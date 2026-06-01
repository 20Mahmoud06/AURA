import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aura/core/bloc/media_bloc.dart';
import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/core/services/audio_player_service.dart';
import 'package:aura/core/utils/playlist_media_type.dart';
import 'package:aura/database/models/music_item.dart';
import 'package:aura/database/models/video_item.dart';
import 'package:aura/features/home/presentation/widgets/widgets.dart';
import 'package:aura/features/music/presentation/widgets/mini_player.dart';
import 'package:aura/features/music/presentation/widgets/music_content.dart';
import 'package:aura/features/music/presentation/widgets/music_create_playlist_tile.dart';
import 'package:aura/shared/widgets/aura_bottom_navigation.dart';
import 'package:aura/shared/widgets/aura_screen_background.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.initialTab = AuraNavTab.videos,
  });

  final AuraNavTab initialTab;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PageController _pageController;
  late AuraNavTab _currentTab;
  final _clearSelectionSignal = ValueNotifier<int>(0);

  Set<int>? _videoSelectedIds;
  Set<int>? _musicSelectedIds;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    _pageController = PageController(initialPage: _pageIndexForTab(_currentTab));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleTabSelected(AuraNavTab tab) {
    if (tab == _currentTab) return;

    setState(() => _currentTab = tab);
    _pageController.animateToPage(
      _pageIndexForTab(tab),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  void _handlePageChanged(int index) {
    final tab = _tabForPageIndex(index);
    if (tab == _currentTab) return;
    setState(() => _currentTab = tab);
  }

  int _pageIndexForTab(AuraNavTab tab) {
    return switch (tab) {
      AuraNavTab.videos => 0,
      AuraNavTab.music => 1,
    };
  }

  AuraNavTab _tabForPageIndex(int index) {
    return switch (index) {
      0 => AuraNavTab.videos,
      _ => AuraNavTab.music,
    };
  }

  bool get _showSelectionBar {
    final ids = _currentTab == AuraNavTab.videos ? _videoSelectedIds : _musicSelectedIds;
    return ids != null && ids.isNotEmpty;
  }

  Set<int> get _currentSelectedIds {
    return _currentTab == AuraNavTab.videos
        ? _videoSelectedIds ?? {}
        : _musicSelectedIds ?? {};
  }

  void _deleteSelected() {
    final ids = _currentSelectedIds;
    if (ids.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuraColors.surfaceHigh,
        title: Text(
          'Delete ${ids.length} item${ids.length == 1 ? '' : 's'}?',
          style: TextStyle(color: AuraColors.text, fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will permanently delete the selected items from your device.',
          style: TextStyle(color: AuraColors.muted, fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AuraColors.muted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmDelete(ids);
            },
            child: Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Set<int> ids) {
    final state = context.read<MediaBloc>().state;
    if (_currentTab == AuraNavTab.videos) {
      final items = state.videoItems.where((v) => ids.contains(v.id)).toList();
      if (items.isNotEmpty) {
        context.read<MediaBloc>().add(DeleteVideoListEvent(items));
      }
      setState(() {
        _videoSelectedIds = null;
        _clearSelectionSignal.value++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${items.length} video(s) deleted')),
      );
    } else {
      final items = state.musicItems.where((m) => ids.contains(m.id)).toList();
      if (items.isNotEmpty) {
        context.read<MediaBloc>().add(DeleteMusicListEvent(items));
      }
      setState(() {
        _musicSelectedIds = null;
        _clearSelectionSignal.value++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${items.length} track(s) deleted')),
      );
    }
  }

  void _addSelectedToPlaylist() {
    final ids = _currentSelectedIds;
    if (ids.isEmpty) return;
    final state = context.read<MediaBloc>().state;

    if (_currentTab == AuraNavTab.videos) {
      final items = state.videoItems.where((v) => ids.contains(v.id)).toList();
      if (items.isEmpty) return;
      _showAddToPlaylistSheet(items, isVideos: true);
    } else {
      final items = state.musicItems.where((m) => ids.contains(m.id)).toList();
      if (items.isEmpty) return;
      _showAddToPlaylistSheet(items, isVideos: false);
    }
  }

  void _showAddToPlaylistSheet(List<Object> items, {required bool isVideos}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.surfaceHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final currentState = context.read<MediaBloc>().state;
            final playlists = currentState.playlists
                .where((p) => !p.isFavorites && (isVideos
                    ? isVideoPlaylist(p,
                        musicPaths: currentState.musicItems.map((m) => m.path).toSet(),
                        videoPaths: currentState.videoItems.map((v) => v.path).toSet())
                    : isMusicPlaylist(p,
                        musicPaths: currentState.musicItems.map((m) => m.path).toSet(),
                        videoPaths: currentState.videoItems.map((v) => v.path).toSet())))
                .toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add ${items.length} ${isVideos ? 'video(s)' : 'track(s)'} to Playlist',
                      style: TextStyle(color: AuraColors.text, fontSize: 16.sp, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 12.h),
                    isVideos
                        ? CreatePlaylistTile(
                            onCreate: (name) {
                              context.read<MediaBloc>().add(CreatePlaylistEvent(name, mediaType: playlistTypeVideo));
                              context.read<MediaBloc>().stream.firstWhere(
                                (s) => s.playlists.any((p) => p.name == name && !p.isFavorites),
                              ).then((_) {
                                final s = context.read<MediaBloc>().state;
                                final pl = s.playlists.firstWhere((p) => p.name == name && !p.isFavorites);
                                context.read<MediaBloc>().add(AddVideoListToPlaylistEvent(items.cast<VideoItem>(), pl));
                              });
                              Navigator.pop(ctx);
                              setState(() {
                                _videoSelectedIds = null;
                                _clearSelectionSignal.value++;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Added ${items.length} video(s) to "$name"')),
                              );
                            },
                          )
                        : MusicCreatePlaylistTile(
                            onCreate: (name) {
                              context.read<MediaBloc>().add(CreatePlaylistEvent(name, mediaType: playlistTypeMusic));
                              context.read<MediaBloc>().stream.firstWhere(
                                (s) => s.playlists.any((p) => p.name == name && !p.isFavorites),
                              ).then((_) {
                                final s = context.read<MediaBloc>().state;
                                final pl = s.playlists.firstWhere((p) => p.name == name && !p.isFavorites);
                                context.read<MediaBloc>().add(AddMusicListToPlaylistEvent(items.cast<MusicItem>(), pl));
                              });
                              Navigator.pop(ctx);
                              setState(() {
                                _musicSelectedIds = null;
                                _clearSelectionSignal.value++;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Added ${items.length} track(s) to "$name"')),
                              );
                            },
                          ),
                    SizedBox(height: 8.h),
                    if (playlists.isEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 6.h),
                        child: Text('No playlists yet.',
                            style: TextStyle(color: AuraColors.muted, fontSize: 12.sp)),
                      ),
                    ...playlists.map((p) => ListTile(
                      leading: Icon(Icons.playlist_play_rounded, color: AuraColors.primary),
                      title: Text(p.name, style: TextStyle(color: AuraColors.text, fontSize: 14.sp)),
                      onTap: () {
                        if (isVideos) {
                          context.read<MediaBloc>().add(AddVideoListToPlaylistEvent(items.cast<VideoItem>(), p));
                          setState(() {
                            _videoSelectedIds = null;
                            _clearSelectionSignal.value++;
                          });
                        } else {
                          context.read<MediaBloc>().add(AddMusicListToPlaylistEvent(items.cast<MusicItem>(), p));
                          setState(() {
                            _musicSelectedIds = null;
                            _clearSelectionSignal.value++;
                          });
                        }
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added ${items.length} ${isVideos ? 'video(s)' : 'track(s)'} to ${p.name}')),
                        );
                      },
                    )),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final navBottom = isLandscape ? 8.h : 16.h;
    final navHeight = isLandscape ? 48.h : 64.h;
    final gap = 8.h;
    final selIds = _currentSelectedIds;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: AuraColors.neutral,
        body: Stack(
          children: [
            const Positioned.fill(child: AuraScreenBackground()),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 520.w),
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _handlePageChanged,
                    children: [
                      HomeContent(
                        onSelectionChanged: (ids) => setState(() => _videoSelectedIds = ids),
                        clearSelectionSignal: _clearSelectionSignal,
                      ),
                      MusicContent(
                        onSelectionChanged: (ids) => setState(() => _musicSelectedIds = ids),
                        clearSelectionSignal: _clearSelectionSignal,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_currentTab == AuraNavTab.music)
              Positioned(
                left: isLandscape ? 40.w : 24.w,
                right: isLandscape ? 40.w : 24.w,
                bottom: navBottom + bottomInset + navHeight + gap,
                child: const MiniPlayer(),
              ),
            AuraBottomNavigation(
              currentTab: _currentTab,
              onTabSelected: _handleTabSelected,
            ),
            if (_showSelectionBar)
              StreamBuilder<MusicItem?>(
                stream: AudioPlayerService().currentMusicStream,
                initialData: AudioPlayerService().currentMusic,
                builder: (context, snapshot) {
                  final hasTrack = snapshot.data != null;
                  final selectionBottom = _currentTab == AuraNavTab.music && hasTrack
                      ? navBottom + bottomInset + navHeight + gap + 56.h + gap
                      : navBottom + bottomInset + navHeight + gap;

                  return Positioned(
                    left: isLandscape ? 40.w : 24.w,
                    right: isLandscape ? 40.w : 24.w,
                    bottom: selectionBottom,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AuraColors.surface.withValues(alpha: 0.95),
                          ],
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${selIds.length}',
                                style: TextStyle(
                                  color: AuraColors.text,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _addSelectedToPlaylist,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                                decoration: BoxDecoration(
                                  color: AuraColors.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.playlist_add_rounded, color: AuraColors.primary, size: 18.r),
                                    SizedBox(width: 6.w),
                                    Text(
                                      'Add to Playlist',
                                      style: TextStyle(
                                        color: AuraColors.primary,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            GestureDetector(
                              onTap: _deleteSelected,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18.r),
                                    SizedBox(width: 6.w),
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
