import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../database/models/music_item.dart';
import '../../database/models/video_item.dart';

/// Result of a media permission request.
class MediaPermissionResult {
  const MediaPermissionResult({
    required this.granted,
    this.shouldOpenSettings = false,
  });

  final bool granted;
  final bool shouldOpenSettings;
}

class MediaScannerService {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  static const PermissionRequestOption _videoPermissionOption =
      PermissionRequestOption(
    androidPermission: AndroidPermission(
      type: RequestType.video,
      mediaLocation: false,
    ),
  );

  static const _videoExtensions = <String>{
    '.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv',
    '.3gp', '.webm', '.m4v', '.mpg', '.mpeg', '.ts',
    '.vob', '.ogv', '.divx',
  };

  Future<bool> hasMediaPermissions() async {
    if (Platform.isAndroid) {
      final audioOk = await _audioQuery.permissionsStatus();
      final videoState = await PhotoManager.getPermissionState(
        requestOption: _videoPermissionOption,
      );
      if (videoState.hasAccess) {
        return audioOk;
      }
      // On older Android (API < 33), storage permission is sufficient
      final storageGranted = await Permission.storage.status.isGranted;
      return audioOk && storageGranted;
    }
    if (Platform.isIOS) {
      final state = await PhotoManager.getPermissionState(
        requestOption: _videoPermissionOption,
      );
      return state.hasAccess;
    }
    return true;
  }

  Future<MediaPermissionResult> requestPermissions() async {
    if (Platform.isAndroid) {
      return _requestAndroidPermissions();
    }
    if (Platform.isIOS) {
      return _requestIosPermissions();
    }
    return const MediaPermissionResult(granted: true);
  }

  Future<MediaPermissionResult> _requestAndroidPermissions() async {
    var audioOk = await _audioQuery.permissionsStatus();
    if (!audioOk) {
      audioOk = await _audioQuery.permissionsRequest(retryRequest: true);
    }

    var videoState = await PhotoManager.getPermissionState(
      requestOption: _videoPermissionOption,
    );
    if (!videoState.hasAccess) {
      videoState = await PhotoManager.requestPermissionExtend(
        requestOption: _videoPermissionOption,
      );
    }

    await <Permission>[
      Permission.audio,
      Permission.videos,
      Permission.storage,
    ].request();

    // On older Android (API < 33), storage permission is sufficient
    // for video access via file system fallback
    final storageGranted = await Permission.storage.status.isGranted;
    final videoOk = videoState.hasAccess || storageGranted;
    final granted = audioOk && videoOk;

    if (granted) {
      return const MediaPermissionResult(granted: true);
    }

    final shouldOpenSettings = await _shouldOpenAppSettings(
      audioGranted: audioOk,
      videoHasAccess: videoOk,
    );
    return MediaPermissionResult(
      granted: false,
      shouldOpenSettings: shouldOpenSettings,
    );
  }

  Future<MediaPermissionResult> _requestIosPermissions() async {
    var state = await PhotoManager.requestPermissionExtend(
      requestOption: _videoPermissionOption,
    );
    if (state.hasAccess) {
      return const MediaPermissionResult(granted: true);
    }

    final current = await PhotoManager.getPermissionState(
      requestOption: _videoPermissionOption,
    );
    return MediaPermissionResult(
      granted: false,
      shouldOpenSettings: current == PermissionState.denied,
    );
  }

  Future<bool> _shouldOpenAppSettings({
    required bool audioGranted,
    required bool videoHasAccess,
  }) async {
    if (audioGranted && videoHasAccess) return false;

    final audioStatus = await Permission.audio.status;
    final videoStatus = await Permission.videos.status;
    final storageStatus = await Permission.storage.status;

    return audioStatus.isPermanentlyDenied ||
        videoStatus.isPermanentlyDenied ||
        storageStatus.isPermanentlyDenied ||
        (!audioGranted && !await Permission.audio.isGranted) ||
        (!videoHasAccess &&
            (videoStatus.isDenied || storageStatus.isDenied));
  }

