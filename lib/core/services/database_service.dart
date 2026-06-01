import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../database/models/video_item.dart';
import '../../database/models/music_item.dart';
import '../../database/models/playlist.dart';

class DatabaseService {
  late final Isar isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [VideoItemSchema, MusicItemSchema, PlaylistSchema],
      directory: dir.path,
    );
  }

  // --- Music ---
  Future<void> saveMusicItems(List<MusicItem> items) async {
    await isar.writeTxn(() async {
      await isar.musicItems.putAll(items);
    });
  }

  Future<void> saveMusicItem(MusicItem item) async {
    await isar.writeTxn(() async {
      await isar.musicItems.put(item);
    });
  }

  Future<List<MusicItem>> getAllMusic() async {
    return await isar.musicItems.where().findAll();
  }

  // --- Videos ---
  Future<void> saveVideoItems(List<VideoItem> items) async {
    await isar.writeTxn(() async {
      await isar.videoItems.putAll(items);
    });
  }

  Future<List<VideoItem>> getAllVideos() async {
    return await isar.videoItems.where().findAll();
  }

  // --- Playlists ---
  Future<List<Playlist>> getAllPlaylists() async {
    return await isar.playlists.where().findAll();
  }

  Future<void> clearAllMusic() async {
    await isar.writeTxn(() async {
      await isar.musicItems.clear();
    });
  }

  Future<void> clearAllVideos() async {
    await isar.writeTxn(() async {
      await isar.videoItems.clear();
    });
  }

  Future<void> savePlaylist(Playlist playlist) async {
    await isar.writeTxn(() async {
      await isar.playlists.put(playlist);
    });
  }

  Future<void> deletePlaylist(Id id) async {
    await isar.writeTxn(() async {
      await isar.playlists.delete(id);
    });
  }
}
