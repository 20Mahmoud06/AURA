import 'package:aura/database/models/playlist.dart';

const playlistTypeMusic = 'music';
const playlistTypeVideo = 'video';
const playlistMusicMarker = '__aura_playlist_type_music__';
const playlistVideoMarker = '__aura_playlist_type_video__';

String? playlistMarkerForType(String? type) {
  if (type == playlistTypeMusic) return playlistMusicMarker;
  if (type == playlistTypeVideo) return playlistVideoMarker;
  return null;
}

bool isMusicPlaylist(
  Playlist playlist, {
  Set<String> musicPaths = const {},
  Set<String> videoPaths = const {},
}) {
  if (playlist.isFavorites) return playlist.name == 'Favorites Music';
  if (playlist.coverImagePath == playlistMusicMarker) return true;
  if (playlist.coverImagePath == playlistVideoMarker) return false;

  final hasMusic = playlist.itemPaths.any(musicPaths.contains);
  final hasVideo = playlist.itemPaths.any(videoPaths.contains);
  return hasMusic || !hasVideo;
}

bool isVideoPlaylist(
  Playlist playlist, {
  Set<String> musicPaths = const {},
  Set<String> videoPaths = const {},
}) {
  if (playlist.isFavorites) return playlist.name == 'Favorites Videos';
  if (playlist.coverImagePath == playlistVideoMarker) return true;
  if (playlist.coverImagePath == playlistMusicMarker) return false;

  final hasMusic = playlist.itemPaths.any(musicPaths.contains);
  final hasVideo = playlist.itemPaths.any(videoPaths.contains);
  return hasVideo || !hasMusic;
}
