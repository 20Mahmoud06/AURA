import 'package:isar/isar.dart';

part 'music_item.g.dart';

@collection
class MusicItem {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String path;

  late String title;

  String? artist;

  String? album;

  late int durationMs;

  late int sizeBytes;
  
  String? artworkPath; // Or use audio query id

  int? audioQueryId;

  DateTime? dateAdded;

  bool isFavorite = false;

  DateTime? lastPlayedAt;
}
