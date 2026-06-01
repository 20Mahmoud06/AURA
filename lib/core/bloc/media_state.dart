part of 'media_bloc.dart';

class MediaState {
  final bool isLoading;
  final bool isPermissionGranted;
  final bool permissionNeedsSettings;
  final List<MusicItem> musicItems;
  final List<VideoItem> videoItems;
  final List<Playlist> playlists;
  final VideoItem? currentVideo;
  final MusicItem? currentMusic;

  const MediaState({
    this.isLoading = false,
    this.isPermissionGranted = false,
    this.permissionNeedsSettings = false,
    this.musicItems = const [],
    this.videoItems = const [],
    this.playlists = const [],
    this.currentVideo,
    this.currentMusic,
  });

  MediaState copyWith({
    bool? isLoading,
    bool? isPermissionGranted,
    bool? permissionNeedsSettings,
    List<MusicItem>? musicItems,
    List<VideoItem>? videoItems,
    List<Playlist>? playlists,
    VideoItem? currentVideo,
    MusicItem? currentMusic,
  }) {
    return MediaState(
      isLoading: isLoading ?? this.isLoading,
      isPermissionGranted: isPermissionGranted ?? this.isPermissionGranted,
      permissionNeedsSettings:
          permissionNeedsSettings ?? this.permissionNeedsSettings,
      musicItems: musicItems ?? this.musicItems,
      videoItems: videoItems ?? this.videoItems,
      playlists: playlists ?? this.playlists,
      currentVideo: currentVideo ?? this.currentVideo,
      currentMusic: currentMusic ?? this.currentMusic,
    );
  }
}
