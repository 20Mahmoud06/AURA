import 'package:isar/isar.dart';

part 'playlist.g.dart';

@collection
class Playlist {
  Id id = Isar.autoIncrement;

  late String name;

  String? coverImagePath;

  DateTime? createdAt;

  List<String> itemPaths = [];

  bool isFavorites = false;

  List<String> get paths => List.unmodifiable(itemPaths);

  void addPath(String path) {
    itemPaths = [...itemPaths, path];
  }
}