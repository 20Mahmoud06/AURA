import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/shared/widgets/custom_text.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing Icon
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120.r,
                  height: 120.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AuraColors.primary.withValues(alpha: 0.15),
                        blurRadius: 60.r,
                        spreadRadius: 20.r,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 80.r,
                  height: 80.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AuraColors.surfaceHigh.withValues(alpha: 0.8),
                    border: Border.all(
                      color: AuraColors.primary.withValues(alpha: 0.3),
                      width: 1.r,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 36.r,
                    color: AuraColors.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 32.h),
            // Title
            CustomText(
              text: title,
              textColor: AuraColors.text,
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: 12.h),
              CustomText(
                text: subtitle!,
                textColor: AuraColors.muted,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: 40.h),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuraColors.primary.withValues(alpha: 0.1),
                  foregroundColor: AuraColors.primary,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100.r),
                    side: BorderSide(color: AuraColors.primary.withValues(alpha: 0.3)),
                  ),
                ),
                child: CustomText(
                  text: actionLabel!,
                  textColor: AuraColors.primary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

