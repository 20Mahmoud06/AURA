import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/core/services/audio_player_service.dart';
import 'package:just_audio/just_audio.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key, this.isPlaying = false});
  final bool isPlaying;

  void _showNote(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: AuraColors.text, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        backgroundColor: AuraColors.surfaceHigh,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        margin: EdgeInsets.only(bottom: 24.h, left: 48.w, right: 48.w),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioService = AudioPlayerService();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        StreamBuilder<bool>(
          stream: audioService.shuffleModeEnabledStream,
          builder: (context, snapshot) {
            final isShuffle = snapshot.data ?? false;
            return IconButton(
              onPressed: () {
                final newState = !isShuffle;
                audioService.setShuffleModeEnabled(newState);
                _showNote(context, newState ? 'Shuffle On' : 'Shuffle Off');
              },
              icon: Icon(
                Icons.shuffle_rounded,
                color: isShuffle ? AuraColors.primary : AuraColors.muted.withValues(alpha: 0.6),
                size: 24.r,
              ),
            );
          }
        ),
        _ControlButton(
          icon: Icons.skip_previous_rounded,
          onPressed: () {
            audioService.skipToPrevious();
          },
        ),
        _PlayPauseButton(
          isPlaying: isPlaying,
          onPressed: () {
            if (isPlaying) {
              audioService.pause();
            } else {
              audioService.play();
            }
          },
        ),
        _ControlButton(
          icon: Icons.skip_next_rounded,
          onPressed: () {
            audioService.skipToNext();
          },
        ),
        StreamBuilder<LoopMode>(
          stream: audioService.loopModeStream,
          builder: (context, snapshot) {
            final loopMode = snapshot.data ?? LoopMode.off;
            IconData icon = Icons.repeat_rounded;
            Color color = AuraColors.muted.withValues(alpha: 0.6);
            
            if (loopMode == LoopMode.all) {
              color = AuraColors.primary;
            } else if (loopMode == LoopMode.one) {
              icon = Icons.repeat_one_rounded;
              color = AuraColors.primary;
            }

            return IconButton(
              onPressed: () {
                if (loopMode == LoopMode.off) {
                  audioService.setLoopMode(LoopMode.all);
                  _showNote(context, 'Repeat All');
                } else if (loopMode == LoopMode.all) {
                  audioService.setLoopMode(LoopMode.one);
                  _showNote(context, 'Repeat One');
                } else {
                  audioService.setLoopMode(LoopMode.off);
                  _showNote(context, 'Repeat Off');
                }
              },
              icon: Icon(
                icon,
                color: color,
                size: 24.r,
              ),
            );
          }
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48.r,
      height: 48.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AuraColors.surfaceHigh.withValues(alpha: 0.5),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: AuraColors.text,
          size: 28.r,
        ),
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({
    required this.isPlaying,
    required this.onPressed,
  });

  final bool isPlaying;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72.r,
      height: 72.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AuraColors.primary,
            AuraColors.secondary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AuraColors.primary.withValues(alpha: 0.4),
            blurRadius: 24.r,
            spreadRadius: 4.r,
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: AuraColors.surface,
          size: 36.r,
        ),
      ),
    );
  }
}
