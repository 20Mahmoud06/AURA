import 'package:flutter/services.dart';

class FileOperationService {
  static const _channel = MethodChannel('com.aura.media.player/file');

  static Future<bool> deleteMediaFile({
    required String path,
    required String mediaType,
    int? id,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('deleteMediaFile', {
        'path': path,
        'mediaType': mediaType,
        'id': id,
      });
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> renameMediaFile({
    required String oldPath,
    required String newPath,
    required String mediaType,
    int? id,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('renameMediaFile', {
        'oldPath': oldPath,
        'newPath': newPath,
        'mediaType': mediaType,
        'id': id,
      });
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}
