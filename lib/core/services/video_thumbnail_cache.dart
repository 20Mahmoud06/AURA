import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

/// In-memory cache for gallery video thumbnails (no disk JPEG / Image.file).
class VideoThumbnailCache {
  VideoThumbnailCache._();

  static final VideoThumbnailCache instance = VideoThumbnailCache._();

  static const ThumbnailSize _size = ThumbnailSize(200, 200);
  static const int _maxEntries = 128;

  final LinkedHashMap<String, Uint8List> _cache = LinkedHashMap();

  Future<Uint8List?> get(String? assetId) async {
    if (assetId == null || assetId.isEmpty) return null;

    final cached = _cache.remove(assetId);
    if (cached != null) {
      _cache[assetId] = cached;
      return cached;
    }

    try {
      final entity = await AssetEntity.fromId(assetId);
      if (entity == null) return null;

      final bytes = await entity.thumbnailDataWithSize(_size);
      if (bytes == null || bytes.isEmpty) return null;

      _put(assetId, bytes);
      return bytes;
    } catch (error) {
      debugPrint('VideoThumbnailCache miss for $assetId: $error');
      return null;
    }
  }

  void _put(String key, Uint8List value) {
    while (_cache.length >= _maxEntries) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }

  void clear() => _cache.clear();
}
