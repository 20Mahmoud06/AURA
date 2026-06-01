import 'package:isar/isar.dart';

part 'video_item.g.dart';

@collection
class VideoItem {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String path;

  late String title;
  
  String? folderName;

  late int durationMs;

  late int sizeBytes;

  String? thumbnailPath;

  /// Photo Manager asset id — used to load thumbnails without decoding full video files.
  String? assetId;

  DateTime? dateAdded;
  
  bool isFavorite = false;
}
