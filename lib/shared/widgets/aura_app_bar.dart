import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/core/routing/app_routes.dart';
import 'package:aura/shared/widgets/aura_heading.dart';
import 'package:aura/shared/widgets/aura_icon_button.dart';

class AuraAppBar extends StatelessWidget {
  const AuraAppBar({
    super.key,
    this.showBackButton = false,
    this.showSettingsButton = true,
    this.showSearchButton = true,
    this.isSearchActive = false,
    this.onBackPressed,
    this.onSearchTap,
  });

  final bool showBackButton;
  final bool showSettingsButton;
  final bool showSearchButton;
  final bool isSearchActive;
  final VoidCallback? onBackPressed;
  final VoidCallback? onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBackButton)
          AuraIconButton(
            icon: Icons.arrow_back_rounded,
            size: 34.r,
            backgroundColor: AuraColors.surfaceHigh.withValues(alpha: 0.72),
            iconColor: AuraColors.muted,
            onTap: onBackPressed ?? () => context.pop(),
          )
        else if (showSearchButton)
          AuraIconButton(
            icon: isSearchActive ? Icons.close_rounded : Icons.search_rounded,
            size: 34.r,
            backgroundColor: AuraColors.surfaceHigh,
            iconColor: AuraColors.muted,
            onTap: onSearchTap,
          )
        else
          SizedBox(width: 34.r),
        const Spacer(),
        const AuraHeading(),
        const Spacer(),
        if (showSettingsButton)
          AuraIconButton(
            icon: Icons.settings_rounded,
            size: 34.r,
            backgroundColor: AuraColors.surfaceHigh,
            iconColor: AuraColors.muted,
            onTap: () => context.push(AppRoutes.settings),
          )
        else
          SizedBox(width: 34.r),
      ],
    );
  }
}