import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/core/theme/app_borders.dart';
import 'package:aura/database/models/video_item.dart';
import 'package:aura/shared/widgets/aura_icon_button.dart';
import 'package:aura/shared/widgets/custom_text.dart';
import 'package:aura/shared/widgets/video_thumbnail_image.dart';

class RecentMediaCard extends StatelessWidget {
  const RecentMediaCard({
    super.key,
    required this.item,
  });

  final VideoItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 156.w,
      child: ClipRRect(
        borderRadius: AppBorders.lg,
        child: Stack(
          children: [
            Positioned.fill(
              child: VideoThumbnailImage(
                assetId: item.assetId,
                fit: BoxFit.cover,
                placeholder: _Artwork(
                  colors: [AuraColors.primary, AuraColors.surfaceHigh],
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AuraColors.neutral.withValues(alpha: 0.82),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12.w,
              right: 12.w,
              bottom: 12.h,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    text: item.title,
                    textColor: AuraColors.text,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  CustomText(
                    text: '${(item.durationMs / 60000).floor()}:${((item.durationMs % 60000) / 1000).floor().toString().padLeft(2, '0')}',
                    textColor: AuraColors.text.withValues(alpha: 0.74),
                    fontSize: 10.sp,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  ClipRRect(
                    borderRadius: AppBorders.full,
                    child: LinearProgressIndicator(
                      value: 0.0, // Replace with actual progress if available later
                      minHeight: 3.h,
                      color: AuraColors.primary,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 10.w,
              bottom: 38.h,
              child: AuraIconButton(
                icon: Icons.play_arrow_rounded,
                size: 34.r,
                backgroundColor: AuraColors.primary.withValues(alpha: 0.76),
                iconColor: AuraColors.neutral,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: CustomPaint(
        painter: _ArtworkPainter(colors.first.withValues(alpha: 0.78)),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ArtworkPainter extends CustomPainter {
  const _ArtworkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 7; i++) {
      final y = size.height * (0.24 + i * 0.08);
      final path = Path()
        ..moveTo(size.width * 0.12, y)
        ..cubicTo(
          size.width * 0.34,
          y - 26,
          size.width * 0.52,
          y + 28,
          size.width * 0.86,
          y - 4,
        );
      canvas.drawPath(path, paint..color = color.withValues(alpha: 0.18 + i * 0.08));
    }
  }

  @override
  bool shouldRepaint(covariant _ArtworkPainter oldDelegate) => oldDelegate.color != color;
}
