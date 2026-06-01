import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:aura/core/bloc/media_bloc.dart';
import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/database/models/video_item.dart';
import 'package:aura/core/utils/playlist_media_type.dart';
import 'package:aura/features/home/presentation/widgets/home_header.dart';
import 'package:aura/features/home/presentation/widgets/home_storage_summary.dart';
import 'package:aura/features/home/presentation/widgets/home_folders_grid.dart';
import 'package:aura/features/home/presentation/widgets/home_playlists_grid.dart';
import 'package:aura/features/video/widgets/video_list_tile.dart';
import 'package:aura/core/routing/app_routes.dart';
import 'package:aura/shared/widgets/section_header.dart';
import 'package:aura/shared/widgets/search_field.dart';
import 'package:aura/shared/widgets/app_empty_state.dart';

import 'home_create_playlist_tile.dart';

class HomeContent extends StatefulWidget {
  final void Function(Set<int>? selectedIds)? onSelectionChanged;
  final ValueNotifier<int>? clearSelectionSignal;

  const HomeContent({super.key, this.onSelectionChanged, this.clearSelectionSignal});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isSelecting = false;
  final Set<int> _selectedVideoIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSelectionChanged?.call(null);
    });
    widget.clearSelectionSignal?.addListener(_onClearSelection);
  }

  void _onClearSelection() {
    if (!_isSelecting && _selectedVideoIds.isEmpty) return;
    setState(() {
      _isSelecting = false;
      _selectedVideoIds.clear();
    });
    _notifySelection();
  }

  @override
  void didUpdateWidget(HomeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clearSelectionSignal != widget.clearSelectionSignal) {
      oldWidget.clearSelectionSignal?.removeListener(_onClearSelection);
      widget.clearSelectionSignal?.addListener(_onClearSelection);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _notifySelection() {
    widget.onSelectionChanged?.call(
      _isSelecting && _selectedVideoIds.isNotEmpty ? Set.of(_selectedVideoIds) : null,
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelecting = !_isSelecting;
      if (!_isSelecting) _selectedVideoIds.clear();
    });
    _notifySelection();
  }

  void _toggleVideoSelection(int id) {
    setState(() {
      if (_selectedVideoIds.contains(id)) {
        _selectedVideoIds.remove(id);
        if (_selectedVideoIds.isEmpty) _isSelecting = false;
      } else {
        _selectedVideoIds.add(id);
      }
    });
    _notifySelection();
  }

  void _onVideoLongPress(int id) {
    setState(() {
      _isSelecting = true;
      _selectedVideoIds.add(id);
    });
    _notifySelection();
  }

  void _selectAllVideos(List<VideoItem> videos) {
    setState(() {
      _selectedVideoIds.addAll(videos.map((v) => v.id));
    });
    _notifySelection();
  }

  void _clearVideoSelection() {
    setState(() {
      _isSelecting = false;
      _selectedVideoIds.clear();
    });
    _notifySelection();
  }



  void _playVideo(BuildContext context, VideoItem video, {List<VideoItem>? playlist}) {
    context.read<MediaBloc>().add(PlayVideoEvent(video));
    final items = playlist ?? [video];
    final index = items.indexOf(video);
    context.push(AppRoutes.videoPlayer, extra: {
      'path': video.path,
      'items': items,
      'index': index >= 0 ? index : 0,
    });
  }

  void _renameVideo(BuildContext context, VideoItem video, String newName) {
    if (newName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid name.')),
      );
      return;
    }
    context.read<MediaBloc>().add(RenameVideoEvent(video, newName));
  }

  void _deleteVideo(BuildContext context, VideoItem video) {
    context.read<MediaBloc>().add(DeleteVideoEvent(video));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${video.title}" deleted')),
    );
  }

  void _addToPlaylist(BuildContext context, VideoItem video) {
    final state = context.read<MediaBloc>().state;
    final playlists = state.playlists
        .where(
          (playlist) => isVideoPlaylist(
            playlist,
            musicPaths: state.musicItems.map((music) => music.path).toSet(),
            videoPaths: state.videoItems.map((video) => video.path).toSet(),
          ),
        )
        .toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.surfaceHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add to Playlist', style: TextStyle(color: AuraColors.text, fontSize: 16.sp, fontWeight: FontWeight.w800)),
              SizedBox(height: 12.h),
              CreatePlaylistTile(
                onCreate: (name) {
                  context.read<MediaBloc>().add(
                        CreatePlaylistEvent(name, mediaType: playlistTypeVideo),
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Playlist "$name" created')),
                  );
                },
              ),
              if (playlists.isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: Text(
                    'No playlists yet. Create one to add this video.',
                    style: TextStyle(color: AuraColors.muted, fontSize: 12.sp),
                  ),
                ),
              ...playlists.map((p) => ListTile(
                leading: Icon(Icons.playlist_play_rounded, color: AuraColors.primary),
                title: Text(p.name, style: TextStyle(color: AuraColors.text, fontSize: 14.sp)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<MediaBloc>().add(AddVideoToPlaylistEvent(video, p));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added to ${p.name}')),
                  );
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleFavorite(BuildContext context, VideoItem video) {
    context.read<MediaBloc>().add(ToggleFavoriteVideoEvent(video));
  }

  Map<String, List<VideoItem>> _groupVideosByFolder(List<VideoItem> videos) {
    final map = <String, List<VideoItem>>{};
    for (final v in videos) {
      final dir = Directory(v.path).parent.path;
      final folderName = dir.split(Platform.pathSeparator).last;
      map.putIfAbsent(folderName, () => []).add(v);
    }
    return map;
  }

  void _openFolder(BuildContext context, String folderName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.surfaceHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18.r))),
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: BlocBuilder<MediaBloc, MediaState>(
          builder: (context, state) {
            final folderVideos = state.videoItems.where((v) {
              final dir = Directory(v.path).parent.path;
              final name = dir.split(Platform.pathSeparator).last;
              return name == folderName;
            }).toList();

            return Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.folder_rounded, color: AuraColors.primary),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          folderName,
                          style: TextStyle(color: AuraColors.text, fontSize: 16.sp, fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  if (folderVideos.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.h),
                      child: Center(
                        child: Text(
                          'No videos in this folder',
                          style: TextStyle(color: AuraColors.muted, fontSize: 12.sp, fontWeight: FontWeight.w600),
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: folderVideos.length,
                        itemBuilder: (context, index) {
                          final item = folderVideos[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: 10.h),
                            child: VideoListTile(
                              item: item,
                              onTap: () {
                                Navigator.pop(ctx);
                                _playVideo(context, item, playlist: folderVideos);
                              },
                              onDelete: () => _deleteVideo(context, item),
                              onRename: (newName) => _renameVideo(context, item, newName),
                              onAddToPlaylist: () => _addToPlaylist(context, item),
                              onToggleFavorite: () => _toggleFavorite(context, item),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaBloc, MediaState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AuraColors.primary));
        }

        if (!state.isPermissionGranted) {
          return Center(
            child: AppEmptyState(
              icon: Icons.folder_off_rounded,
              title: 'Permission Required',
              subtitle: state.permissionNeedsSettings
                  ? 'Allow music and video access in Settings, then return to AURA.'
                  : 'Allow access to music and videos on this device.',
              actionLabel: state.permissionNeedsSettings
                  ? 'Open Settings'
                  : 'Grant Permission',
              onAction: () => context.read<MediaBloc>().add(
                    RequestPermissionsEvent(),
                  ),
            ),
          );
        }

        final allVideos = state.videoItems;
        final filteredVideos = _searchQuery.isEmpty
            ? allVideos
            : allVideos.where((v) => v.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

        final isCompletelyEmpty = allVideos.isEmpty;
        final folders = _groupVideosByFolder(allVideos);

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 104.h),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    if (_isSearching)
                      _buildSearchBar()
                    else
                      HomeHeader(onSearchTap: _toggleSearch, isSearchActive: false),
                    SizedBox(height: 16.h),
                    if (isCompletelyEmpty && !_isSearching)
                      Padding(
                        padding: EdgeInsets.only(top: 60.h),
                        child: AppEmptyState(
                          icon: Icons.video_library_rounded,
                          title: 'No Videos Found',
                          subtitle: 'Tap "Scan Device" to find videos on your device.',
                          actionLabel: 'Scan Device',
                          onAction: () => context.read<MediaBloc>().add(ScanDeviceEvent()),
                        ),
                      )
                     else if (!_isSearching) ...[
                       SizedBox(height: 14.h),
                       HomeStorageSummary(
                         onScanTap: () => context.read<MediaBloc>().add(ScanDeviceEvent()),
                       ),
                        SizedBox(height: 28.h),
                        SectionHeader(
                          title: 'Playlists',
                          actionLabel: 'SEE ALL',
                          onActionTap: () => context.push(AppRoutes.videoPlaylists),
                        ),
                        SizedBox(height: 12.h),
                        PlaylistsGrid(
                          playlists: state.playlists
                              .where(
                                (playlist) => isVideoPlaylist(
                                  playlist,
                                  musicPaths: state.musicItems
                                      .map((music) => music.path)
                                      .toSet(),
                                  videoPaths: state.videoItems
                                      .map((video) => video.path)
                                      .toSet(),
                                ),
                              )
                              .toList(),
                        ),
                       SizedBox(height: 24.h),
                       SectionHeader(title: 'Folders'),
                       SizedBox(height: 12.h),
                        FoldersGrid(
                         folders: folders,
                         onTapFolder: (name) => _openFolder(context, name),
                       ),
                        SizedBox(height: 28.h),
                        Row(
                          children: [
                            const Expanded(child: SectionHeader(title: 'All Videos')),
                            if (!_isSearching)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isSelecting)
                                    GestureDetector(
                                      onTap: () => _selectAllVideos(allVideos),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                        decoration: BoxDecoration(
                                          color: AuraColors.surfaceHigh.withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(20.r),
                                        ),
                                        child: Text(
                                          'Select All',
                                          style: TextStyle(
                                            color: AuraColors.muted,
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (_isSelecting) SizedBox(width: 8.w),
                                  GestureDetector(
                                    onTap: _isSelecting ? _clearVideoSelection : _toggleSelectionMode,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                      decoration: BoxDecoration(
                                        color: _isSelecting
                                            ? AuraColors.primary.withValues(alpha: 0.2)
                                            : AuraColors.surfaceHigh.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(20.r),
                                      ),
                                      child: Text(
                                        _isSelecting ? 'Cancel' : 'Select',
                                        style: TextStyle(
                                          color: _isSelecting ? AuraColors.primary : AuraColors.muted,
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        ...allVideos.map(
                           (item) => Padding(
                             padding: EdgeInsets.only(bottom: 10.h),
                             child: VideoListTile(
                               item: item,
                               showSelectionCheckbox: _isSelecting,
                               isSelected: _selectedVideoIds.contains(item.id),
                               onSelect: (val) => _toggleVideoSelection(item.id),
                               onLongPress: _isSelecting ? null : () => _onVideoLongPress(item.id),
                               onTap: _isSelecting ? null : () => _playVideo(context, item, playlist: allVideos),
                               onDelete: _isSelecting ? null : () => _deleteVideo(context, item),
                               onRename: _isSelecting ? null : (newName) => _renameVideo(context, item, newName),
                               onAddToPlaylist: _isSelecting ? null : () => _addToPlaylist(context, item),
                               onToggleFavorite: _isSelecting ? null : () => _toggleFavorite(context, item),
                             ),
                           ),
                         ),
                     ],
                    if (_isSearching) ...[
                      SizedBox(height: 20.h),
                      SectionHeader(title: 'Search Results'),
                      SizedBox(height: 12.h),
                      if (filteredVideos.isEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 40.h),
                          child: Center(
                            child: Text(
                              'No results found for "$_searchQuery"',
                              style: TextStyle(
                                color: AuraColors.muted,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      else
                        ...filteredVideos.map(
                          (item) => Padding(
                            padding: EdgeInsets.only(bottom: 10.h),
                            child: VideoListTile(
                              item: item,
                              onTap: () => _playVideo(context, item, playlist: filteredVideos),
                              onDelete: () => _deleteVideo(context, item),
                              onRename: (newName) => _renameVideo(context, item, newName),
                              onAddToPlaylist: () => _addToPlaylist(context, item),
                              onToggleFavorite: () => _toggleFavorite(context, item),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Column(
      children: [
        HomeHeader(onSearchTap: _toggleSearch, isSearchActive: true),
        SizedBox(height: 16.h),
        SearchField(
          controller: _searchController,
          hintText: 'Search Videos',
          autofocus: true,
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
        ),
      ],
    );
  }
}


