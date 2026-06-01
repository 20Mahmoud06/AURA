import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/shared/widgets/custom_text.dart';
import 'package:aura/features/settings/presentation/widgets/settings_seconds_chip.dart';

class DoubleTapSecondsPicker extends StatelessWidget {
  const DoubleTapSecondsPicker({super.key, 
    required this.selectedSeconds,
    required this.onChanged,
  });

  final int selectedSeconds;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomText(
            text: 'Double Tap Amount',
            textColor: AuraColors.text,
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SecondsChip(
          label: '5s',
          isSelected: selectedSeconds == 5,
          onTap: () => onChanged(5),
        ),
        SizedBox(width: 8.w),
        SecondsChip(
          label: '10s',
          isSelected: selectedSeconds == 10,
          onTap: () => onChanged(10),
        ),
      ],
    );
  }
}
