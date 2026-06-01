import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:aura/core/constants/aura_colors.dart';

/// Vertical brightness/volume slider shown on the screen edge while gesturing.
class VideoEdgeSlider extends StatelessWidget {
  const VideoEdgeSlider({
    super.key,
    required this.topIcon,
    required this.bottomIcon,
    required this.value,
  });

  final IconData topIcon;
  final IconData bottomIcon;
  final double value;

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final barHeight = isLandscape ? 100.0 : 128.h;
    final barWidth = isLandscape ? 24.0 : 28.w;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 8 : 10.w,
        vertical: isLandscape ? 8 : 12.h,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(isLandscape ? 16 : 20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            topIcon,
            color: Colors.white.withValues(alpha: 0.95),
            size: isLandscape ? 18 : 20.r,
          ),
          SizedBox(height: isLandscape ? 6 : 8.h),
          SizedBox(
            height: barHeight,
            width: barWidth,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isLandscape ? 10 : 12.r),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  FractionallySizedBox(
                    heightFactor: value.clamp(0.0, 1.0),
                    widthFactor: 1,
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AuraColors.primary,
                            AuraColors.primary.withValues(alpha: 0.65),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: isLandscape ? 6 : 8.h),
          Icon(
            bottomIcon,
            color: Colors.white.withValues(alpha: 0.55),
            size: isLandscape ? 16 : 18.r,
          ),
        ],
      ),
    );
  }
}
