import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:aura/core/constants/aura_colors.dart';

class SeekHintBadge extends StatelessWidget {
  final bool forward;
  final int seconds;

  const SeekHintBadge({super.key, required this.forward, this.seconds = 5});

  @override
  Widget build(BuildContext context) {
    final IconData displayIcon;
    if (seconds == 5) {
      displayIcon =
      forward ? Icons.forward_5_rounded : Icons.replay_5_rounded;
    } else if (seconds == 10) {
      displayIcon =
      forward ? Icons.forward_10_rounded : Icons.replay_10_rounded;
    } else if (seconds == 30) {
      displayIcon =
      forward ? Icons.forward_30_rounded : Icons.replay_30_rounded;
    } else {
      displayIcon =
      forward ? Icons.forward_10_rounded : Icons.replay_10_rounded;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AuraColors.surfaceHigh.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!forward) Icon(displayIcon, color: AuraColors.text, size: 20.r),
          if (!forward) SizedBox(width: 8.w),
          Text(
            forward ? 'Forward ${seconds}s' : 'Back ${seconds}s',
            style: TextStyle(
              color: AuraColors.text,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (forward) SizedBox(width: 8.w),
          if (forward) Icon(displayIcon, color: AuraColors.text, size: 20.r),
        ],
      ),
    );
  }
}
