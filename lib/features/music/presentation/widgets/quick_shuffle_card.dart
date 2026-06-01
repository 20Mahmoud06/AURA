import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/core/theme/app_borders.dart';
import 'package:aura/database/models/music_item.dart';
import 'package:aura/shared/widgets/aura_icon_button.dart';
import 'package:aura/shared/widgets/custom_text.dart';
import 'package:aura/core/services/audio_player_service.dart';
import 'package:aura/core/bloc/media_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:aura/core/routing/app_routes.dart';

class QuickShuffleCard extends StatelessWidget {
  const QuickShuffleCard({super.key, required this.tracks});

  final List<MusicItem> tracks;

  @override
  Widget build(BuildContext context) {
    final hasTracks = tracks.isNotEmpty;
    return Container(
      height: 188.h,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AuraColors.surface,
        borderRadius: AppBorders.xl,
        border: Border.all(color: AuraColors.primary.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AuraColors.primary.withValues(alpha: 0.30),
            blurRadius: 28.r,
            spreadRadius: 1.r,
          ),
          BoxShadow(
            color: AuraColors.secondary.withValues(alpha: 0.22),
            blurRadius: 32.r,
            offset: Offset(0, 12.h),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AuraColors.primary.withValues(alpha: 0.28),
            AuraColors.surface,
            AuraColors.secondary.withValues(alpha: 0.22),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomText(
            text: 'INSTANT MIX',
            textColor: AuraColors.primary,
            fontSize: 8.sp,
            fontWeight: FontWeight.w900,
            maxLines: 1,
          ),
          SizedBox(height: 6.h),
          CustomText(
            text: 'Quick Shuffle',
            textColor: AuraColors.text,
            fontSize: 22.sp,
            fontWeight: FontWeight.w900,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8.h),
          CustomText(
            text: 'Dive into a hyper-personalized blend of your top tracks and cinematic soundscapes.',
            textColor: AuraColors.text.withValues(alpha: 0.74),
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 10.h),
          AuraIconButton(
            icon: Icons.play_arrow_rounded,
            size: 44.r,
            backgroundColor: hasTracks
                ? AuraColors.primary
                : AuraColors.primary.withValues(alpha: 0.4),
            iconColor: AuraColors.neutral,
            onTap: () {
              if (!hasTracks) return;
              final randomTrack = tracks[Random().nextInt(tracks.length)];
              final audioService = AudioPlayerService();
              audioService.setShuffleModeEnabled(true);
              audioService.playMusic(randomTrack, allItems: tracks);
              context.read<MediaBloc>().add(PlayMusicEvent(randomTrack));
              context.push(AppRoutes.musicPlayer, extra: randomTrack);
            },
          ),
        ],
      ),
    );
  }
}
