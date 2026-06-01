import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/shared/widgets/custom_text.dart';

class SettingsTitle extends StatelessWidget {
  const SettingsTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: 'Settings',
          textColor: AuraColors.text,
          fontSize: 15.sp,
          fontWeight: FontWeight.w900,
        ),
        SizedBox(height: 5.h),
        CustomText(
          text: 'Customize your cinematic experience.',
          textColor: AuraColors.muted,
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
        ),
      ],
    );
  }
}
