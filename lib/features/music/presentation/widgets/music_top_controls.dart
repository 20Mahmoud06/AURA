import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/core/theme/app_borders.dart';
import 'package:aura/shared/widgets/custom_text.dart';

class MusicTopControls extends StatelessWidget {
  const MusicTopControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.h,
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        color: AuraColors.neutral.withValues(alpha: 0.78),
        borderRadius: AppBorders.md,
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: AuraColors.muted, size: 19.r),
          SizedBox(width: 10.w),
          Expanded(
            child: CustomText(
              text: 'Search Music',
              textColor: AuraColors.muted,
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
