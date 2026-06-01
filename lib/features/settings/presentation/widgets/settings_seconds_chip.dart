import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/core/theme/app_borders.dart';
import 'package:aura/shared/widgets/custom_text.dart';

class SecondsChip extends StatelessWidget {
  const SecondsChip({super.key, 
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AuraColors.primary.withValues(alpha: 0.16) : AuraColors.neutral.withValues(alpha: 0.34),
          borderRadius: AppBorders.full,
          border: Border.all(
            color: isSelected ? AuraColors.primary : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: CustomText(
          text: label,
          textColor: isSelected ? AuraColors.primary : AuraColors.muted,
          fontSize: 11.sp,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
