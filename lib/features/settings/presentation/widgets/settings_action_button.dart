import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/core/theme/app_borders.dart';
import 'package:aura/shared/widgets/custom_text.dart';

class SettingsActionButton extends StatelessWidget {
  const SettingsActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorders.full,
        child: Ink(
          height: 46.h,
          decoration: BoxDecoration(
            borderRadius: AppBorders.full,
            gradient: const LinearGradient(
              colors: [
                AuraColors.primary,
                AuraColors.secondary,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AuraColors.primary.withValues(alpha: 0.22),
                blurRadius: 22.r,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AuraColors.neutral, size: 16.r),
              SizedBox(width: 8.w),
              CustomText(
                text: label,
                textColor: AuraColors.neutral,
                fontSize: 12.sp,
                fontWeight: FontWeight.w900,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
