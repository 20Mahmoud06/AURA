import 'dart:async';
import 'package:flutter/services.dart';

class PictureInPictureService {
  PictureInPictureService._();
  static final PictureInPictureService instance = PictureInPictureService._();

  static const _channel = MethodChannel('com.aura.media.player/pip');

  bool _isInitialized = false;
  void Function(bool isActive)? onPipModeChanged;

  void init() {
    if (_isInitialized) return;
    _isInitialized = true;
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onPipModeChanged':
        final isActive = call.arguments as bool? ?? false;
        onPipModeChanged?.call(isActive);
        return null;
      default:
        throw MissingPluginException();
    }
  }

  Future<bool> get isSupported async {
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> enterPictureInPicture() async {
    try {
      final result = await _channel.invokeMethod<bool>('enter');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setAspectRatio(double width, double height) async {
    try {
      await _channel.invokeMethod('setAspectRatio', {
        'width': width,
        'height': height,
      });
    } catch (_) {}
  }

  Future<bool> get isPipActive async {
    try {
      final result = await _channel.invokeMethod<bool>('isActive');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
