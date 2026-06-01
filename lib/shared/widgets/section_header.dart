import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/aura_colors.dart';
import 'custom_text.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
    this.trailing,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomText(
            text: title,
            textColor: AuraColors.text,
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) trailing!,
        if (actionLabel != null)
          TextButton(
            onPressed: onActionTap,
            child: CustomText(
              text: actionLabel!,
              textColor: AuraColors.text.withValues(alpha: 0.75),
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}
