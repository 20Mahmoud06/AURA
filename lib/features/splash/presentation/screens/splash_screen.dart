import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/core/routing/app_routes.dart';
import 'package:aura/core/services/audio_player_service.dart';
import 'package:aura/shared/app_assets.dart';
import 'package:aura/shared/widgets/aura_screen_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _splashDuration = Duration(milliseconds: 2600);
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_splashDuration, _goToHome);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _goToHome() {
    if (!mounted) return;
    final hasPlayingSong = AudioPlayerService().currentMusic != null;
    if (hasPlayingSong) {
      context.go(AppRoutes.musicPlayer);
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraColors.neutral,
      body: Stack(
        children: [
          const Positioned.fill(child: AuraScreenBackground()),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 0.9,
                  colors: [
                    AuraColors.primary.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 38.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LogoImage()
                        .animate()
                        .fadeIn(duration: 650.ms, curve: Curves.easeOut)
                        .scale(
                          begin: const Offset(0.88, 0.88),
                          end: const Offset(1, 1),
                          duration: 850.ms,
                          curve: Curves.easeOutBack,
                        )
                        .then(delay: 180.ms)
                        .shimmer(
                          duration: 1100.ms,
                          color: AuraColors.primary.withValues(alpha: 0.35),
                        ),
                    SizedBox(height: 30.h),
                    const _LoadingLine()
                        .animate(onPlay: (controller) => controller.repeat(reverse: true))
                        .fadeIn(delay: 500.ms, duration: 420.ms)
                        .scale(
                          begin: const Offset(0.45, 1),
                          end: const Offset(1, 1),
                          duration: 900.ms,
                          curve: Curves.easeInOut,
                        ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280.r,
      height: 280.r,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40.r),
        boxShadow: [
          BoxShadow(
            color: AuraColors.primary.withValues(alpha: 0.20),
            blurRadius: 52.r,
            spreadRadius: 4.r,
          ),
          BoxShadow(
            color: AuraColors.tertiary.withValues(alpha: 0.16),
            blurRadius: 58.r,
            offset: Offset(18.w, 18.h),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        AppAssets.auraLogo,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _LoadingLine extends StatelessWidget {
  const _LoadingLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92.w,
      height: 4.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999.r),
        gradient: const LinearGradient(
          colors: [
            AuraColors.primary,
            AuraColors.secondary,
            AuraColors.tertiary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AuraColors.primary.withValues(alpha: 0.28),
            blurRadius: 18.r,
          ),
        ],
      ),
    );
  }
}