  Future<List<MusicItem>> scanMusic() async {
    if (!await hasMediaPermissions()) return [];

    try {
      final songs = await _audioQuery.querySongs(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      return songs
          .where(_isMusicFile)
          .map((song) {
        return MusicItem()
          ..path = song.data
          ..title = song.title
          ..artist = song.artist
          ..album = song.album
          ..durationMs = song.duration ?? 0
          ..sizeBytes = song.size
          ..audioQueryId = song.id
          ..dateAdded = DateTime.now();
      }).toList();
    } catch (error, stackTrace) {
      debugPrint('scanMusic failed: $error\n$stackTrace');
      return [];
    }
  }

  bool _isMusicFile(SongModel song) {
    final duration = song.duration ?? 0;
    if (duration > 0 && duration < 20000) return false;
    final path = song.data.toLowerCase();
    if (path.contains('whatsapp') && path.contains('voice')) return false;
    if (path.contains('/ringtone') || path.contains('/notifications') || path.contains('/alarm')) return false;
    return true;
  }

  /// Indexes videos only (metadata). Thumbnails load lazily in the UI.
  Future<List<VideoItem>> scanVideos() async {
    if (!await hasMediaPermissions()) return [];

    // First try: photo_manager (works on modern Android + most devices)
    final photoManagerResult = await _scanVideosWithPhotoManager();
    if (photoManagerResult.isNotEmpty) {
      debugPrint(
        'scanVideos: photo_manager found ${photoManagerResult.length} videos',
      );
      return photoManagerResult;
    }

    debugPrint(
      'scanVideos: photo_manager returned empty, trying file system fallback',
    );

    // Fallback: file system scan for older Android or when photo_manager fails
    if (Platform.isAndroid) {
      final fileSystemResult = await _scanVideosWithFileSystem();
      debugPrint(
        'scanVideos: file system fallback found ${fileSystemResult.length} videos',
      );
      return fileSystemResult;
    }

    return [];
  }

  Future<List<VideoItem>> _scanVideosWithPhotoManager() async {
    try {
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.video,
      );

      if (albums.isEmpty) return [];

      final seenPaths = <String>{};
      final videoItems = <VideoItem>[];

      for (final album in albums) {
        final count = await album.assetCountAsync;
        if (count == 0) continue;

        const pageSize = 200;
        for (var page = 0; page * pageSize < count; page++) {
          final entities = await album.getAssetListPaged(
            page: page,
            size: pageSize,
          );

          for (final entity in entities) {
            try {
              final file = await entity.file;
              if (file == null) continue;

              final path = file.path;
              if (!seenPaths.add(path)) continue;

              videoItems.add(
                VideoItem()
                  ..path = path
                  ..title = entity.title ?? p.basename(path)
                  ..assetId = entity.id
                  ..durationMs = entity.duration * 1000
                  ..sizeBytes = await file.length()
                  ..dateAdded = entity.createDateTime,
              );
            } catch (error) {
              debugPrint('Skipped video asset ${entity.id}: $error');
            }
          }
        }
      }

      return videoItems;
    } catch (error, stackTrace) {
      debugPrint('_scanVideosWithPhotoManager failed: $error\n$stackTrace');
      return [];
    }
  }

  /// Fallback video scanner that walks known storage directories for video files.
  /// Used on older Android devices where photo_manager fails to return results.
  Future<List<VideoItem>> _scanVideosWithFileSystem() async {
    final seenPaths = <String>{};
    final items = <VideoItem>[];

    final candidates = <String>[
      '/storage/emulated/0/DCIM',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Movies',
      '/storage/emulated/0/Movie',
      '/storage/emulated/0/Videos',
      '/storage/emulated/0/Video',
      '/storage/emulated/0/WhatsApp/Media/WhatsApp Video',
      '/storage/emulated/0/Telegram/Telegram Video',
    ];

    for (final dirPath in candidates) {
      try {
        final dir = Directory(dirPath);
        if (!await dir.exists()) continue;
        await _walkForVideoFiles(dir, seenPaths, items);
      } catch (_) {}
    }

    return items;
  }

  Future<void> _walkForVideoFiles(
    Directory dir,
    Set<String> seenPaths,
    List<VideoItem> items,
  ) async {
    try {
      final entities = dir.list(recursive: true, followLinks: false);
      await for (final entity in entities) {
        if (entity is! File) continue;

        final path = entity.path;
        if (!_videoExtensions.any(path.toLowerCase().endsWith)) continue;
        if (!seenPaths.add(path)) continue;

        try {
          final stat = await entity.stat();
          items.add(
            VideoItem()
              ..path = path
              ..title = p.basenameWithoutExtension(path)
              ..durationMs = 0
              ..sizeBytes = stat.size
              ..dateAdded = stat.modified,
          );
        } catch (_) {}
      }
    } catch (_) {}
  }
}
