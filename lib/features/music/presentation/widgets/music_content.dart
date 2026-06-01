import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/core/bloc/media_bloc.dart';
import 'package:aura/core/utils/playlist_media_type.dart';
import 'package:aura/core/routing/app_routes.dart';
import 'package:aura/features/music/presentation/widgets/music_header.dart';
import 'package:aura/features/music/presentation/widgets/music_scan_card.dart';
import 'package:aura/features/music/presentation/widgets/music_track_tile.dart';
import 'package:aura/features/music/presentation/widgets/music_playlists_grid.dart';
import 'package:aura/features/music/presentation/widgets/music_create_playlist_tile.dart';
import 'package:aura/features/music/presentation/widgets/quick_shuffle_card.dart';
import 'package:aura/shared/widgets/section_header.dart';
import 'package:aura/shared/widgets/search_field.dart';
import 'package:aura/shared/widgets/app_empty_state.dart';
import 'package:aura/database/models/music_item.dart';

class MusicContent extends StatefulWidget {
  final void Function(Set<int>? selectedIds)? onSelectionChanged;
  final ValueNotifier<int>? clearSelectionSignal;

  const MusicContent({super.key, this.onSelectionChanged, this.clearSelectionSignal});

  @override
  State<MusicContent> createState() => _MusicContentState();
}

