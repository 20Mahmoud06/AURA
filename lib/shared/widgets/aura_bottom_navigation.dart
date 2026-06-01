import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/core/theme/app_borders.dart';
import 'package:aura/core/theme/app_durations.dart';
import 'package:aura/shared/widgets/custom_text.dart';

enum AuraNavTab { videos, music }

class AuraBottomNavigation extends StatelessWidget {
  const AuraBottomNavigation({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  final AuraNavTab currentTab;
  final ValueChanged<AuraNavTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return Positioned(
      left: isLandscape ? 40.w : 24.w,
      right: isLandscape ? 40.w : 24.w,
      bottom: isLandscape ? 8.h : 16.h,
      child: SafeArea(
        top: false,
        child: Container(
          height: isLandscape ? 48.h : 64.h,
          padding: EdgeInsets.all(isLandscape ? 4.r : 8.r),
          decoration: BoxDecoration(
            color: AuraColors.surfaceHigh.withValues(alpha: 0.86),
            borderRadius: AppBorders.xl,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: AuraColors.primary.withValues(alpha: 0.12),
                blurRadius: 28.r,
                offset: Offset(0, 12.h),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gap = 8.w;
              final tabWidth = (constraints.maxWidth - gap) / 2;

              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: AppDurations.normal,
                    curve: Curves.easeOutCubic,
                    left: currentTab == AuraNavTab.videos ? 0 : tabWidth + gap,
                    top: 0,
                    bottom: 0,
                    width: tabWidth,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AuraColors.primary.withValues(alpha: 0.16),
                        borderRadius: AppBorders.full,
                        border: Border.all(color: AuraColors.primary.withValues(alpha: 0.24)),
                        boxShadow: [
                          BoxShadow(
                            color: AuraColors.primary.withValues(alpha: 0.22),
                            blurRadius: 18.r,
                            spreadRadius: 1.r,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _NavigationItem(
                          icon: Icons.video_collection_rounded,
                          label: 'Videos',
                          isSelected: currentTab == AuraNavTab.videos,
                          onTap: () => onTabSelected(AuraNavTab.videos),
                        ),
                      ),
                      SizedBox(width: gap),
                      Expanded(
                        child: _NavigationItem(
                          icon: Icons.music_note_rounded,
                          label: 'Music',
                          isSelected: currentTab == AuraNavTab.music,
                          onTap: () => onTabSelected(AuraNavTab.music),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final color = isSelected ? AuraColors.primary : AuraColors.muted;

    return InkWell(
      onTap: onTap,
      borderRadius: AppBorders.full,
      child: AnimatedScale(
        duration: AppDurations.fast,
        scale: isSelected ? 1 : 0.96,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: isLandscape ? 14.r : 18.r),
            SizedBox(height: isLandscape ? 2.h : 3.h),
            CustomText(
              text: label,
              textColor: color,
              fontSize: isLandscape ? 7.sp : 9.sp,
              fontWeight: FontWeight.w800,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
