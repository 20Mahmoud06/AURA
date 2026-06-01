import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:media_kit/media_kit.dart';
import 'package:aura/core/constants/aura_colors.dart';

class VideoControls extends StatefulWidget {
  final Player player;
  final void Function(bool forward, int seconds)? onSeek;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool hasPrevious;
  final bool hasNext;

  const VideoControls({
    super.key,
    required this.player,
    this.onSeek,
    this.onPrevious,
    this.onNext,
    this.hasPrevious = false,
    this.hasNext = false,
  });

  @override
  State<VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<VideoControls> {
  bool _isPlaying = false;
  StreamSubscription? _playingSub;

  @override
  void initState() {
    super.initState();
    _playingSub = widget.player.stream.playing.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });
  }

  @override
  void dispose() {
    _playingSub?.cancel();
    super.dispose();
  }

  void _seekRelative(int seconds) {
    final current = widget.player.state.position;
    final duration = widget.player.state.duration;
    var target = current + Duration(seconds: seconds);
    if (target < Duration.zero) {
      target = Duration.zero;
    } else if (duration > Duration.zero && target > duration) {
      target = duration;
    }
    widget.player.seek(target);
    widget.onSeek?.call(seconds > 0, seconds.abs());
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final iconSize = isLandscape ? 20.0 : 24.r;
    final navIconSize = isLandscape ? 22.0 : 28.r;
    final buttonExtent = isLandscape ? 42.0 : 48.r;
    return Container(
      width: isLandscape ? 320 : null,
      margin: EdgeInsets.symmetric(horizontal: isLandscape ? 0 : 24.w),
      padding: EdgeInsets.symmetric(
        vertical: isLandscape ? 6 : 12.h,
        horizontal: isLandscape ? 10 : 16.w,
      ),
      decoration: BoxDecoration(
        color: AuraColors.surfaceHigh.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(isLandscape ? 22 : 24.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () => _seekRelative(-5),
            icon: Icon(
              Icons.replay_5_rounded,
              color: AuraColors.muted.withValues(alpha: 0.6),
              size: iconSize,
            ),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints.tight(Size.square(buttonExtent)),
          ),
          IconButton(
            onPressed: widget.onPrevious,
            icon: Icon(
              Icons.skip_previous_rounded,
              color: widget.hasPrevious ? AuraColors.text : AuraColors.muted.withValues(alpha: 0.3),
              size: navIconSize,
            ),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints.tight(Size.square(buttonExtent)),
          ),
          _PlayPauseButton(
            isPlaying: _isPlaying,
            onPressed: () {
              if (_isPlaying) {
                widget.player.pause();
              } else {
                widget.player.play();
              }
            },
            isLandscape: isLandscape,
          ),
          IconButton(
            onPressed: widget.onNext,
            icon: Icon(
              Icons.skip_next_rounded,
              color: widget.hasNext ? AuraColors.text : AuraColors.muted.withValues(alpha: 0.3),
              size: navIconSize,
            ),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints.tight(Size.square(buttonExtent)),
          ),
          IconButton(
            onPressed: () => _seekRelative(5),
            icon: Icon(
              Icons.forward_5_rounded,
              color: AuraColors.muted.withValues(alpha: 0.6),
              size: iconSize,
            ),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints.tight(Size.square(buttonExtent)),
          ),
        ],
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPressed;
  final bool isLandscape;

  const _PlayPauseButton({
    required this.isPlaying,
    required this.onPressed,
    this.isLandscape = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = isLandscape ? 48.0 : 64.r;
    final iconSize = isLandscape ? 26.0 : 32.r;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AuraColors.surfaceHigh.withValues(alpha: 0.4),
        border: Border.all(
          color: AuraColors.primary.withValues(alpha: 0.5),
          width: isLandscape ? 1.6 : 2.r,
        ),
        boxShadow: [
          BoxShadow(
            color: AuraColors.primary.withValues(alpha: 0.2),
            blurRadius: isLandscape ? 14 : 16.r,
            spreadRadius: isLandscape ? 1 : 2.r,
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints.tight(Size.square(size)),
        icon: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: AuraColors.primary,
          size: iconSize,
        ),
      ),
    );
  }
}
