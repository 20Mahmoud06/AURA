import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/core/theme/app_borders.dart';
import 'package:aura/database/models/music_item.dart';
import 'package:aura/shared/widgets/custom_text.dart';

class MusicPlaylistCard extends StatelessWidget {
  const MusicPlaylistCard({
    super.key,
    required this.items,
  });

  final List<MusicItem> items;

  @override
  Widget build(BuildContext context) {
    final favoritesCount = items.length;
    return SizedBox(
      width: 110.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 90.h,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: AppBorders.lg,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AuraColors.surfaceHigh,
                      AuraColors.neutral,
                      AuraColors.surface,
                    ],
                  ),
                ),
                child: CustomPaint(
                  painter: const _WavePainter(),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          CustomText(
            text: 'Favorites',
            textColor: AuraColors.text,
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),
          CustomText(
            text: '$favoritesCount tracks',
            textColor: AuraColors.muted,
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 10; i++) {
      final paint = Paint()
        ..color = _waveColors[i % _waveColors.length].withValues(alpha: 0.42)
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final y = size.height * (0.30 + i * 0.052);
      final path = Path()
        ..moveTo(size.width * -0.10, y)
        ..cubicTo(
          size.width * 0.24,
          y - 34.h,
          size.width * 0.56,
          y + 24.h,
          size.width * 1.10,
          y - 18.h,
        );

      canvas.drawPath(path, paint);
    }
  }

  static const List<Color> _waveColors = [
    AuraColors.primary,
    AuraColors.tertiary,
    AuraColors.secondary,
  ];

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => false;
}
