import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/shared/widgets/aura_icon_button.dart';
import 'package:aura/shared/widgets/custom_text.dart';

class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AuraIconButton(
          icon: icon,
          size: 38.r,
          backgroundColor: AuraColors.primary.withValues(alpha: 0.12),
          iconColor: AuraColors.primary,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: title,
                textColor: AuraColors.text,
                fontSize: 13.sp,
                fontWeight: FontWeight.w900,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 3.h),
              CustomText(
                text: subtitle,
                textColor: AuraColors.muted,
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
