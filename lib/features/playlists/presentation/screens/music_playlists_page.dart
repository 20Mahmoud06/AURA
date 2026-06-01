import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/core/bloc/media_bloc.dart';
import 'package:aura/core/routing/app_routes.dart';
import 'package:aura/core/utils/playlist_media_type.dart';
import 'package:aura/shared/widgets/app_empty_state.dart';
import 'package:aura/features/playlists/presentation/widgets/playlist_card.dart';

class MusicPlaylistsPage extends StatelessWidget {
  const MusicPlaylistsPage({super.key});

  void _createNewPlaylist(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuraColors.surfaceHigh,
        title: Text(
          'New Playlist',
          style: TextStyle(color: AuraColors.text, fontSize: 16.sp, fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: AuraColors.text),
          decoration: InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(color: AuraColors.muted),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AuraColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AuraColors.muted, fontSize: 12.sp, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              Navigator.pop(ctx);
              if (name.isNotEmpty) {
                context.read<MediaBloc>().add(
                      CreatePlaylistEvent(name, mediaType: playlistTypeMusic),
                    );
              }
            },
            child: Text('Create', style: TextStyle(color: AuraColors.primary, fontSize: 12.sp, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _openPlaylist(BuildContext context, String id, String title) {
    context.push(
      AppRoutes.playlistDetail.replaceFirst(':id', id),
      extra: {'title': title, 'type': 'music'},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 42.r,
                      height: 42.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AuraColors.surfaceHigh.withValues(alpha: 0.72),
                      ),
                      child: Icon(Icons.arrow_back_rounded, color: AuraColors.muted, size: 21.r),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Music Playlists',
                    style: TextStyle(
                      color: AuraColors.text,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _createNewPlaylist(context),
                    child: Container(
                      width: 42.r,
                      height: 42.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AuraColors.surfaceHigh.withValues(alpha: 0.72),
                      ),
                      child: Icon(Icons.add_rounded, color: AuraColors.primary, size: 24.r),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: BlocBuilder<MediaBloc, MediaState>(
                builder: (context, state) {
                  final playlists = state.playlists
                      .where(
                        (playlist) => isMusicPlaylist(
                          playlist,
                          musicPaths:
                              state.musicItems.map((music) => music.path).toSet(),
                          videoPaths:
                              state.videoItems.map((video) => video.path).toSet(),
                        ),
                      )
                      .toList();

                  if (playlists.isEmpty) {
                    return AppEmptyState(
                      icon: Icons.queue_music_rounded,
                      title: 'No Playlists Yet',
                      subtitle: 'Create a playlist to organize your music.',
                      actionLabel: 'Create Playlist',
                      onAction: () => _createNewPlaylist(context),
                    );
                  }

                  return GridView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12.w,
                      mainAxisSpacing: 12.h,
                    ),
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
                      final items = state.musicItems.where((m) => playlist.itemPaths.contains(m.path)).toList();
                      return PlaylistCard(
                        title: playlist.name,
                        subtitle: '${items.length} songs',
                        thumbnailPath: items.isNotEmpty ? items.first.artworkPath : null,
                        isFavorites: playlist.isFavorites,
                        onTap: () => _openPlaylist(context, playlist.id.toString(), playlist.name),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
