import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/shared/widgets/aura_app_bar.dart';
import 'package:aura/shared/widgets/app_empty_state.dart';
import 'package:aura/shared/widgets/custom_text.dart';
import 'package:aura/features/music/presentation/widgets/music_track_tile.dart';
import 'package:aura/features/video/widgets/video_list_tile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura/core/bloc/media_bloc.dart';
import 'package:aura/core/services/audio_player_service.dart';
import 'package:aura/database/models/music_item.dart';
import 'package:aura/database/models/playlist.dart';
import 'package:aura/database/models/video_item.dart';
import 'package:aura/core/routing/app_routes.dart';

class PlaylistDetailScreen extends StatefulWidget {
  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    required this.playlistTitle,
    this.type = 'music',
  });

  final String playlistId;
  final String playlistTitle;
  final String type;

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  late String _currentTitle;
  bool _isSelecting = false;
  final Set<String> _selectedPaths = {};
  bool get _isMusic => widget.type == 'music';

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.playlistTitle;
  }

  void _editPlaylistName() {
    final TextEditingController controller = TextEditingController(text: _currentTitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AuraColors.surfaceHigh,
        title: CustomText(
          text: 'Edit Playlist Name',
          textColor: AuraColors.text,
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: AuraColors.text),
          decoration: InputDecoration(
            hintText: 'Playlist Name',
            hintStyle: TextStyle(color: AuraColors.muted),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AuraColors.primary.withValues(alpha: 0.5))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AuraColors.primary)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: CustomText(text: 'Cancel', textColor: AuraColors.muted),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final id = int.tryParse(widget.playlistId);
                if (id != null) {
                  context.read<MediaBloc>().add(RenamePlaylistEvent(id, name));
                }
                setState(() => _currentTitle = name);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AuraColors.primary, foregroundColor: AuraColors.surface),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deletePlaylist() {
    final id = int.tryParse(widget.playlistId);
    if (id == null) {
      context.pop();
      return;
    }
    context.read<MediaBloc>().add(DeletePlaylistEvent(id));
    context.pop();
  }

  void _enterSelectionMode(String path) {
    setState(() {
      _isSelecting = true;
      _selectedPaths.add(path);
    });
  }

  void _cancelSelection() {
    setState(() {
      _isSelecting = false;
      _selectedPaths.clear();
    });
  }

  void _selectAll(Iterable<String> paths) {
    setState(() {
      _selectedPaths.addAll(paths);
    });
  }

  void _toggleSelected(String path) {
    setState(() {
      if (_selectedPaths.contains(path)) {
        _selectedPaths.remove(path);
        if (_selectedPaths.isEmpty) {
          _isSelecting = false;
        }
      } else {
        _selectedPaths.add(path);
      }
    });
  }

  void _deleteSelected(Playlist playlist) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuraColors.surfaceHigh,
        title: Text(
          'Remove ${_selectedPaths.length} item${_selectedPaths.length == 1 ? '' : 's'}?',
          style: TextStyle(color: AuraColors.text, fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'These items will be removed from this playlist.',
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
              _confirmDeleteFromPlaylist(playlist);
            },
            child: Text('Remove', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFromPlaylist(Playlist playlist) {
    final bloc = context.read<MediaBloc>();
    final state = bloc.state;
    for (final path in _selectedPaths.toList()) {
      if (_isMusic) {
        final item = state.musicItems.where((m) => m.path == path).firstOrNull;
        if (item != null) {
          bloc.add(RemoveMusicFromPlaylistEvent(item, playlist));
        }
      } else {
        final item = state.videoItems.where((v) => v.path == path).firstOrNull;
        if (item != null) {
          bloc.add(RemoveVideoFromPlaylistEvent(item, playlist));
        }
      }
    }
    _cancelSelection();
  }

  void _showAddToPlaylistPicker(Playlist currentPlaylist, List<String> selectedItemPaths) {
    final bloc = context.read<MediaBloc>();
    final state = bloc.state;
    final otherPlaylists = state.playlists
        .where((p) => p.id != currentPlaylist.id && !p.isFavorites)
        .toList();

    if (otherPlaylists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No other playlists available')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 12.h, left: 20.w),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: CustomText(
                    text: 'Add to Playlist',
                    textColor: AuraColors.text,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...otherPlaylists.map((playlist) => ListTile(
                leading: Icon(Icons.playlist_play_rounded, color: AuraColors.primary),
                title: CustomText(
                  text: playlist.name,
                  textColor: AuraColors.text,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  final items = selectedItemPaths
                      .map((path) => _isMusic
                          ? state.musicItems.where((m) => m.path == path).firstOrNull
                          : state.videoItems.where((v) => v.path == path).firstOrNull)
                      .whereType<dynamic>()
                      .toList();
                  if (_isMusic) {
                    bloc.add(AddMusicListToPlaylistEvent(List<MusicItem>.from(items), playlist));
                  } else {
                    bloc.add(AddVideoListToPlaylistEvent(List<VideoItem>.from(items), playlist));
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${items.length} item(s) added to "${playlist.name}"'),
                    ),
                  );
                  _cancelSelection();
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _playVideo(BuildContext context, dynamic video, {List<VideoItem>? playlist}) {
    context.read<MediaBloc>().add(PlayVideoEvent(video));
    final items = playlist ?? [video as VideoItem];
    final index = items.indexOf(video as VideoItem);
    context.push(AppRoutes.videoPlayer, extra: {
      'path': video.path,
      'items': items,
      'index': index >= 0 ? index : 0,
    });
  }

  void _playMusicFromPlaylist(MusicItem music, List<MusicItem> playlistTracks) {
    AudioPlayerService().playMusic(music, allItems: playlistTracks);
    context.read<MediaBloc>().add(PlayMusicEvent(music));
    context.push(AppRoutes.musicPlayer, extra: music);
  }

  Playlist? _playlistFromState(MediaState state) {
    final playlistId = int.tryParse(widget.playlistId);
    if (playlistId == null) return null;
    return state.playlists.where((p) => p.id == playlistId).firstOrNull;
  }

  void _showAddMusicPicker(Playlist playlist, List<MusicItem> allMusic) {
    final selectedPaths = <String>{};

    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.surface,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final availableMusic = allMusic
                .where((music) => !playlist.itemPaths.contains(music.path))
                .toList();
            final selectedMusic = availableMusic
                .where((music) => selectedPaths.contains(music.path))
                .toList();

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.82,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 8.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: CustomText(
                              text: 'Add Music',
                              textColor: AuraColors.text,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: selectedMusic.isEmpty
                                ? null
                                : () {
                                    context.read<MediaBloc>().add(
                                          AddMusicListToPlaylistEvent(
                                            selectedMusic,
                                            playlist,
                                          ),
                                        );
                                    Navigator.pop(sheetContext);
                                  },
                            child: Text(
                              selectedMusic.isEmpty
                                  ? 'Add'
                                  : 'Add (${selectedMusic.length})',
                              style: TextStyle(
                                color: selectedMusic.isEmpty
                                    ? AuraColors.muted
                                    : AuraColors.primary,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
                    if (availableMusic.isEmpty)
                      Expanded(
                        child: AppEmptyState(
                          icon: Icons.library_music_rounded,
                          title: 'No Songs To Add',
                          subtitle: allMusic.isEmpty
                              ? 'Scan your device to find music first.'
                              : 'All songs are already in this playlist.',
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          itemCount: availableMusic.length,
                          itemBuilder: (context, index) {
                            final music = availableMusic[index];
                            final isSelected = selectedPaths.contains(music.path);
                            return CheckboxListTile(
                              value: isSelected,
                              activeColor: AuraColors.primary,
                              checkColor: AuraColors.surface,
                              onChanged: (_) {
                                setSheetState(() {
                                  if (isSelected) {
                                    selectedPaths.remove(music.path);
                                  } else {
                                    selectedPaths.add(music.path);
                                  }
                                });
                              },
                              title: Text(
                                music.title.trim().isEmpty
                                    ? 'Unknown Title'
                                    : music.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AuraColors.text,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                (music.artist ?? '').trim().isEmpty
                                    ? 'Unknown Artist'
                                    : music.artist!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AuraColors.muted,
                                  fontSize: 11.sp,
                                ),
                              ),
                              secondary: Icon(
                                Icons.music_note_rounded,
                                color: isSelected
                                    ? AuraColors.primary
                                    : AuraColors.muted,
                                size: 22.r,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddVideoPicker(Playlist playlist, List<VideoItem> allVideos) {
    final selectedPaths = <String>{};

    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.surface,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final availableVideos = allVideos
                .where((video) => !playlist.itemPaths.contains(video.path))
                .toList();
            final selectedVideos = availableVideos
                .where((video) => selectedPaths.contains(video.path))
                .toList();

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.82,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 8.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: CustomText(
                              text: 'Add Videos',
                              textColor: AuraColors.text,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: selectedVideos.isEmpty
                                ? null
                                : () {
                                    context.read<MediaBloc>().add(
                                          AddVideoListToPlaylistEvent(
                                            selectedVideos,
                                            playlist,
                                          ),
                                        );
                                    Navigator.pop(sheetContext);
                                  },
                            child: Text(
                              selectedVideos.isEmpty
                                  ? 'Add'
                                  : 'Add (${selectedVideos.length})',
                              style: TextStyle(
                                color: selectedVideos.isEmpty
                                    ? AuraColors.muted
                                    : AuraColors.primary,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
                    if (availableVideos.isEmpty)
                      Expanded(
                        child: AppEmptyState(
                          icon: Icons.video_library_rounded,
                          title: 'No Videos To Add',
                          subtitle: allVideos.isEmpty
                              ? 'Scan your device to find videos first.'
                              : 'All videos are already in this playlist.',
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          itemCount: availableVideos.length,
                          itemBuilder: (context, index) {
                            final video = availableVideos[index];
                            final isSelected = selectedPaths.contains(video.path);
                            return CheckboxListTile(
                              value: isSelected,
                              activeColor: AuraColors.primary,
                              checkColor: AuraColors.surface,
                              onChanged: (_) {
                                setSheetState(() {
                                  if (isSelected) {
                                    selectedPaths.remove(video.path);
                                  } else {
                                    selectedPaths.add(video.path);
                                  }
                                });
                              },
                              title: Text(
                                video.title.trim().isEmpty
                                    ? 'Unknown Video'
                                    : video.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AuraColors.text,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                video.folderName ?? 'Video',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AuraColors.muted,
                                  fontSize: 11.sp,
                                ),
                              ),
                              secondary: Icon(
                                Icons.video_library_rounded,
                                color: isSelected
                                    ? AuraColors.primary
                                    : AuraColors.muted,
                                size: 22.r,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit_rounded, color: AuraColors.text),
                title: CustomText(text: 'Edit Name', textColor: AuraColors.text, fontSize: 16.sp),
                onTap: () {
                  Navigator.pop(context);
                  _editPlaylistName();
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_rounded, color: Colors.redAccent),
                title: CustomText(text: 'Delete Playlist', textColor: Colors.redAccent, fontSize: 16.sp),
                onTap: () {
                  Navigator.pop(context);
                  _deletePlaylist();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

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
            BlocBuilder<MediaBloc, MediaState>(
              builder: (context, state) {
                final playlist = _playlistFromState(state);
                final canAddMusic =
                    _isMusic && playlist != null && !playlist.isFavorites;
                final canAddVideo =
                    !_isMusic && playlist != null && !playlist.isFavorites;
                final musicTracks = playlist == null
                    ? <MusicItem>[]
                    : state.musicItems
                        .where((m) => playlist.itemPaths.contains(m.path))
                        .toList();
                final videoTracks = playlist == null
                    ? <VideoItem>[]
                    : state.videoItems
                        .where((v) => playlist.itemPaths.contains(v.path))
                        .toList();
                final hasPlayableItems =
                    _isMusic ? musicTracks.isNotEmpty : videoTracks.isNotEmpty;

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  child: _isSelecting
                      ? Row(
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                final allPaths = _isMusic
                                    ? musicTracks.map((e) => e.path).toList()
                                    : videoTracks.map((e) => e.path).toList();
                                if (_selectedPaths.length == allPaths.length) {
                                  _cancelSelection();
                                } else {
                                  _selectAll(allPaths);
                                }
                              },
                              icon: Icon(
                                _selectedPaths.length == (_isMusic ? musicTracks.length : videoTracks.length)
                                    ? Icons.deselect_rounded
                                    : Icons.select_all_rounded,
                                color: AuraColors.primary,
                                size: 20.r,
                              ),
                              label: CustomText(
                                text: _selectedPaths.length == (_isMusic ? musicTracks.length : videoTracks.length)
                                    ? 'Deselect All'
                                    : 'Select All',
                                textColor: AuraColors.primary,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            CustomText(
                              text: '${_selectedPaths.length}',
                              textColor: AuraColors.muted,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: _cancelSelection,
                              child: CustomText(
                                text: 'Cancel',
                                textColor: AuraColors.muted,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      : Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          text: _currentTitle,
                          textColor: AuraColors.text,
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasPlayableItems)
                        IconButton(
                          onPressed: () {
                            if (_isMusic) {
                              _playMusicFromPlaylist(
                                musicTracks.first,
                                musicTracks,
                              );
                            } else {
                              _playVideo(context, videoTracks.first, playlist: videoTracks);
                            }
                          },
                          icon: Icon(
                            Icons.play_arrow_rounded,
                            color: AuraColors.primary,
                            size: 30.r,
                          ),
                        ),
                      if (canAddMusic)
                        IconButton(
                          onPressed: () => _showAddMusicPicker(
                            playlist,
                            state.musicItems,
                          ),
                          icon: Icon(
                            Icons.playlist_add_rounded,
                            color: AuraColors.primary,
                            size: 28.r,
                          ),
                        ),
                      if (canAddVideo)
                        IconButton(
                          onPressed: () => _showAddVideoPicker(
                            playlist,
                            state.videoItems,
                          ),
                          icon: Icon(
                            Icons.playlist_add_rounded,
                            color: AuraColors.primary,
                            size: 28.r,
                          ),
                        ),
                      IconButton(
                        onPressed: _showOptions,
                        icon: Icon(Icons.more_vert_rounded, color: AuraColors.muted, size: 28.r),
                      ),
                    ],
                  ),
                );
              },
            ),
            Expanded(
              child: BlocBuilder<MediaBloc, MediaState>(
                builder: (context, state) {
                  final Playlist? playlist = _playlistFromState(state);

                  if (playlist == null) {
                    return AppEmptyState(
                      icon: Icons.music_off_rounded,
                      title: 'Playlist not found',
                      subtitle: 'This playlist may have been deleted.',
                    );
                  }

                  final musicTracks = state.musicItems
                      .where((m) => playlist.itemPaths.contains(m.path))
                      .toList();

                  final videoTracks = state.videoItems
                      .where((v) => playlist.itemPaths.contains(v.path))
                      .toList();

                  final tracks = _isMusic ? musicTracks : videoTracks;

                  if (tracks.isEmpty) {
                    return AppEmptyState(
                      icon: _isMusic
                          ? Icons.music_off_rounded
                          : Icons.video_library_rounded,
                      title: 'Playlist is Empty',
                      subtitle: _isMusic
                          ? 'Find your favorite songs and add them here.'
                          : 'Find your favorite videos and add them here.',
                      actionLabel: _isMusic && !playlist.isFavorites
                          ? 'Add Music'
                          : !_isMusic && !playlist.isFavorites
                              ? 'Add Videos'
                              : null,
                      onAction: _isMusic && !playlist.isFavorites
                          ? () => _showAddMusicPicker(playlist, state.musicItems)
                          : !_isMusic && !playlist.isFavorites
                              ? () => _showAddVideoPicker(
                                    playlist,
                                    state.videoItems,
                                  )
                          : null,
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.only(
                      left: 20.w,
                      right: 20.w,
                      top: 8.h,
                      bottom: _isSelecting ? 80.h : 8.h,
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: tracks.length,
                    itemBuilder: (context, index) {
                      if (_isMusic) {
                        final item = musicTracks[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 10.h),
                          child: MusicTrackTile(
                            item: item,
                            queueItems: musicTracks,
                            isSelected: _selectedPaths.contains(item.path),
                            showSelectionCheckbox: _isSelecting,
                            onSelect: (_) => _toggleSelected(item.path),
                            onLongPress: _isSelecting
                                ? null
                                : () => _enterSelectionMode(item.path),
                            onRemoveFromPlaylist: !playlist.isFavorites
                                ? () => context.read<MediaBloc>().add(
                                      RemoveMusicFromPlaylistEvent(
                                        item,
                                        playlist,
                                      ),
                                    )
                                : null,
                            onToggleFavorite: () => context.read<MediaBloc>().add(ToggleFavoriteMusicEvent(item)),
                          ),
                        );
                      } else {
                        final item = tracks[index] as dynamic;
                        return Padding(
                          padding: EdgeInsets.only(bottom: 10.h),
                          child: VideoListTile(
                            item: item,
                            isSelected: _selectedPaths.contains(item.path),
                            showSelectionCheckbox: _isSelecting,
                            onSelect: (_) => _toggleSelected(item.path),
                            onLongPress: _isSelecting
                                ? null
                                : () => _enterSelectionMode(item.path),
                            onTap: _isSelecting
                                ? null
                                : () => _playVideo(context, item, playlist: videoTracks),
                            onRemoveFromPlaylist: !playlist.isFavorites
                                ? () => context.read<MediaBloc>().add(
                                      RemoveVideoFromPlaylistEvent(
                                        item,
                                        playlist,
                                      ),
                                    )
                                : null,
                            onToggleFavorite: () => context.read<MediaBloc>().add(ToggleFavoriteVideoEvent(item)),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
            if (_isSelecting && _selectedPaths.isNotEmpty)
              Container(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, bottomInset + 12.h),
                decoration: BoxDecoration(
                  color: AuraColors.surfaceHigh,
                  border: Border(
                    top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final playlist = _playlistFromState(
                              context.read<MediaBloc>().state);
                          if (playlist != null) {
                            _showAddToPlaylistPicker(playlist, _selectedPaths.toList());
                          }
                        },
                        icon: Icon(Icons.playlist_add_rounded, color: AuraColors.primary, size: 20.r),
                        label: CustomText(
                          text: 'Add to Playlist',
                          textColor: AuraColors.primary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AuraColors.primary.withValues(alpha: 0.4)),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final playlist = _playlistFromState(
                              context.read<MediaBloc>().state);
                          if (playlist != null) {
                            _deleteSelected(playlist);
                          }
                        },
                        icon: Icon(Icons.delete_outline_rounded, color: AuraColors.surface, size: 20.r),
                        label: CustomText(
                          text: 'Remove (${_selectedPaths.length})',
                          textColor: AuraColors.surface,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
