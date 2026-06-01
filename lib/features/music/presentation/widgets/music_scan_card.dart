import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/core/theme/app_borders.dart';
import 'package:aura/shared/widgets/aura_icon_button.dart';
import 'package:aura/shared/widgets/custom_text.dart';

class MusicScanCard extends StatelessWidget {
  const MusicScanCard({super.key, this.onScanTap});

  final VoidCallback? onScanTap;

  void _scanMusic(BuildContext context) {
    if (onScanTap != null) {
      onScanTap!.call();
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text('Music scan UI selected')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AuraColors.surface.withValues(alpha: 0.82),
        borderRadius: AppBorders.lg,
        border: Border.all(color: AuraColors.primary.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          AuraIconButton(
            icon: Icons.library_music_rounded,
            size: 42.r,
            backgroundColor: AuraColors.primary.withValues(alpha: 0.12),
            iconColor: AuraColors.primary,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: 'Music Library',
                  textColor: AuraColors.text,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w900,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 5.h),
                CustomText(
                  text: 'Scan songs, albums, artists, and local playlists.',
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
          GestureDetector(
            onTap: () => _scanMusic(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AuraColors.primary.withValues(alpha: 0.14),
                borderRadius: AppBorders.full,
                border: Border.all(color: AuraColors.primary.withValues(alpha: 0.24)),
              ),
              child: CustomText(
                text: 'Scan',
                textColor: AuraColors.primary,
                fontSize: 11.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
