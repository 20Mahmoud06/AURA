import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura/core/constants/aura_colors.dart';

class AuraScreenBackground extends StatelessWidget {
  const AuraScreenBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF171B1F),
            AuraColors.neutral,
            Color(0xFF090D12),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90.h,
            left: -60.w,
            child: _Glow(
              color: AuraColors.primary.withValues(alpha: 0.18),
              size: 190.r,
            ),
          ),
          Positioned(
            top: 40.h,
            right: -80.w,
            child: _Glow(
              color: AuraColors.secondary.withValues(alpha: 0.14),
              size: 210.r,
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 90.r,
            spreadRadius: 45.r,
          ),
        ],
      ),
    );
  }
}
