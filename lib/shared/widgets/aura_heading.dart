import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuraHeading extends StatelessWidget {
  const AuraHeading({
    super.key,
    this.compact = true,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/AURA_heading.png',
      height: compact ? 34.h : 18.h,
      fit: BoxFit.contain,
    );
  }
}
