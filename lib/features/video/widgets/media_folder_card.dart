import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/core/theme/app_borders.dart';
import 'package:aura/features/video/models/media_folder_item.dart';
import 'package:aura/shared/widgets/custom_text.dart';

class MediaFolderCard extends StatelessWidget {
  const MediaFolderCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final MediaFolderItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: AuraColors.surfaceHigh,
            borderRadius: AppBorders.lg,
            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 32.r,
              color: item.color,
            ),
            SizedBox(height: 6.h),
            CustomText(
              text: item.title,
              textColor: AuraColors.text,
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            CustomText(
              text: item.subtitle,
              textColor: AuraColors.muted,
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
