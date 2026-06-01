import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/core/services/audio_player_service.dart';
import 'dart:math' as math;

class PlayerVisualizer extends StatefulWidget {
  const PlayerVisualizer({super.key, required this.isPlaying});
  
  final bool isPlaying;

  @override
  State<PlayerVisualizer> createState() => _PlayerVisualizerState();
}

class _PlayerVisualizerState extends State<PlayerVisualizer> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _intensityController;
  late Animation<double> _intensityAnimation;
  
  final heights = [12.0, 24.0, 16.0, 36.0, 18.0, 28.0, 14.0, 32.0, 20.0, 12.0];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _intensityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      value: widget.isPlaying ? 1.0 : 0.0,
    );

    _intensityAnimation = Tween<double>(begin: 0.15, end: 1.0).animate(
      CurvedAnimation(
        parent: _intensityController,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant PlayerVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _intensityController.forward();
      } else {
        _intensityController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _intensityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioService = AudioPlayerService();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SeekButton(
            icon: Icons.replay_5_rounded,
            onPressed: () => audioService.seekRelative(Duration(seconds: -5)),
          ),
          SizedBox(width: 12.w),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              heights.length,
              (index) {
                return AnimatedBuilder(
                  animation: Listenable.merge([_waveController, _intensityController]),
                  builder: (context, child) {
                    final phase = index * (math.pi / heights.length);
                    final waveValue = math.sin((_waveController.value * math.pi) + phase).abs();
                    final intensity = _intensityAnimation.value;
                    final currentHeight = heights[index] * 0.4 + (heights[index] * 0.8 * waveValue * intensity);

                    return Container(
                      width: 4.w,
                      height: currentHeight.h,
                      margin: EdgeInsets.symmetric(horizontal: 2.w),
                      decoration: BoxDecoration(
                        color: AuraColors.primary.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(2.r),
                        boxShadow: [
                          BoxShadow(
                            color: AuraColors.primary.withValues(alpha: 0.4),
                            blurRadius: 6.r,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SizedBox(width: 12.w),
          _SeekButton(
            icon: Icons.forward_5_rounded,
            onPressed: () => audioService.seekRelative(Duration(seconds: 5)),
          ),
        ],
      ),
    );
  }
}

class _SeekButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _SeekButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44.r,
      height: 44.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AuraColors.surfaceHigh.withValues(alpha: 0.5),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: AuraColors.muted, size: 22.r),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
