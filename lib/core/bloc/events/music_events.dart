part of '../media_bloc.dart';

class PlayMusicEvent extends MediaEvent {
  final MusicItem music;
  PlayMusicEvent(this.music);
}

class ToggleFavoriteMusicEvent extends MediaEvent {
  final MusicItem music;
  ToggleFavoriteMusicEvent(this.music);
}

class RenameMusicEvent extends MediaEvent {
  final MusicItem music;
  final String newName;
  RenameMusicEvent(this.music, this.newName);
}

class DeleteMusicEvent extends MediaEvent {
  final MusicItem music;
  DeleteMusicEvent(this.music);
}

class AddMusicToPlaylistEvent extends MediaEvent {
  final MusicItem music;
  final Playlist playlist;
  AddMusicToPlaylistEvent(this.music, this.playlist);
}

class AddMusicListToPlaylistEvent extends MediaEvent {
  final List<MusicItem> musicItems;
  final Playlist playlist;
  AddMusicListToPlaylistEvent(this.musicItems, this.playlist);
}

class RemoveMusicFromPlaylistEvent extends MediaEvent {
  final MusicItem music;
  final Playlist playlist;
  RemoveMusicFromPlaylistEvent(this.music, this.playlist);
}

class DeleteMusicListEvent extends MediaEvent {
  final List<MusicItem> musicItems;
  DeleteMusicListEvent(this.musicItems);
}
