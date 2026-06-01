import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../database/models/music_item.dart';
import 'settings_service.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal() {
    _player.setLoopMode(LoopMode.all);
    _positionSub = _player.positionStream.listen(_handleRepeatOneOnce);
    _playingSub = _player.playingStream.listen(_onPlayingChanged);
    _currentIndexSub = _player.currentIndexStream.listen(_onTrackChanged);
    _processingStateSub = _player.processingStateStream.listen(_onProcessingState);
  }

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  List<MusicItem> _currentItems = [];
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<int?>? _currentIndexSub;
  StreamSubscription<ProcessingState>? _processingStateSub;
  bool _repeatOneOnceEnabled = false;
  bool _repeatOneReachedEnd = false;
  Timer? _positionSaveTimer;
  int? _previousIndex;
  bool _isManualPrevious = false;
  bool _isManualNext = false;
  bool _isLoading = false;

  final _settings = SettingsService.instance;

  void _handleRepeatOneOnce(Duration position) {
    if (!_repeatOneOnceEnabled || _player.loopMode != LoopMode.one) return;

    final duration = _player.duration;
    if (duration == null || duration.inMilliseconds <= 0) return;

    final remaining = duration - position;
    if (!_repeatOneReachedEnd && remaining.inMilliseconds <= 900) {
      _repeatOneReachedEnd = true;
      return;
    }

    if (_repeatOneReachedEnd && position.inMilliseconds <= 900) {
      _repeatOneOnceEnabled = false;
      _repeatOneReachedEnd = false;
      _player.setLoopMode(LoopMode.off);
    }
  }

  void _onProcessingState(ProcessingState state) {
    if (state == ProcessingState.completed && _player.loopMode == LoopMode.all) {
      if (_currentItems.length > 1) {
        _player.seek(Duration.zero, index: 0);
      } else {
        _player.seek(Duration.zero);
      }
      _player.play();
    }
  }

  void _onPlayingChanged(bool playing) {
    if (playing && _settings.rememberPlaybackPosition) {
      _startPositionSaving();
    } else {
      _stopPositionSaving();
    }
  }

  void _onTrackChanged(int? index) {
    if (index == _previousIndex || index == null) return;
    if (_previousIndex != null && _previousIndex! < _currentItems.length) {
      _saveCurrentPosition();
    }
    _previousIndex = index;
    if (_isManualPrevious || _isManualNext) {
      _isManualPrevious = false;
      _isManualNext = false;
      _player.seek(Duration.zero);
      return;
    }
    if (_settings.rememberPlaybackPosition && index < _currentItems.length) {
      _restoreTrackPosition(_currentItems[index]);
    }
  }

  void _startPositionSaving() {
    _positionSaveTimer?.cancel();
    _positionSaveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _saveCurrentPosition();
    });
  }

  void _stopPositionSaving() {
    _positionSaveTimer?.cancel();
    _positionSaveTimer = null;
  }

  void _saveCurrentPosition() {
    final pos = _player.position.inMilliseconds;
    final index = _player.currentIndex;
    if (index == null || index >= _currentItems.length) return;
    final track = _currentItems[index];
    if (pos > 2000) {
      _settings.savePosition(track.path, pos);
    }
  }

  void _restoreTrackPosition(MusicItem track) {
    final savedPos = _settings.getSavedPositions()[track.path];
    if (savedPos != null && savedPos > 0) {
      _player.seek(Duration(milliseconds: savedPos));
    }
  }

  Future<void> playMusic(MusicItem music, {List<MusicItem>? allItems}) async {
    if (_isLoading) return;
    _isLoading = true;
    try {
      if (allItems != null && allItems.isNotEmpty) {
        _currentItems = allItems;
        final index = allItems.indexWhere((item) => item.id == music.id);
        
        final audioSources = allItems.map((item) {
          return AudioSource.uri(
            Uri.file(item.path),
            tag: MediaItem(
              id: item.id.toString(),
              album: item.artist ?? 'Unknown Artist',
              title: (item.title.trim().isEmpty) ? 'Unknown Title' : item.title,
              artUri: item.artworkPath != null ? Uri.file(item.artworkPath!) : null,
            ),
          );
        }).toList();
        
        // ignore: deprecated_member_use
        await _player.setAudioSource(ConcatenatingAudioSource(children: audioSources), initialIndex: index >= 0 ? index : 0);
        _previousIndex = index >= 0 ? index : 0;
      } else {
        _currentItems = [music];
        _previousIndex = 0;
        await _player.setAudioSource(
          AudioSource.uri(
            Uri.file(music.path),
            tag: MediaItem(
              id: music.id.toString(),
              album: music.artist ?? 'Unknown Artist',
              title: (music.title.trim().isEmpty) ? 'Unknown Title' : music.title,
              artUri: music.artworkPath != null ? Uri.file(music.artworkPath!) : null,
            ),
          ),
        );
      }
      
      await _player.play();

      if (_settings.rememberPlaybackPosition) {
        _restoreTrackPosition(music);
      }
    } finally {
      _isLoading = false;
    }
  }

  void play() => _player.play();
  void pause() => _player.pause();
  void stop() {
    _player.stop();
    _currentItems = [];
    _previousIndex = null;
  }
  void seek(Duration position) => _player.seek(position);
  void seekRelative(Duration offset) {
    final current = _player.position;
    final target = current + offset;
    final duration = _player.duration ?? Duration.zero;
    if (target < Duration.zero) {
      _player.seek(Duration.zero);
    } else if (target > duration) {
      _player.seek(duration);
    } else {
      _player.seek(target);
    }
  }
  void skipToNext() {
    _isManualNext = true;
    _player.seekToNext();
  }
  void skipToPrevious() {
    _isManualPrevious = true;
    _player.seekToPrevious();
  }
  Future<void> playQueueIndex(int index) async {
    if (index < 0 || index >= _currentItems.length) return;
    await _player.seek(Duration.zero, index: index);
    await _player.play();
  }
  void setShuffleModeEnabled(bool enabled) => _player.setShuffleModeEnabled(enabled);
  void setLoopMode(LoopMode mode) {
    _repeatOneOnceEnabled = mode == LoopMode.one;
    _repeatOneReachedEnd = false;
    _player.setLoopMode(mode);
  }
  void setSpeed(double speed) => _player.setSpeed(speed);
  
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<bool> get shuffleModeEnabledStream => _player.shuffleModeEnabledStream;
  Stream<LoopMode> get loopModeStream => _player.loopModeStream;
  Stream<double> get speedStream => _player.speedStream;
  
  Stream<MusicItem?> get currentMusicStream => _player.currentIndexStream.map((index) {
    if (index == null || _currentItems.isEmpty || index >= _currentItems.length) return null;
    return _currentItems[index];
  });

  MusicItem? get currentMusic {
    final index = _player.currentIndex;
    if (index == null || _currentItems.isEmpty || index >= _currentItems.length) return null;
    return _currentItems[index];
  }

  List<MusicItem> get currentQueue => List.unmodifiable(_currentItems);

  int? get currentQueueIndex => _player.currentIndex;

  double get currentSpeed => _player.speed;

  void dispose() {
    _saveCurrentPosition();
    _stopPositionSaving();
    _positionSub?.cancel();
    _playingSub?.cancel();
    _currentIndexSub?.cancel();
    _processingStateSub?.cancel();
    _player.dispose();
  }
}
