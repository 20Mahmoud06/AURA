import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/core/services/settings_service.dart';
import 'package:aura/core/services/picture_in_picture_service.dart';
import 'package:aura/database/models/video_item.dart';
import '../widgets/video_controls.dart';
import '../widgets/video_top_bar.dart';
import '../widgets/video_edge_slider.dart';
import '../widgets/seek_hint_badge.dart';
import '../widgets/speed_hint_badge.dart';
import '../widgets/playback_rate_panel.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;
  final List<VideoItem> videoItems;
  final int initialIndex;

  const VideoPlayerScreen({
    super.key,
    this.videoPath = '',
    this.videoItems = const [],
    this.initialIndex = 0,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  bool _showControls = false;
  late final Player _player;
  late final VideoController _videoController;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _playingSub;
  StreamSubscription? _completedSub;
  bool _isPlaying = false;
  Timer? _hideTimer;
  double _brightness = 0.7;
  double _volume = 1.0;
  bool _showVolumeBrightness = false;
  String? _activeGesture;
  bool _showSeekFeedback = false;
  bool _seekForward = true;
  int _seekSeconds = 5;
  Timer? _seekFeedbackTimer;
  bool _isMuted = false;
  double _playbackRate = 1.0;
  bool _showRatePanel = false;
  bool _isInPipMode = false;

  double? _panStartX;
  bool _isAdjustingGesture = false;

  bool _isLocked = false;

  bool _settingsPictureInPicture = true;
  bool _settingsGestureControls = true;
  bool _settingsDoubleTapSeek = true;
  int _settingsDoubleTapSeconds = 10;
  bool _settingsLongPressSpeed = true;
  bool _settingsRememberSpeed = false;

  bool _isLongPressing = false;
  double _previousPlaybackRate = 1.0;

  int _currentIndex = 0;
  List<VideoItem> _videoItems = [];
  bool get _hasMultipleVideos => _videoItems.length > 1;
  bool get _hasPrevious => _hasMultipleVideos && _currentIndex > 0;
  bool get _hasNext => _hasMultipleVideos && _currentIndex < _videoItems.length - 1;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);
    _currentIndex = widget.initialIndex;
    _videoItems = widget.videoItems;
    _initPlayer();
    _listenToStreams();
    _loadSettings();
    _bindPipListener();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _bindPipListener() {
    PictureInPictureService.instance.onPipModeChanged = (isActive) {
      if (!mounted) return;
      setState(() {
        _isInPipMode = isActive;
        if (isActive) {
          _showControls = false;
          _showVolumeBrightness = false;
          _showRatePanel = false;
          _activeGesture = null;
          _hideTimer?.cancel();
        }
      });
    };
  }

  void _loadSettings() {
    final s = SettingsService.instance;
    _settingsPictureInPicture = s.pictureInPicture;
    _settingsGestureControls = s.gestureControls;
    _settingsDoubleTapSeek = s.doubleTapSeek;
    _settingsDoubleTapSeconds = s.doubleTapSeconds;
    _settingsLongPressSpeed = s.longPressSpeed;
    _settingsRememberSpeed = s.rememberPlaybackSpeed;
    if (_settingsRememberSpeed) {
      final saved = s.savedPlaybackSpeed;
      _playbackRate = saved;
      _player.setRate(saved);
    }
  }

  void _initPlayer() async {
    final path = _videoItems.isNotEmpty && _currentIndex < _videoItems.length
        ? _videoItems[_currentIndex].path
        : widget.videoPath;
    if (path.isNotEmpty) {
      final file = File(path);
      if (await file.exists()) {
        await _player.open(Media(path));
        await _player.setVolume(_volume * 100);
        _player.play();
        setState(() => _showControls = true);
        _startHideTimer();
      }
    }
  }

  void _listenToStreams() {
    _positionSub = _player.stream.position.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _durationSub = _player.stream.duration.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _playingSub = _player.stream.playing.listen((p) {
      if (mounted) setState(() => _isPlaying = p);
    });
    _completedSub = _player.stream.completed.listen((c) {
      if (c && mounted) {
        setState(() => _position = _duration);
      }
    });
  }

  @override
  void dispose() {
    PictureInPictureService.instance.onPipModeChanged = null;
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playingSub?.cancel();
    _completedSub?.cancel();
    _hideTimer?.cancel();
    _seekFeedbackTimer?.cancel();
    _player.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      _showVolumeBrightness = false;
      _activeGesture = null;
      if (!_showControls) {
        _showRatePanel = false;
      }
    });
    if (_showControls) _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showControls = false;
          _showVolumeBrightness = false;
          _activeGesture = null;
          _showRatePanel = false;
        });
      }
    });
  }

  void _onPanStart(DragStartDetails details) {
    if (!_settingsGestureControls || _isInPipMode) return;
    _panStartX = details.localPosition.dx;
    _isAdjustingGesture = false;
    _hideTimer?.cancel();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_settingsGestureControls || _isInPipMode || _panStartX == null) {
      return;
    }

    final width = MediaQuery.sizeOf(context).width;

    if (!_isAdjustingGesture) {
      if (details.delta.dy.abs() <= details.delta.dx.abs()) return;

      if (_panStartX! < width * 0.45) {
        _activeGesture = 'left';
      } else if (_panStartX! > width * 0.55) {
        _activeGesture = 'right';
      } else {
        return;
      }

      _isAdjustingGesture = true;
      setState(() => _showVolumeBrightness = true);
    }

    if (!_isAdjustingGesture || _activeGesture == null) return;

    final screenHeight = MediaQuery.sizeOf(context).height;
    final delta = screenHeight == 0 ? 0.0 : details.delta.dy / screenHeight;

    setState(() {
      if (_activeGesture == 'left') {
        _brightness = (_brightness - delta).clamp(0.0, 1.0);
      } else {
        _volume = (_volume - delta).clamp(0.0, 1.0);
        if (!_isMuted) {
          _player.setVolume(_volume * 100);
        }
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _panStartX = null;
    _isAdjustingGesture = false;
    _activeGesture = null;
    if (mounted) {
      setState(() => _showVolumeBrightness = false);
    }
    _startHideTimer();
  }

  void _onTap() {
    if (_isInPipMode) {
      if (_isPlaying) {
        _player.pause();
      } else {
        _player.play();
      }
      return;
    }
    _toggleControls();
  }

  void _onDoubleTap(bool forward) {
    if (!_settingsDoubleTapSeek || _isInPipMode) return;
    final seconds = _settingsDoubleTapSeconds;
    final seekBy = Duration(seconds: forward ? seconds : -seconds);
    final target = _clampSeekPosition(_position + seekBy);
    _player.seek(target);
    _showSeekHint(forward, seconds);
  }

  void _onCenterDoubleTap() {
    if (_isInPipMode) return;
    if (_isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  Duration _clampSeekPosition(Duration target) {
    if (target < Duration.zero) return Duration.zero;
    if (_duration > Duration.zero && target > _duration) return _duration;
    return target;
  }

  void _showSeekHint(bool forward, int seconds) {
    _seekFeedbackTimer?.cancel();
    setState(() {
      _seekForward = forward;
      _seekSeconds = seconds;
      _showSeekFeedback = true;
    });
    _seekFeedbackTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _showSeekFeedback = false);
    });
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (!_settingsLongPressSpeed || _isInPipMode) return;
    _previousPlaybackRate = _playbackRate;
    _player.setRate(2.0);
    setState(() {
      _playbackRate = 2.0;
      _isLongPressing = true;
    });
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (!_isLongPressing) return;
    _player.setRate(_previousPlaybackRate);
    setState(() {
      _playbackRate = _previousPlaybackRate;
      _isLongPressing = false;
    });
  }

  void _onLongPressCancel() {
    if (!_isLongPressing) return;
    _player.setRate(_previousPlaybackRate);
    setState(() {
      _playbackRate = _previousPlaybackRate;
      _isLongPressing = false;
    });
  }

  void _goToPrevious() {
    if (!_hasPrevious) return;
    final newIndex = _currentIndex - 1;
    _loadVideoAtIndex(newIndex);
  }

  void _goToNext() {
    if (!_hasNext) return;
    final newIndex = _currentIndex + 1;
    _loadVideoAtIndex(newIndex);
  }

  Future<void> _loadVideoAtIndex(int index) async {
    if (index < 0 || index >= _videoItems.length) return;
    final path = _videoItems[index].path;
    final file = File(path);
    if (!await file.exists()) return;
    await _player.open(Media(path));
    await _player.setVolume(_isMuted ? 0 : _volume * 100);
    _player.play();
    setState(() {
      _currentIndex = index;
      _position = Duration.zero;
      _duration = Duration.zero;
    });
  }

  void _goBack() {
    context.pop();
  }

  void _toggleLock() {
    setState(() => _isLocked = !_isLocked);
    if (!_isLocked) _startHideTimer();
  }

  String get _currentVideoTitle {
    if (_currentIndex >= 0 && _currentIndex < _videoItems.length) {
      final title = _videoItems[_currentIndex].title;
      return title.trim().isEmpty ? 'Unknown Video' : title;
    }
    return '';
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    if (_isMuted) {
      _player.setVolume(0);
    } else {
      _player.setVolume(_volume * 100);
    }
  }

  void _toggleRatePanel() {
    setState(() => _showRatePanel = !_showRatePanel);
    if (_showRatePanel) {
      _hideTimer?.cancel();
    } else {
      _startHideTimer();
    }
  }

  void _setPlaybackRate(double rate) {
    setState(() => _playbackRate = rate);
    _player.setRate(rate);
    if (_settingsRememberSpeed) {
      SettingsService.instance.setSavedPlaybackSpeed(rate);
    }
    if (_isLongPressing) {
      _isLongPressing = false;
    }
    _startHideTimer();
  }

  void _toggleRotation() {
    final orientation = MediaQuery.of(context).orientation;
    if (orientation == Orientation.portrait) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
    _startHideTimer();
  }

  Future<void> _onPictureInPicture() async {
    if (!_settingsPictureInPicture) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enable Picture-in-Picture in Settings'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    final supported = await PictureInPictureService.instance.isSupported;
    if (!supported) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PiP not supported on this device'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    await PictureInPictureService.instance.enterPictureInPicture();
  }

  void _seekTo(double value) {
    final seekPos =
    Duration(milliseconds: (value * _duration.inMilliseconds).round());
    _player.seek(seekPos);
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isInPipMode) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.videoPath.isNotEmpty)
                Video(
                  controller: _videoController,
                  fill: Colors.black,
                  controls: (state) => const SizedBox.shrink(),
                )
              else
                const ColoredBox(color: Colors.black),
              if (!_isPlaying)
                Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white.withValues(alpha: 0.85),
                    size: 40,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final controlsVisible = _showControls;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        onDoubleTapDown: _isLocked
            ? null
            : (details) {
                final width = MediaQuery.sizeOf(context).width;
                final dx = details.localPosition.dx;
                final leftBound = width * 0.45;
                final rightBound = width * 0.55;
                if (dx > leftBound && dx < rightBound) {
                  _onCenterDoubleTap();
                } else {
                  _onDoubleTap(dx > width / 2);
                }
              },
        onPanStart: _isLocked ? null : _onPanStart,
        onPanUpdate: _isLocked ? null : _onPanUpdate,
        onPanEnd: _isLocked ? null : _onPanEnd,
        onLongPressStart: _isLocked ? null : _onLongPressStart,
        onLongPressEnd: _isLocked ? null : _onLongPressEnd,
        onLongPressCancel: _isLocked ? null : _onLongPressCancel,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.videoPath.isNotEmpty)
              Video(
                controller: _videoController,
                fill: Colors.black,
                controls: (state) => const SizedBox.shrink(),
              )
            else
              Container(
                color: AuraColors.surfaceHigh,
                child: Center(
                  child: Icon(
                    Icons.video_camera_back_outlined,
                    size: 64.r,
                    color: AuraColors.muted,
                  ),
                ),
              ),
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black
                      .withValues(alpha: (1 - _brightness).clamp(0.0, 0.85)),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: controlsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                        Colors.black,
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            if (_showVolumeBrightness)
              Positioned(
                left: isLandscape ? 12 : 16.w,
                top: 0,
                bottom: 0,
                child: Center(
                  child: VideoEdgeSlider(
                    topIcon: Icons.wb_sunny_rounded,
                    bottomIcon: Icons.wb_sunny_outlined,
                    value: _brightness,
                  ),
                ),
              ),
            if (_showVolumeBrightness)
              Positioned(
                right: isLandscape ? 12 : 16.w,
                top: 0,
                bottom: 0,
                child: Center(
                  child: VideoEdgeSlider(
                    topIcon: Icons.volume_up_rounded,
                    bottomIcon: Icons.volume_mute_rounded,
                    value: _volume,
                  ),
                ),
              ),
            if (!_isLocked)
              IgnorePointer(
                ignoring: !_showSeekFeedback,
                child: AnimatedOpacity(
                  opacity: _showSeekFeedback ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: AnimatedScale(
                    scale: _showSeekFeedback ? 1.0 : 0.9,
                    duration: const Duration(milliseconds: 150),
                    child: Align(
                      alignment: _seekForward
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32.w),
                        child: SeekHintBadge(
                          forward: _seekForward,
                          seconds: _seekSeconds,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (!_isLocked)
              IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _isLongPressing ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Align(
                    alignment: Alignment.center,
                    child: SpeedHintBadge(),
                  ),
                ),
              ),
            IgnorePointer(
              ignoring: !(controlsVisible && _showRatePanel),
              child: AnimatedOpacity(
                opacity: controlsVisible && _showRatePanel ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: isLandscape ? 52 : 72.h,
                      right: isLandscape ? 12 : 12.w,
                    ),
                    child: PlaybackRatePanel(
                      value: _playbackRate,
                      onSelect: _setPlaybackRate,
                      onSliderChange: _setPlaybackRate,
                      compact: isLandscape,
                    ),
                  ),
                ),
              ),
            ),
            IgnorePointer(
              ignoring: !controlsVisible,
              child: AnimatedOpacity(
                opacity: controlsVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: SafeArea(
                  child: Column(
                    children: [
                      VideoTopBar(
                        onBack: _goBack,
                        isMuted: _isMuted,
                        playbackRate: _playbackRate,
                        showPip: _settingsPictureInPicture,
                        onPictureInPicture: _onPictureInPicture,
                        onToggleRate: _toggleRatePanel,
                        onToggleMute: _toggleMute,
                        onToggleRotation: _toggleRotation,
                        onToggleLock: _toggleLock,
                        isLocked: _isLocked,
                        videoTitle: _currentVideoTitle,
                      ),
                      const Spacer(),
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: isLandscape ? 10 : 20.h,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isLandscape ? 40 : 20.w,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    _formatDuration(_position),
                                    style: TextStyle(
                                      color: AuraColors.text,
                                      fontSize: isLandscape ? 11 : 10.sp,
                                    ),
                                  ),
                                  SizedBox(width: isLandscape ? 8 : 6.w),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderThemeData(
                                        trackHeight: isLandscape ? 3 : 3.h,
                                        activeTrackColor: AuraColors.primary,
                                        inactiveTrackColor: AuraColors.surfaceHigh
                                            .withValues(alpha: 0.5),
                                        thumbColor: AuraColors.primary,
                                        overlayColor: AuraColors.primary
                                            .withValues(alpha: 0.2),
                                        thumbShape: RoundSliderThumbShape(
                                          enabledThumbRadius:
                                          isLandscape ? 5 : 6.r,
                                        ),
                                      ),
                                      child: Slider(
                                        value: _duration.inMilliseconds > 0
                                            ? (_position.inMilliseconds /
                                            _duration.inMilliseconds)
                                            .clamp(0.0, 1.0)
                                            : 0.0,
                                        onChanged: _seekTo,
                                        onChangeStart: (_) =>
                                            _hideTimer?.cancel(),
                                        onChangeEnd: (_) => _startHideTimer(),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: isLandscape ? 8 : 6.w),
                                  Text(
                                    _formatDuration(_duration),
                                    style: TextStyle(
                                      color: AuraColors.text,
                                      fontSize: isLandscape ? 11 : 10.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: isLandscape ? 8 : 12.h),
                            VideoControls(
                              player: _player,
                              onSeek: _showSeekHint,
                              onPrevious: _goToPrevious,
                              onNext: _goToNext,
                              hasPrevious: _hasPrevious,
                              hasNext: _hasNext,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

