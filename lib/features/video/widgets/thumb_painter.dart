import 'package:flutter/material.dart';

class ThumbPainter extends CustomPainter {
  const ThumbPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 5; i++) {
      final path = Path()
        ..moveTo(-10, size.height * (0.28 + i * 0.13))
        ..quadraticBezierTo(
          size.width * 0.42,
          size.height * (0.04 + i * 0.1),
          size.width + 8,
          size.height * (0.2 + i * 0.12),
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ThumbPainter oldDelegate) => oldDelegate.color != color;
}
