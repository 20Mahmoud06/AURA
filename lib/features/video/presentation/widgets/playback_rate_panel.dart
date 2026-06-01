import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:aura/core/constants/aura_colors.dart';

class PlaybackRatePanel extends StatelessWidget {
  const PlaybackRatePanel({super.key, 
    required this.value,
    required this.onSelect,
    required this.onSliderChange,
    this.compact = false,
  });

  final double value;
  final ValueChanged<double> onSelect;
  final ValueChanged<double> onSliderChange;
  final bool compact;

  static const List<double> _rates = [
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    2.0,
  ];

  int _sliderIndex() {
    var closest = 0;
    var minDiff = double.infinity;
    for (var i = 0; i < _rates.length; i++) {
      final diff = (_rates[i] - value).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = i;
      }
    }
    return closest;
  }

  String _formatRate(double rate) {
    if (rate % 1 == 0) return rate.toStringAsFixed(0);
    return rate.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 200 : 180.w,
      padding: EdgeInsets.all(compact ? 10 : 12.r),
      decoration: BoxDecoration(
        color: AuraColors.surfaceHigh.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(compact ? 14 : 16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Speed',
                style: TextStyle(
                  color: AuraColors.text,
                  fontSize: compact ? 12 : 11.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${_formatRate(value)}x',
                style: TextStyle(
                  color: AuraColors.primary,
                  fontSize: compact ? 12 : 11.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 6 : 8.h),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              activeTrackColor: AuraColors.primary,
              inactiveTrackColor: AuraColors.surfaceHigh.withValues(alpha: 0.5),
              thumbColor: AuraColors.primary,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            ),
            child: Slider(
              value: _sliderIndex().toDouble(),
              min: 0,
              max: (_rates.length - 1).toDouble(),
              divisions: _rates.length - 1,
              onChanged: (v) => onSliderChange(_rates[v.round()]),
            ),
          ),
          SizedBox(height: compact ? 4 : 6.h),
          Wrap(
            spacing: compact ? 4 : 6.w,
            runSpacing: compact ? 4 : 6.h,
            children: _rates.map((rate) {
              final isActive = (rate - value).abs() < 0.01;
              return GestureDetector(
                onTap: () => onSelect(rate),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 8 : 8.w,
                    vertical: compact ? 4 : 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AuraColors.primary.withValues(alpha: 0.18)
                        : AuraColors.surfaceHigh.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: isActive
                          ? AuraColors.primary
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Text(
                    '${_formatRate(rate)}x',
                    style: TextStyle(
                      color: isActive ? AuraColors.primary : AuraColors.text,
                      fontSize: compact ? 10 : 9.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
