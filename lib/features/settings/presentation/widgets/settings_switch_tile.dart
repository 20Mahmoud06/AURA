import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/shared/widgets/custom_text.dart';

class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 16.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: title,
                  textColor: AuraColors.text,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
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
          SizedBox(width: 12.w),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AuraColors.primary,
            activeTrackColor: AuraColors.primary.withValues(alpha: 0.36),
            inactiveThumbColor: AuraColors.text.withValues(alpha: 0.80),
            inactiveTrackColor: AuraColors.muted.withValues(alpha: 0.30),
          ),
        ],
      ),
    );
  }
}
