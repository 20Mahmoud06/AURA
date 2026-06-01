part of '../media_bloc.dart';

class CreatePlaylistEvent extends MediaEvent {
  final String name;
  final String? mediaType;
  CreatePlaylistEvent(this.name, {this.mediaType});
}

class RenamePlaylistEvent extends MediaEvent {
  final Id playlistId;
  final String name;
  RenamePlaylistEvent(this.playlistId, this.name);
}

class DeletePlaylistEvent extends MediaEvent {
  final Id playlistId;
  DeletePlaylistEvent(this.playlistId);
}
