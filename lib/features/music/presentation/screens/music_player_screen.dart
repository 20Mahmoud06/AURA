import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aura/shared/widgets/aura_screen_background.dart';
import 'package:aura/core/bloc/media_bloc.dart';
import 'package:aura/core/services/audio_player_service.dart';
import 'package:aura/database/models/music_item.dart';

import '../widgets/player_top_bar.dart';
import '../widgets/player_album_art.dart';
import '../widgets/player_track_info.dart';
import '../widgets/player_progress_bar.dart';
import '../widgets/player_controls.dart';
import '../widgets/player_visualizer.dart';

class MusicPlayerScreen extends StatefulWidget {
  final MusicItem? initialTrack;

  const MusicPlayerScreen({super.key, this.initialTrack});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  final _audioService = AudioPlayerService();
  MusicItem? _activeTrack;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _activeTrack = widget.initialTrack ?? _audioService.currentMusic;
    _audioService.positionStream.listen((pos) {
      if (mounted) setState(() => _currentPosition = pos);
    });
    _audioService.durationStream.listen((dur) {
      if (mounted) setState(() => _totalDuration = dur ?? Duration.zero);
    });
    _audioService.playingStream.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });
    _audioService.currentMusicStream.listen((track) {
      if (mounted) setState(() => _activeTrack = track);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AuraScreenBackground(),
          SafeArea(
            child: BlocBuilder<MediaBloc, MediaState>(
              builder: (context, state) {
                final track = _activeTrack ?? state.currentMusic ?? (state.musicItems.isNotEmpty ? state.musicItems.first : null);
                if (track != null && !_initialized) {
                  _initialized = true;
                  _activeTrack ??= track;
                }

                final title = (track?.title ?? '').trim().isEmpty ? 'Unknown Title' : track!.title;
                final artist = (track?.artist ?? '').trim().isEmpty ? 'Unknown Artist' : track!.artist!;
                final totalMs = _totalDuration.inMilliseconds > 0
                    ? _totalDuration
                    : Duration(milliseconds: track?.durationMs ?? 0);
                final progress = totalMs.inMilliseconds == 0
                    ? 0.0
                    : _currentPosition.inMilliseconds / totalMs.inMilliseconds;

                return SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: 24.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PlayerTopBar(),
                      SizedBox(height: 28.h),
                      PlayerAlbumArt(
                        artworkPath: track?.artworkPath,
                        audioQueryId: track?.audioQueryId,
                        isPlaying: _isPlaying,
                      ),
                      SizedBox(height: 36.h),
                      PlayerTrackInfo(
                        title: title,
                        artist: artist,
                        isFavorite: track?.isFavorite ?? false,
                        onToggleFavorite: track == null
                            ? null
                            : () => context.read<MediaBloc>().add(
                                  ToggleFavoriteMusicEvent(track),
                                ),
                      ),
                      SizedBox(height: 28.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32.w),
                        child: PlayerProgressBar(
                          currentPosition: _formatDuration(_currentPosition),
                          totalDuration: _formatDuration(totalMs),
                          progress: progress.clamp(0.0, 1.0),
                          rawTotalDuration: totalMs,
                        ),
                      ),
                      SizedBox(height: 28.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: PlayerControls(isPlaying: _isPlaying),
                      ),
                      SizedBox(height: 26.h),
                      PlayerVisualizer(isPlaying: _isPlaying),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