class _MusicContentState extends State<MusicContent> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isSelecting = false;
  final Set<int> _selectedIds = {};

  bool _isRecentSelecting = false;
  final Set<int> _selectedRecentIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSelectionChanged?.call(null);
    });
    widget.clearSelectionSignal?.addListener(_onClearSelection);
  }

  void _onClearSelection() {
    if (!_isSelecting && _selectedIds.isEmpty && !_isRecentSelecting && _selectedRecentIds.isEmpty) return;
    setState(() {
      _isSelecting = false;
      _selectedIds.clear();
      _isRecentSelecting = false;
      _selectedRecentIds.clear();
    });
    _notifySelection();
  }

  @override
  void didUpdateWidget(MusicContent oldWidget) {
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
      _isSelecting && _selectedIds.isNotEmpty ? Set.of(_selectedIds) : null,
    );
  }

  void _notifyRecentSelection() {
    widget.onSelectionChanged?.call(
      _isRecentSelecting && _selectedRecentIds.isNotEmpty ? Set.of(_selectedRecentIds) : null,
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
      if (!_isSelecting) _selectedIds.clear();
    });
    _notifySelection();
  }

  void _toggleItemSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelecting = false;
      } else {
        _selectedIds.add(id);
      }
    });
    _notifySelection();
  }

  void _onMusicLongPress(int id) {
    setState(() {
      _isSelecting = true;
      _selectedIds.add(id);
    });
    _notifySelection();
  }

  void _selectAllMusic(List<MusicItem> items) {
    setState(() {
      _selectedIds.addAll(items.map((m) => m.id));
    });
    _notifySelection();
  }

  void _clearMusicSelection() {
    setState(() {
      _isSelecting = false;
      _selectedIds.clear();
    });
    _notifySelection();
  }



  void _addToPlaylist(BuildContext context, MusicItem item) {
    final state = context.read<MediaBloc>().state;
    final playlists = state.playlists
        .where(
          (playlist) => isMusicPlaylist(
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
              MusicCreatePlaylistTile(
                onCreate: (name) {
                  context.read<MediaBloc>().add(
                        CreatePlaylistEvent(name, mediaType: playlistTypeMusic),
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
                    'No playlists yet. Create one to add this track.',
                    style: TextStyle(color: AuraColors.muted, fontSize: 12.sp),
                  ),
                ),
              ...playlists.map((p) => ListTile(
                leading: Icon(Icons.playlist_play_rounded, color: AuraColors.primary),
                title: Text(p.name, style: TextStyle(color: AuraColors.text, fontSize: 14.sp)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<MediaBloc>().add(AddMusicToPlaylistEvent(item, p));
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

  void _toggleRecentSelectionMode() {
    setState(() {
      _isRecentSelecting = !_isRecentSelecting;
      if (!_isRecentSelecting) _selectedRecentIds.clear();
    });
    _notifyRecentSelection();
  }

  void _toggleRecentItemSelection(int id) {
    setState(() {
      if (_selectedRecentIds.contains(id)) {
        _selectedRecentIds.remove(id);
        if (_selectedRecentIds.isEmpty) _isRecentSelecting = false;
      } else {
        _selectedRecentIds.add(id);
      }
    });
    _notifyRecentSelection();
  }

  void _onRecentLongPress(int id) {
    setState(() {
      _isRecentSelecting = true;
      _selectedRecentIds.add(id);
    });
    _notifyRecentSelection();
  }

  void _selectAllRecent(List<MusicItem> items) {
    setState(() {
      _selectedRecentIds.addAll(items.map((m) => m.id));
    });
    _notifyRecentSelection();
  }

  void _clearRecentSelection() {
    setState(() {
      _isRecentSelecting = false;
      _selectedRecentIds.clear();
    });
    _notifyRecentSelection();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaBloc, MediaState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
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

        final allMusic = List.of(state.musicItems);
        allMusic.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

        final filteredTracks = _searchQuery.isEmpty
            ? allMusic
            : allMusic.where((m) {
                final query = _searchQuery.toLowerCase();
                return m.title.toLowerCase().contains(query) ||
                    (m.artist ?? '').toLowerCase().contains(query) ||
                    (m.album ?? '').toLowerCase().contains(query);
              }).toList();
        final recentTracks = List.of(state.musicItems)
          ..where((m) => m.lastPlayedAt != null)
          ..sort((a, b) {
            final aDate = a.lastPlayedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = b.lastPlayedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });
        final topRecentTracks = recentTracks.take(5).toList();
        final hasRecentTracks = topRecentTracks.isNotEmpty && topRecentTracks.any((m) => m.lastPlayedAt != null);

        final isCompletelyEmpty = allMusic.isEmpty;

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
                  MusicHeader(onSearchTap: _toggleSearch, isSearchActive: _isSearching),
                SizedBox(height: 14.h),
                if (isCompletelyEmpty && !_isSearching)
                  Padding(
                    padding: EdgeInsets.only(top: 60.h),
                    child: AppEmptyState(
                      icon: Icons.music_note_rounded,
                      title: 'No Music Found',
                      subtitle: 'Add some tracks to your device and scan to see them here.',
                      actionLabel: 'Scan Device',
                      onAction: () => context.read<MediaBloc>().add(ScanDeviceEvent()),
                    ),
                  )
                else if (!_isSearching) ...[
                  MusicScanCard(onScanTap: () => context.read<MediaBloc>().add(ScanDeviceEvent())),
                  SizedBox(height: 26.h),
                  QuickShuffleCard(tracks: allMusic),
                  SizedBox(height: 28.h),
                  SectionHeader(
                    title: 'Playlists',
                    actionLabel: 'SEE ALL',
                    onActionTap: () => context.push(AppRoutes.musicPlaylists),
                  ),
                  SizedBox(height: 12.h),
                  MusicPlaylistsGrid(
                    playlists: state.playlists
                        .where(
                          (playlist) => isMusicPlaylist(
                            playlist,
                            musicPaths:
                                state.musicItems.map((music) => music.path).toSet(),
                            videoPaths:
                                state.videoItems.map((video) => video.path).toSet(),
                          ),
                        )
                        .toList(),
                  ),
                  if (hasRecentTracks) ...[
                    SizedBox(height: 30.h),
                    Row(
                      children: [
                        const Expanded(child: SectionHeader(title: 'Recent Played')),
                        if (!_isSearching)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isRecentSelecting)
                                GestureDetector(
                                  onTap: () => _selectAllRecent(topRecentTracks),
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
                              if (_isRecentSelecting) SizedBox(width: 8.w),
                              GestureDetector(
                                onTap: _isRecentSelecting ? _clearRecentSelection : _toggleRecentSelectionMode,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                  decoration: BoxDecoration(
                                    color: _isRecentSelecting
                                        ? AuraColors.primary.withValues(alpha: 0.2)
                                        : AuraColors.surfaceHigh.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Text(
                                    _isRecentSelecting ? 'Cancel' : 'Select',
                                    style: TextStyle(
                                      color: _isRecentSelecting ? AuraColors.primary : AuraColors.muted,
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
                    ...topRecentTracks.map(
                      (item) => Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: MusicTrackTile(
                          item: item,
                          showSelectionCheckbox: _isRecentSelecting,
                          isSelected: _selectedRecentIds.contains(item.id),
                          onSelect: (val) => _toggleRecentItemSelection(item.id),
                          onLongPress: _isRecentSelecting ? null : () => _onRecentLongPress(item.id),
                          onDelete: _isRecentSelecting ? null : () {
                            context.read<MediaBloc>().add(DeleteMusicEvent(item));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('"${item.title}" deleted')),
                            );
                          },
                          onRename: _isRecentSelecting ? null : (newName) => context.read<MediaBloc>().add(RenameMusicEvent(item, newName)),
                          onToggleFavorite: _isRecentSelecting ? null : () => context.read<MediaBloc>().add(ToggleFavoriteMusicEvent(item)),
                          onAddToPlaylist: _isRecentSelecting ? null : () => _addToPlaylist(context, item),
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 30.h),
                  Row(
                    children: [
                      const Expanded(child: SectionHeader(title: 'All Songs')),
                      if (!_isSearching)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isSelecting)
                              GestureDetector(
                                onTap: () => _selectAllMusic(allMusic),
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
                              onTap: _isSelecting ? _clearMusicSelection : _toggleSelectionMode,
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
                  ...allMusic.map(
                    (item) => Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: MusicTrackTile(
                        item: item,
                        showSelectionCheckbox: _isSelecting,
                        isSelected: _selectedIds.contains(item.id),
                        onSelect: (val) => _toggleItemSelection(item.id),
                        onLongPress: _isSelecting ? null : () => _onMusicLongPress(item.id),
                        onDelete: _isSelecting ? null : () {
                          context.read<MediaBloc>().add(DeleteMusicEvent(item));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('"${item.title}" deleted')),
                          );
                        },
                        onRename: _isSelecting ? null : (newName) => context.read<MediaBloc>().add(RenameMusicEvent(item, newName)),
                        onToggleFavorite: _isSelecting ? null : () => context.read<MediaBloc>().add(ToggleFavoriteMusicEvent(item)),
                        onAddToPlaylist: _isSelecting ? null : () => _addToPlaylist(context, item),
                      ),
                    ),
                  ),
                ],
                if (_isSearching && filteredTracks.isEmpty)
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
                  ),
                if (_isSearching && filteredTracks.isNotEmpty) ...[
                  SizedBox(height: 20.h),
                  SectionHeader(title: 'Search Results'),
                  SizedBox(height: 12.h),
                  ...filteredTracks.map(
                    (item) => Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: MusicTrackTile(
                        item: item,
                        showSelectionCheckbox: _isSelecting,
                        isSelected: _selectedIds.contains(item.id),
                        onSelect: (val) => _toggleItemSelection(item.id),
                        onDelete: _isSelecting ? null : () {
                          context.read<MediaBloc>().add(DeleteMusicEvent(item));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('"${item.title}" deleted')),
                          );
                        },
                        onRename: _isSelecting ? null : (newName) => context.read<MediaBloc>().add(RenameMusicEvent(item, newName)),
                        onToggleFavorite: _isSelecting ? null : () => context.read<MediaBloc>().add(ToggleFavoriteMusicEvent(item)),
                        onAddToPlaylist: _isSelecting ? null : () => _addToPlaylist(context, item),
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
        MusicHeader(onSearchTap: _toggleSearch, isSearchActive: true),
        SizedBox(height: 16.h),
        SearchField(
          controller: _searchController,
          hintText: 'Search music',
          autofocus: true,
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
        ),
      ],
    );
  }
}




