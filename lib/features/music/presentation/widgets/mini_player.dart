import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/core/routing/app_routes.dart';
import 'package:aura/core/services/audio_player_service.dart';
import 'package:aura/database/models/music_item.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  MusicItem? _track;
  StreamSubscription<MusicItem?>? _trackSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<bool>? _playingSub;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    final audioService = AudioPlayerService();
    _track = audioService.currentMusic;
    _trackSub = audioService.currentMusicStream.listen((track) {
      if (mounted) setState(() => _track = track);
    });
    _positionSub = audioService.positionStream.listen((pos) {
      if (!mounted) return;
      if (_isPlaying) setState(() => _position = pos);
    });
    _durationSub = audioService.durationStream.listen((dur) {
      if (!mounted) return;
      if (_isPlaying) setState(() => _duration = dur ?? Duration.zero);
    });
    _playingSub = audioService.playingStream.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });
  }

  @override
  void dispose() {
    _trackSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playingSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = _track;
    if (track == null) return const SizedBox.shrink();

    final audioService = AudioPlayerService();
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.musicPlayer),
      child: Container(
        decoration: BoxDecoration(
          color: AuraColors.surfaceHigh.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: AuraColors.primary.withValues(alpha: 0.10),
              blurRadius: 24.r,
              offset: Offset(0, -4.h),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 16.r,
              offset: Offset(0, -4.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ProgressBar(progress: progress),
            Padding(
              padding: EdgeInsets.only(
                  left: 10.w, right: 2.w, top: 8.h, bottom: 8.h),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: SizedBox(
                      width: 36.r,
                      height: 36.r,
                      child: track.artworkPath != null &&
                              File(track.artworkPath!).existsSync()
                          ? Image.file(File(track.artworkPath!),
                              fit: BoxFit.cover)
                          : Container(
                              color:
                                  AuraColors.surfaceHigh.withValues(alpha: 0.6),
                              child: Icon(Icons.music_note_rounded,
                                  color: AuraColors.muted, size: 16.r),
                            ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          style: TextStyle(
                              color: AuraColors.text,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (track.artist != null && track.artist!.isNotEmpty)
                          Text(
                            track.artist!,
                            style: TextStyle(
                                color: AuraColors.muted,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  IntrinsicHeight(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MiniControlButton(
                          icon: Icons.skip_previous_rounded,
                          onPressed: () => audioService.skipToPrevious(),
                        ),
                        _MiniControlButton(
                          icon: _isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_filled_rounded,
                          color: AuraColors.primary,
                          size: 30.r,
                          onPressed: () {
                            if (_isPlaying) {
                              audioService.pause();
                            } else {
                              audioService.play();
                            }
                          },
                        ),
                        _MiniControlButton(
                          icon: Icons.skip_next_rounded,
                          onPressed: () => audioService.skipToNext(),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: AuraColors.muted, size: 16.r),
                          onPressed: () => audioService.stop(),
                          padding: EdgeInsets.zero,
                          constraints:
                              BoxConstraints(minWidth: 24.w, minHeight: 24.h),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final double size;

  const _MiniControlButton({
    required this.icon,
    required this.onPressed,
    this.color,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: color ?? AuraColors.text, size: size.r),
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(minWidth: 26.w, minHeight: 26.h),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;

  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      child: SizedBox(
        height: 3.h,
        child: Stack(
          children: [
            Container(color: AuraColors.surfaceHigh.withValues(alpha: 0.6)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AuraColors.primary, AuraColors.secondary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AuraColors.primary.withValues(alpha: 0.6),
                      blurRadius: 6.r,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
