import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  SettingsService._();
  static SettingsService? _instance;
  static SettingsService get instance => _instance ??= SettingsService._();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Video Playback ──

  bool get pictureInPicture => _prefs.getBool('pictureInPicture') ?? true;
  void setPictureInPicture(bool v) => unawaited(_prefs.setBool('pictureInPicture', v));

  bool get subtitlesByDefault => _prefs.getBool('subtitlesByDefault') ?? false;
  void setSubtitlesByDefault(bool v) => unawaited(_prefs.setBool('subtitlesByDefault', v));

  bool get rememberPlaybackSpeed => _prefs.getBool('rememberPlaybackSpeed') ?? false;
  void setRememberPlaybackSpeed(bool v) => unawaited(_prefs.setBool('rememberPlaybackSpeed', v));

  // ── Video Gestures ──

  bool get gestureControls => _prefs.getBool('gestureControls') ?? true;
  void setGestureControls(bool v) => unawaited(_prefs.setBool('gestureControls', v));

  bool get doubleTapSeek => _prefs.getBool('doubleTapSeek') ?? true;
  void setDoubleTapSeek(bool v) => unawaited(_prefs.setBool('doubleTapSeek', v));

  int get doubleTapSeconds => _prefs.getInt('doubleTapSeconds') ?? 10;
  void setDoubleTapSeconds(int v) => unawaited(_prefs.setInt('doubleTapSeconds', v));

  bool get longPressSpeed => _prefs.getBool('longPressSpeed') ?? true;
  void setLongPressSpeed(bool v) => unawaited(_prefs.setBool('longPressSpeed', v));

  // ── Music Library ──

  bool get autoScanMusic => _prefs.getBool('autoScanMusic') ?? true;
  void setAutoScanMusic(bool v) => unawaited(_prefs.setBool('autoScanMusic', v));

  bool get scanOnLaunch => _prefs.getBool('scanOnLaunch') ?? false;
  void setScanOnLaunch(bool v) => unawaited(_prefs.setBool('scanOnLaunch', v));

  bool get normalizeVolume => _prefs.getBool('normalizeVolume') ?? true;
  void setNormalizeVolume(bool v) => unawaited(_prefs.setBool('normalizeVolume', v));

  // ── Remembered Playback Speed ──

  double get savedPlaybackSpeed => _prefs.getDouble('savedPlaybackSpeed') ?? 1.0;
  void setSavedPlaybackSpeed(double v) => unawaited(_prefs.setDouble('savedPlaybackSpeed', v));

  // ── Music Playback ──

  bool get gaplessPlayback => _prefs.getBool('gaplessPlayback') ?? true;
  void setGaplessPlayback(bool v) => unawaited(_prefs.setBool('gaplessPlayback', v));

  bool get rememberPlaybackPosition => _prefs.getBool('rememberPlaybackPosition') ?? false;
  void setRememberPlaybackPosition(bool v) => unawaited(_prefs.setBool('rememberPlaybackPosition', v));

  bool get lockScreenControls => _prefs.getBool('lockScreenControls') ?? true;
  void setLockScreenControls(bool v) => unawaited(_prefs.setBool('lockScreenControls', v));

  // ── Remembered Playback Positions (track path → ms) ──

  Map<String, int> getSavedPositions() {
    final raw = _prefs.getString('savedPositions');
    if (raw == null) return {};
    try {
      final entries = raw.split(',');
      final map = <String, int>{};
      for (final entry in entries) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          map[parts[0]] = int.tryParse(parts[1]) ?? 0;
        }
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  void savePosition(String trackPath, int positionMs) {
    final positions = getSavedPositions();
    positions[trackPath] = positionMs;
    final encoded = positions.entries.map((e) => '${e.key}:${e.value}').join(',');
    unawaited(_prefs.setString('savedPositions', encoded));
  }

  void clearPosition(String trackPath) {
    final positions = getSavedPositions();
    positions.remove(trackPath);
    final encoded = positions.entries.map((e) => '${e.key}:${e.value}').join(',');
    unawaited(_prefs.setString('savedPositions', encoded));
  }
}
