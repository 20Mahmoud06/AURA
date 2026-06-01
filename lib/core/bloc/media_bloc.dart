import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:isar/isar.dart';
import '../../database/models/music_item.dart';
import '../../database/models/video_item.dart';
import '../../database/models/playlist.dart';
import '../services/database_service.dart';
import '../services/file_operation_service.dart';
import '../services/media_scanner_service.dart';
import '../services/video_thumbnail_cache.dart';
import '../config/app_config.dart';
import '../utils/playlist_media_type.dart';

part 'media_state.dart';
part 'events/media_event.dart';
part 'events/music_events.dart';
part 'events/video_events.dart';
part 'events/playlist_events.dart';

class MediaBloc extends Bloc<MediaEvent, MediaState> {
  MediaBloc() : super(const MediaState()) {
    on<LoadMediaEvent>(_onLoadMedia);
    on<RequestPermissionsEvent>(_onRequestPermissions);
    on<PlayVideoEvent>(_onPlayVideo);
    on<RenameVideoEvent>(_onRenameVideo);
    on<DeleteVideoEvent>(_onDeleteVideo);
    on<DeleteVideoListEvent>(_onDeleteVideoList);
    on<AddVideoToPlaylistEvent>(_onAddVideoToPlaylist);
    on<AddVideoListToPlaylistEvent>(_onAddVideoListToPlaylist);
    on<RemoveVideoFromPlaylistEvent>(_onRemoveVideoFromPlaylist);
    on<CreatePlaylistEvent>(_onCreatePlaylist);
    on<ToggleFavoriteVideoEvent>(_onToggleFavoriteVideo);
    on<RefreshVideosEvent>(_onRefreshVideos);
    on<ScanDeviceEvent>(_onScanDevice);
    on<PlayMusicEvent>(_onPlayMusic);
    on<ToggleFavoriteMusicEvent>(_onToggleFavoriteMusic);
    on<RenameMusicEvent>(_onRenameMusic);
    on<DeleteMusicEvent>(_onDeleteMusic);
    on<DeleteMusicListEvent>(_onDeleteMusicList);
    on<AddMusicToPlaylistEvent>(_onAddMusicToPlaylist);
    on<AddMusicListToPlaylistEvent>(_onAddMusicListToPlaylist);
    on<RemoveMusicFromPlaylistEvent>(_onRemoveMusicFromPlaylist);
    on<RenamePlaylistEvent>(_onRenamePlaylist);
    on<DeletePlaylistEvent>(_onDeletePlaylist);
  }

  final DatabaseService _db = AppConfig.databaseService;
  final MediaScannerService _scanner = AppConfig.mediaScannerService;

  Future<void> _onLoadMedia(LoadMediaEvent event, Emitter<MediaState> emit) async {
    await _loadMedia(emit, requestIfNeeded: true);
  }

  Future<void> _onRequestPermissions(
    RequestPermissionsEvent event,
    Emitter<MediaState> emit,
  ) async {
    await _loadMedia(emit, requestIfNeeded: true, openSettingsOnDenial: true);
  }

  Future<void> _loadMedia(
    Emitter<MediaState> emit, {
    required bool requestIfNeeded,
    bool openSettingsOnDenial = false,
  }) async {
    emit(state.copyWith(isLoading: true, permissionNeedsSettings: false));

    try {
      final MediaPermissionResult permissionResult;
      if (requestIfNeeded) {
        permissionResult = await _scanner.requestPermissions();
      } else {
        final granted = await _scanner.hasMediaPermissions();
        permissionResult = MediaPermissionResult(granted: granted);
      }

      if (!permissionResult.granted) {
        if (openSettingsOnDenial && permissionResult.shouldOpenSettings) {
          await openAppSettings();
        }
        emit(
          state.copyWith(
            isLoading: false,
            isPermissionGranted: false,
            permissionNeedsSettings: permissionResult.shouldOpenSettings,
          ),
        );
        return;
      }

      emit(state.copyWith(isPermissionGranted: true));

      var dbMusic = await _db.getAllMusic();
      var dbVideos = await _db.getAllVideos();
      var dbPlaylists = await _db.getAllPlaylists();

      dbVideos.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );

      if (dbVideos.isNotEmpty && dbVideos.any((v) => v.assetId == null)) {
        final rescanned = await _scanner.scanVideos();
        if (rescanned.isNotEmpty) {
          await _db.saveVideoItems(rescanned);
          dbVideos = await _db.getAllVideos();
          dbVideos.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
          );
        }
      }

