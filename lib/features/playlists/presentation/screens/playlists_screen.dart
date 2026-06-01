import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/core/bloc/media_bloc.dart';
import 'package:aura/shared/widgets/aura_app_bar.dart';
import 'package:aura/shared/widgets/app_empty_state.dart';

import '../widgets/playlist_card.dart';


class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  void _createNewPlaylist() {
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
                context.read<MediaBloc>().add(CreatePlaylistEvent(name));
              }
            },
            child: Text('Create', style: TextStyle(color: AuraColors.primary, fontSize: 12.sp, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _openPlaylist(String id, String title) {
    context.push('/playlists/$id', extra: title);
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
              child: AuraAppBar(
                showBackButton: true,
                showSearchButton: false,
                showSettingsButton: false,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Playlists',
                    style: TextStyle(
                      color: AuraColors.text,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: _createNewPlaylist,
                    icon: Icon(Icons.add_rounded, color: AuraColors.primary, size: 28.r),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<MediaBloc, MediaState>(
                builder: (context, state) {
                  if (state.playlists.isEmpty) {
                    return AppEmptyState(
                      icon: Icons.queue_music_rounded,
                      title: 'No Playlists Yet',
                      subtitle: 'Create a playlist to organize your music.',
                      actionLabel: 'Create Playlist',
                      onAction: _createNewPlaylist,
                    );
                  }

                  return GridView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 16.w,
                      mainAxisSpacing: 16.h,
                    ),
                    itemCount: state.playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = state.playlists[index];
                      final subtitle = '${playlist.itemPaths.length} tracks';
                      return PlaylistCard(
                        title: playlist.name,
                        subtitle: subtitle,
                        imageUrl: playlist.coverImagePath,
                        onTap: () => _openPlaylist(playlist.id.toString(), playlist.name),
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
