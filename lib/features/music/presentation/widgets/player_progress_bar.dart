import 'package:aura/core/services/audio_player_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/shared/widgets/custom_text.dart';

class PlayerProgressBar extends StatelessWidget {
  const PlayerProgressBar({
    super.key,
    required this.currentPosition,
    required this.totalDuration,
    required this.progress,
    this.rawTotalDuration,
  });

  final String currentPosition;
  final String totalDuration;
  final double progress;
  final Duration? rawTotalDuration;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(
              text: currentPosition,
              textColor: AuraColors.muted,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
            CustomText(
              text: totalDuration,
              textColor: AuraColors.muted,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
        SizedBox(height: 8.h),
        LayoutBuilder(
          builder: (context, constraints) {
            final clamped = progress.clamp(0.0, 1.0);
            final trackWidth = constraints.maxWidth;
            final progressWidth = trackWidth * clamped;
            final thumbOffset = (progressWidth - 8.r).clamp(0.0, trackWidth - 16.r);

            return GestureDetector(
              onHorizontalDragUpdate: (details) {
                if (rawTotalDuration == null) return;
                final dx = details.localPosition.dx.clamp(0.0, trackWidth);
                final fraction = dx / trackWidth;
                final position = Duration(milliseconds: (rawTotalDuration!.inMilliseconds * fraction).round());
                AudioPlayerService().seek(position);
              },
              onTapDown: (details) {
                if (rawTotalDuration == null) return;
                final dx = details.localPosition.dx.clamp(0.0, trackWidth);
                final fraction = dx / trackWidth;
                final position = Duration(milliseconds: (rawTotalDuration!.inMilliseconds * fraction).round());
                AudioPlayerService().seek(position);
              },
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 24.h,
                    color: Colors.transparent,
                  ),
                  Container(
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AuraColors.surfaceHigh.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  Container(
                    height: 4.h,
                    width: progressWidth,
                    decoration: BoxDecoration(
                      color: AuraColors.primary,
                      borderRadius: BorderRadius.circular(2.r),
                      boxShadow: [
                        BoxShadow(
                          color: AuraColors.primary.withValues(alpha: 0.6),
                          blurRadius: 8.r,
                          spreadRadius: 1.r,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: thumbOffset,
                    child: Container(
                      width: 16.r,
                      height: 16.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AuraColors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: AuraColors.primary.withValues(alpha: 0.8),
                            blurRadius: 12.r,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