      if (dbMusic.isEmpty || dbVideos.isEmpty) {
        final scannedMusic = await _scanner.scanMusic();
        final scannedVideos = await _scanner.scanVideos();

        if (scannedVideos.isNotEmpty) {
          scannedVideos.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
          );
        }

        await _db.clearAllMusic();
        await _db.clearAllVideos();
        await _db.saveMusicItems(scannedMusic);
        await _db.saveVideoItems(scannedVideos);

        dbMusic = await _db.getAllMusic();
        dbVideos = await _db.getAllVideos();
        dbVideos.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        dbPlaylists = await _db.getAllPlaylists();
      }

      await _migrateOldFavorites(dbPlaylists, dbMusic, dbVideos);
      dbPlaylists = await _db.getAllPlaylists();

      emit(
        state.copyWith(
          isLoading: false,
          musicItems: dbMusic,
          videoItems: dbVideos,
          playlists: dbPlaylists,
        ),
      );

    } catch (error, stackTrace) {
      debugPrint('MediaBloc._loadMedia failed: $error\n$stackTrace');
      emit(
        state.copyWith(
          isLoading: false,
          isPermissionGranted: false,
        ),
      );
    }
  }

  Future<void> _migrateOldFavorites(
    List<Playlist> playlists,
    List<MusicItem> musicItems,
    List<VideoItem> videoItems,
  ) async {
    final oldFav = playlists.where(
      (p) => p.isFavorites && p.name == 'Favorites',
    ).firstOrNull;
    if (oldFav == null) return;

    final favVideos = playlists.where(
          (p) => p.isFavorites && p.name == 'Favorites Videos',
        ).firstOrNull ??
        Playlist()
          ..name = 'Favorites Videos'
          ..isFavorites = true
          ..createdAt = DateTime.now();

    final favMusic = playlists.where(
          (p) => p.isFavorites && p.name == 'Favorites Music',
        ).firstOrNull ??
        Playlist()
          ..name = 'Favorites Music'
          ..isFavorites = true
          ..createdAt = DateTime.now();

    final videoPathSet = videoItems.map((v) => v.path).toSet();
    final musicPathSet = musicItems.map((m) => m.path).toSet();

    for (final path in oldFav.itemPaths) {
      if (videoPathSet.contains(path)) {
        if (!favVideos.itemPaths.contains(path)) {
          favVideos.itemPaths = [...favVideos.itemPaths, path];
        }
      } else if (musicPathSet.contains(path)) {
        if (!favMusic.itemPaths.contains(path)) {
          favMusic.itemPaths = [...favMusic.itemPaths, path];
        }
      }
    }

    await _db.isar.writeTxn(() async {
      await _db.isar.playlists.put(favVideos);
      await _db.isar.playlists.put(favMusic);
      await _db.isar.playlists.delete(oldFav.id);
    });
  }

  void _onPlayVideo(PlayVideoEvent event, Emitter<MediaState> emit) {
    emit(state.copyWith(currentVideo: event.video));
  }

  Future<void> _onPlayMusic(PlayMusicEvent event, Emitter<MediaState> emit) async {
    event.music.lastPlayedAt = DateTime.now();
    await _db.isar.writeTxn(() async {
      await _db.isar.musicItems.put(event.music);
    });
    emit(state.copyWith(currentMusic: event.music));
  }

  Future<void> _onRenameVideo(RenameVideoEvent event, Emitter<MediaState> emit) async {
    final oldPath = event.video.path;
    final dir = File(oldPath).parent.path;
    final ext = oldPath.split('.').last;
    var sanitizedName = event.newName.trim();
    sanitizedName = sanitizedName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    if (sanitizedName.isEmpty) {
      debugPrint('Rename error: empty name');
      return;
    }
    final hasExtension = sanitizedName.toLowerCase().endsWith('.${ext.toLowerCase()}');
    final fileName = hasExtension ? sanitizedName : '$sanitizedName.$ext';
    final newPath = '$dir${Platform.pathSeparator}$fileName';

    final renamed = await FileOperationService.renameMediaFile(
      oldPath: oldPath,
      newPath: newPath,
      mediaType: 'video',
    );

    if (renamed) {
      await _db.isar.writeTxn(() async {
        event.video.path = newPath;
        event.video.title = fileName.replaceAll('.$ext', '');
        await _db.isar.videoItems.put(event.video);
      });
    } else {
      debugPrint('Rename failed: could not rename file on device');
      await _db.isar.writeTxn(() async {
        event.video.title = fileName.replaceAll('.$ext', '');
        await _db.isar.videoItems.put(event.video);
      });
    }

    final videos = await _db.getAllVideos();
    videos.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    emit(state.copyWith(videoItems: videos));
  }

  Future<void> _onDeleteVideo(DeleteVideoEvent event, Emitter<MediaState> emit) async {
    try {
      await FileOperationService.deleteMediaFile(
        path: event.video.path,
        mediaType: 'video',
      );

      List<Playlist> updatedPlaylists = [];
      await _db.isar.writeTxn(() async {
        await _db.isar.videoItems.delete(event.video.id);

        final allPlaylists = await _db.isar.playlists.where().findAll();
        for (final playlist in allPlaylists) {
          if (playlist.itemPaths.contains(event.video.path)) {
            playlist.itemPaths =
                playlist.itemPaths.where((p) => p != event.video.path).toList();
            await _db.isar.playlists.put(playlist);
          }
        }
      });

      updatedPlaylists = await _db.getAllPlaylists();
      final videos = await _db.getAllVideos();
      videos.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      emit(state.copyWith(videoItems: videos, playlists: updatedPlaylists));
    } catch (e) {
      debugPrint('Delete video error: $e');
    }
  }

  Future<void> _onDeleteVideoList(DeleteVideoListEvent event, Emitter<MediaState> emit) async {
    try {
      for (final video in event.videoItems) {
        await FileOperationService.deleteMediaFile(
          path: video.path,
          mediaType: 'video',
        );
      }

      final pathsToDelete = event.videoItems.map((v) => v.path).toSet();
      List<Playlist> updatedPlaylists = [];
      await _db.isar.writeTxn(() async {
        for (final video in event.videoItems) {
          await _db.isar.videoItems.delete(video.id);
        }

        final allPlaylists = await _db.isar.playlists.where().findAll();
        for (final playlist in allPlaylists) {
          final oldCount = playlist.itemPaths.length;
          playlist.itemPaths =
              playlist.itemPaths.where((p) => !pathsToDelete.contains(p)).toList();
          if (playlist.itemPaths.length != oldCount) {
            await _db.isar.playlists.put(playlist);
          }
        }
      });

      updatedPlaylists = await _db.getAllPlaylists();
      final videos = await _db.getAllVideos();
      videos.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      emit(state.copyWith(videoItems: videos, playlists: updatedPlaylists));
    } catch (e) {
      debugPrint('Delete video list error: $e');
    }
  }

  Future<void> _onAddVideoToPlaylist(AddVideoToPlaylistEvent event, Emitter<MediaState> emit) async {
    await _db.isar.writeTxn(() async {
      event.playlist.coverImagePath ??= playlistVideoMarker;
      if (!event.playlist.itemPaths.contains(event.video.path)) {
        final updated = [...event.playlist.itemPaths, event.video.path];
        event.playlist.itemPaths = updated;
        await _db.isar.playlists.put(event.playlist);
      }
    });
    final playlists = await _db.getAllPlaylists();
    emit(state.copyWith(playlists: playlists));
  }

  Future<void> _onAddVideoListToPlaylist(AddVideoListToPlaylistEvent event, Emitter<MediaState> emit) async {
    if (event.videoItems.isEmpty) return;

    await _db.isar.writeTxn(() async {
      event.playlist.coverImagePath ??= playlistVideoMarker;
      final paths = event.playlist.itemPaths.toSet();
      for (final video in event.videoItems) {
        paths.add(video.path);
      }
      event.playlist.itemPaths = paths.toList();
      await _db.isar.playlists.put(event.playlist);
    });

    final playlists = await _db.getAllPlaylists();
    emit(state.copyWith(playlists: playlists));
  }

  Future<void> _onRemoveVideoFromPlaylist(RemoveVideoFromPlaylistEvent event, Emitter<MediaState> emit) async {
    await _db.isar.writeTxn(() async {
      event.playlist.itemPaths = event.playlist.itemPaths
          .where((path) => path != event.video.path)
          .toList();
      await _db.isar.playlists.put(event.playlist);
    });

    final playlists = await _db.getAllPlaylists();
    emit(state.copyWith(playlists: playlists));
  }

  Future<void> _onCreatePlaylist(CreatePlaylistEvent event, Emitter<MediaState> emit) async {
    final name = event.name.trim();
    if (name.isEmpty) return;
    final playlist = Playlist()
      ..name = name
      ..createdAt = DateTime.now()
      ..coverImagePath = playlistMarkerForType(event.mediaType);
    await _db.savePlaylist(playlist);
    final playlists = await _db.getAllPlaylists();
    emit(state.copyWith(playlists: playlists));
  }

  Future<void> _onRenamePlaylist(RenamePlaylistEvent event, Emitter<MediaState> emit) async {
    final name = event.name.trim();
    if (name.isEmpty) return;
    final playlist = await _db.isar.playlists.get(event.playlistId);
    if (playlist == null) return;
    await _db.isar.writeTxn(() async {
      playlist.name = name;
      await _db.isar.playlists.put(playlist);
    });
    final playlists = await _db.getAllPlaylists();
    emit(state.copyWith(playlists: playlists));
  }

  Future<void> _onDeletePlaylist(DeletePlaylistEvent event, Emitter<MediaState> emit) async {
    await _db.deletePlaylist(event.playlistId);
    final playlists = await _db.getAllPlaylists();
    emit(state.copyWith(playlists: playlists));
  }

  Future<void> _onRefreshVideos(RefreshVideosEvent event, Emitter<MediaState> emit) async {
    final videos = await _db.getAllVideos();
    videos.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    emit(state.copyWith(videoItems: videos));
  }

  Future<void> _onToggleFavoriteVideo(ToggleFavoriteVideoEvent event, Emitter<MediaState> emit) async {
    var fav = await _db.isar.playlists
        .filter()
        .isFavoritesEqualTo(true)
        .nameEqualTo('Favorites Videos')
        .findFirst();
    if (fav == null) {
      final newFav = Playlist()
        ..name = 'Favorites Videos'
        ..isFavorites = true
        ..createdAt = DateTime.now();
      await _db.isar.writeTxn(() async {
        await _db.isar.playlists.put(newFav);
      });
      fav = newFav;
    }
    final favorites = fav;

    await _db.isar.writeTxn(() async {
      event.video.isFavorite = !event.video.isFavorite;
      await _db.isar.videoItems.put(event.video);

      final contains = favorites.itemPaths.contains(event.video.path);
      if (event.video.isFavorite && !contains) {
        favorites.itemPaths = [...favorites.itemPaths, event.video.path];
      } else if (!event.video.isFavorite && contains) {
        favorites.itemPaths = favorites.itemPaths.where((p) => p != event.video.path).toList();
      }
      await _db.isar.playlists.put(favorites);
    });

    final videos = await _db.getAllVideos();
    videos.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    final playlists = await _db.getAllPlaylists();
    emit(state.copyWith(videoItems: videos, playlists: playlists));
  }

  Future<void> _onToggleFavoriteMusic(ToggleFavoriteMusicEvent event, Emitter<MediaState> emit) async {
    var fav = await _db.isar.playlists
        .filter()
        .isFavoritesEqualTo(true)
        .nameEqualTo('Favorites Music')
        .findFirst();
    if (fav == null) {
      final newFav = Playlist()
        ..name = 'Favorites Music'
        ..isFavorites = true
        ..createdAt = DateTime.now();
      await _db.isar.writeTxn(() async {
        await _db.isar.playlists.put(newFav);
      });
      fav = newFav;
    }
    final favorites = fav;

    await _db.isar.writeTxn(() async {
      event.music.isFavorite = !event.music.isFavorite;
      await _db.isar.musicItems.put(event.music);

      final contains = favorites.itemPaths.contains(event.music.path);
      if (event.music.isFavorite && !contains) {
        favorites.itemPaths = [...favorites.itemPaths, event.music.path];
      } else if (!event.music.isFavorite && contains) {
        favorites.itemPaths = favorites.itemPaths.where((p) => p != event.music.path).toList();
      }
      await _db.isar.playlists.put(favorites);
    });

    final music = await _db.getAllMusic();
    final playlists = await _db.getAllPlaylists();
    emit(state.copyWith(musicItems: music, playlists: playlists));
  }

  Future<void> _onRenameMusic(RenameMusicEvent event, Emitter<MediaState> emit) async {
    final oldPath = event.music.path;
    final dir = File(oldPath).parent.path;
    final ext = oldPath.split('.').last;
    var sanitizedName = event.newName.trim();
    sanitizedName = sanitizedName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    if (sanitizedName.isEmpty) return;
    final hasExtension = sanitizedName.toLowerCase().endsWith('.${ext.toLowerCase()}');
    final fileName = hasExtension ? sanitizedName : '$sanitizedName.$ext';
    final newPath = '$dir${Platform.pathSeparator}$fileName';

    final renamed = await FileOperationService.renameMediaFile(
      oldPath: oldPath,
      newPath: newPath,
      mediaType: 'audio',
      id: event.music.audioQueryId,
    );

    if (renamed) {
      await _db.isar.writeTxn(() async {
        event.music.path = newPath;
        event.music.title = fileName.replaceAll('.$ext', '');
        await _db.isar.musicItems.put(event.music);
      });
    } else {
      debugPrint('Rename failed: could not rename file on device');
      await _db.isar.writeTxn(() async {
        event.music.title = fileName.replaceAll('.$ext', '');
        await _db.isar.musicItems.put(event.music);
      });
    }

    final music = await _db.getAllMusic();
    emit(state.copyWith(musicItems: music));
  }

  Future<void> _onDeleteMusic(DeleteMusicEvent event, Emitter<MediaState> emit) async {
    try {
      await FileOperationService.deleteMediaFile(
        path: event.music.path,
        mediaType: 'audio',
        id: event.music.audioQueryId,
      );

      List<Playlist> updatedPlaylists = [];
      await _db.isar.writeTxn(() async {
        await _db.isar.musicItems.delete(event.music.id);

        final allPlaylists = await _db.isar.playlists.where().findAll();
        for (final playlist in allPlaylists) {
          if (playlist.itemPaths.contains(event.music.path)) {
            playlist.itemPaths =
                playlist.itemPaths.where((p) => p != event.music.path).toList();
            await _db.isar.playlists.put(playlist);
          }
        }
      });

      updatedPlaylists = await _db.getAllPlaylists();
      final music = await _db.getAllMusic();
      emit(state.copyWith(musicItems: music, playlists: updatedPlaylists));
    } catch (e) {
      debugPrint('Delete music error: $e');
    }
  }

  Future<void> _onDeleteMusicList(DeleteMusicListEvent event, Emitter<MediaState> emit) async {
    try {
      for (final music in event.musicItems) {
        await FileOperationService.deleteMediaFile(
          path: music.path,
          mediaType: 'audio',
          id: music.audioQueryId,
        );
      }

      final pathsToDelete = event.musicItems.map((m) => m.path).toSet();
      List<Playlist> updatedPlaylists = [];
      await _db.isar.writeTxn(() async {
        for (final music in event.musicItems) {
          await _db.isar.musicItems.delete(music.id);
        }

        final allPlaylists = await _db.isar.playlists.where().findAll();
        for (final playlist in allPlaylists) {
          final oldCount = playlist.itemPaths.length;
          playlist.itemPaths =
              playlist.itemPaths.where((p) => !pathsToDelete.contains(p)).toList();
          if (playlist.itemPaths.length != oldCount) {
            await _db.isar.playlists.put(playlist);
          }
        }
      });

      updatedPlaylists = await _db.getAllPlaylists();
      final music = await _db.getAllMusic();
      emit(state.copyWith(musicItems: music, playlists: updatedPlaylists));
    } catch (e) {
      debugPrint('Delete music list error: $e');
    }
  }

  Future<void> _onAddMusicToPlaylist(AddMusicToPlaylistEvent event, Emitter<MediaState> emit) async {
    await _db.isar.writeTxn(() async {
      event.playlist.coverImagePath ??= playlistMusicMarker;
      if (!event.playlist.itemPaths.contains(event.music.path)) {
        final updated = [...event.playlist.itemPaths, event.music.path];
        event.playlist.itemPaths = updated;
        await _db.isar.playlists.put(event.playlist);
      }
    });
    final playlists = await _db.getAllPlaylists();
    emit(state.copyWith(playlists: playlists));
  }

  Future<void> _onAddMusicListToPlaylist(AddMusicListToPlaylistEvent event, Emitter<MediaState> emit) async {
    if (event.musicItems.isEmpty) return;

    await _db.isar.writeTxn(() async {
      event.playlist.coverImagePath ??= playlistMusicMarker;
      final paths = event.playlist.itemPaths.toSet();
      for (final music in event.musicItems) {
        paths.add(music.path);
      }
      event.playlist.itemPaths = paths.toList();
      await _db.isar.playlists.put(event.playlist);
    });

    final playlists = await _db.getAllPlaylists();
    emit(state.copyWith(playlists: playlists));
  }

  Future<void> _onRemoveMusicFromPlaylist(RemoveMusicFromPlaylistEvent event, Emitter<MediaState> emit) async {
    await _db.isar.writeTxn(() async {
      event.playlist.itemPaths = event.playlist.itemPaths
          .where((path) => path != event.music.path)
          .toList();
      await _db.isar.playlists.put(event.playlist);
    });

    final playlists = await _db.getAllPlaylists();
    emit(state.copyWith(playlists: playlists));
  }

  Future<void> _onScanDevice(ScanDeviceEvent event, Emitter<MediaState> emit) async {
    emit(state.copyWith(isLoading: true, permissionNeedsSettings: false));
    VideoThumbnailCache.instance.clear();

    try {
      final permissionResult = await _scanner.requestPermissions();
      if (!permissionResult.granted) {
        emit(
          state.copyWith(
            isLoading: false,
            isPermissionGranted: false,
            permissionNeedsSettings: permissionResult.shouldOpenSettings,
          ),
        );
        return;
      }

      emit(state.copyWith(isPermissionGranted: true));

      final scannedMusic = await _scanner.scanMusic();
      final scannedVideos = await _scanner.scanVideos();

      scannedVideos.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );

      await _db.clearAllMusic();
      await _db.clearAllVideos();
      await _db.saveMusicItems(scannedMusic);
      await _db.saveVideoItems(scannedVideos);

      final dbMusic = await _db.getAllMusic();
      final dbVideos = await _db.getAllVideos();
      dbVideos.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
      var dbPlaylists = await _db.getAllPlaylists();

      await _migrateOldFavorites(dbPlaylists, dbMusic, dbVideos);
      dbPlaylists = await _db.getAllPlaylists();

      emit(
        state.copyWith(
          isLoading: false,
          musicItems: dbMusic,
          videoItems: dbVideos,
          playlists: dbPlaylists,
        ),
      );

    } catch (error, stackTrace) {
      debugPrint('MediaBloc._onScanDevice failed: $error\n$stackTrace');
      emit(state.copyWith(isLoading: false));
    }
  }

}
