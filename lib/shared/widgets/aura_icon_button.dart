import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/aura_colors.dart';
import '../../core/theme/app_borders.dart';

class AuraIconButton extends StatelessWidget {
  const AuraIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.backgroundColor,
    this.iconColor,
    this.size,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final dimension = size ?? 36.r;

    return SizedBox.square(
      dimension: dimension,
      child: Material(
        color: backgroundColor ?? AuraColors.surfaceHigh,
        borderRadius: AppBorders.full,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppBorders.full,
          child: Icon(
            icon,
            color: iconColor ?? AuraColors.text,
            size: dimension * 0.48,
          ),
        ),
      ),
    );
  }
}
