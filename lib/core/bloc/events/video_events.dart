part of '../media_bloc.dart';

class PlayVideoEvent extends MediaEvent {
  final VideoItem video;
  PlayVideoEvent(this.video);
}

class RenameVideoEvent extends MediaEvent {
  final VideoItem video;
  final String newName;
  RenameVideoEvent(this.video, this.newName);
}

class DeleteVideoEvent extends MediaEvent {
  final VideoItem video;
  DeleteVideoEvent(this.video);
}

class AddVideoToPlaylistEvent extends MediaEvent {
  final VideoItem video;
  final Playlist playlist;
  AddVideoToPlaylistEvent(this.video, this.playlist);
}

class AddVideoListToPlaylistEvent extends MediaEvent {
  final List<VideoItem> videoItems;
  final Playlist playlist;
  AddVideoListToPlaylistEvent(this.videoItems, this.playlist);
}

class RemoveVideoFromPlaylistEvent extends MediaEvent {
  final VideoItem video;
  final Playlist playlist;
  RemoveVideoFromPlaylistEvent(this.video, this.playlist);
}

class ToggleFavoriteVideoEvent extends MediaEvent {
  final VideoItem video;
  ToggleFavoriteVideoEvent(this.video);
}

class DeleteVideoListEvent extends MediaEvent {
  final List<VideoItem> videoItems;
  DeleteVideoListEvent(this.videoItems);
}
