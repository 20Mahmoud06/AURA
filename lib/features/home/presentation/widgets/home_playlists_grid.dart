import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/core/bloc/media_bloc.dart';
import 'package:aura/core/routing/app_routes.dart';
import 'package:aura/database/models/playlist.dart';
import 'package:aura/shared/widgets/video_thumbnail_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlaylistsGrid extends StatelessWidget {
  const PlaylistsGrid({super.key, required this.playlists});

  final List<Playlist> playlists;

  @override
  Widget build(BuildContext context) {
    if (playlists.isEmpty) {
      return SizedBox(
        height: 130.h,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 140.w,
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: AuraColors.surfaceHigh,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Center(
              child: Text(
                'No playlists yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AuraColors.muted,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 130.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: playlists.length,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          final videoItemsInPlaylist = context.read<MediaBloc>().state.videoItems
              .where((v) => playlist.itemPaths.contains(v.path))
              .toList();
          final coverVideo = videoItemsInPlaylist.isNotEmpty ? videoItemsInPlaylist.first : null;
          final coverAssetId = coverVideo?.assetId;
          return GestureDetector(
            onTap: () => context.push(
              AppRoutes.playlistDetail.replaceFirst(':id', playlist.id.toString()),
              extra: {'title': playlist.name, 'type': 'video'},
            ),
            child: Container(
              width: 140.w,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AuraColors.surfaceHigh,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.r),
                      child: SizedBox.expand(
                        child: VideoThumbnailImage(
                          assetId: coverAssetId,
                          fit: BoxFit.cover,
                          placeholder: Container(
                            color: AuraColors.surfaceHigh.withValues(alpha: 0.6),
                            child: Icon(
                              playlist.isFavorites
                                  ? Icons.favorite_rounded
                                  : Icons.playlist_play_rounded,
                              color: playlist.isFavorites
                                  ? AuraColors.primary
                                  : AuraColors.muted,
                              size: 18.r,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    playlist.name,
                    style: TextStyle(color: AuraColors.text, fontSize: 12.sp, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${videoItemsInPlaylist.length} items',
                    style: TextStyle(color: AuraColors.muted, fontSize: 10.sp, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
