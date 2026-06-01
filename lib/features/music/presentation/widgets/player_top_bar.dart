import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/core/bloc/media_bloc.dart';
import 'package:aura/core/services/audio_player_service.dart';
import 'package:aura/core/utils/playlist_media_type.dart';
import 'package:aura/database/models/music_item.dart';
import 'package:aura/shared/widgets/app_properties_dialog.dart';

class PlayerTopBar extends StatelessWidget {
  const PlayerTopBar({super.key});

  void _showSpeedSelector(BuildContext context) {
    final audioService = AudioPlayerService();
    final currentSpeed = audioService.currentSpeed;
    const speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.symmetric(vertical: 24.h),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Playback Speed',
                style: TextStyle(
                  color: AuraColors.text,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              ...speeds.map((speed) => ListTile(
                leading: Icon(
                  speed == currentSpeed ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: speed == currentSpeed ? AuraColors.primary : AuraColors.muted,
                ),
                title: Text(
                  '${speed}x',
                  style: TextStyle(
                    color: speed == currentSpeed ? AuraColors.primary : AuraColors.text,
                    fontWeight: speed == currentSpeed ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  audioService.setSpeed(speed);
                  Navigator.pop(ctx);
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, MusicItem music) {
    final state = context.read<MediaBloc>().state;
    final playlists = state.playlists
        .where(
          (playlist) =>
              !playlist.isFavorites &&
              isMusicPlaylist(
                playlist,
                musicPaths: state.musicItems.map((music) => music.path).toSet(),
                videoPaths: state.videoItems.map((video) => video.path).toSet(),
              ),
        )
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) => SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 20.w),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add to Playlist',
              style: TextStyle(
                color: AuraColors.text,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            if (playlists.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 32.h),
                child: Text(
                  'No playlists yet.\nCreate one from the Playlists tab.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AuraColors.muted, fontSize: 13.sp),
                ),
              )
            else
              ...playlists.map((playlist) => ListTile(
                leading: Icon(Icons.playlist_play_rounded, color: AuraColors.primary),
                title: Text(
                  playlist.name,
                  style: TextStyle(color: AuraColors.text),
                ),
                subtitle: Text(
                  '${playlist.itemPaths.length} tracks',
                  style: TextStyle(color: AuraColors.muted, fontSize: 12.sp),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  final alreadyInPlaylist = playlist.itemPaths.contains(music.path);
                  if (!alreadyInPlaylist) {
                    context.read<MediaBloc>().add(AddMusicToPlaylistEvent(music, playlist));
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        alreadyInPlaylist
                            ? '"${music.title}" already in ${playlist.name}'
                            : '"${music.title}" added to ${playlist.name}',
                      ),
                    ),
                  );
                },
              )),
          ],
        ),
      ),
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    final audioService = AudioPlayerService();
    final music = audioService.currentMusic;
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.symmetric(vertical: 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<double>(
              stream: audioService.speedStream,
              builder: (context, snapshot) {
                final speed = snapshot.data ?? 1.0;
                return ListTile(
                  leading: Icon(Icons.speed_rounded, color: AuraColors.primary),
                  title: Text('Playback Speed', style: TextStyle(color: AuraColors.text)),
                  subtitle: Text('${speed}x', style: TextStyle(color: AuraColors.muted, fontSize: 12.sp)),
                  trailing: Icon(Icons.chevron_right_rounded, color: AuraColors.muted),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showSpeedSelector(context);
                  },
                );
              },
            ),
            if (music != null)
              ListTile(
                leading: Icon(Icons.playlist_add_rounded, color: AuraColors.primary),
                title: Text('Add to Playlist', style: TextStyle(color: AuraColors.text)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddToPlaylistDialog(context, music);
                },
              ),
            if (music != null)
              ListTile(
                leading: Icon(Icons.info_outline_rounded, color: AuraColors.primary),
                title: Text('Properties', style: TextStyle(color: AuraColors.text)),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (_) => AppPropertiesDialog(music: music),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AuraColors.surfaceHigh.withValues(alpha: 0.5),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AuraColors.muted,
                size: 20.r,
              ),
            ),
          ),
          Column(
            children: [
              Text(
                'NOW PLAYING',
                style: TextStyle(
                  color: AuraColors.primary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'A U R A',
                style: TextStyle(
                  color: AuraColors.muted,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AuraColors.surfaceHigh.withValues(alpha: 0.5),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: IconButton(
              onPressed: () => _showMoreMenu(context),
              icon: Icon(
                Icons.more_vert_rounded,
                color: AuraColors.muted,
                size: 20.r,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
