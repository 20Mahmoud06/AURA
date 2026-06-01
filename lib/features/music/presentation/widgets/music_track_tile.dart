import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/core/theme/app_borders.dart';
import 'package:aura/database/models/music_item.dart';
import 'package:aura/shared/widgets/custom_text.dart';
import 'package:aura/shared/widgets/app_properties_dialog.dart';
import 'package:aura/core/bloc/media_bloc.dart';
import 'package:aura/core/routing/app_routes.dart';
import 'package:aura/core/services/audio_player_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:go_router/go_router.dart';

class MusicTrackTile extends StatelessWidget {
  final VoidCallback? onDelete;
  final VoidCallback? onLongPress;
  final ValueChanged<String>? onRename;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onRemoveFromPlaylist;
  final VoidCallback? onToggleFavorite;
  final MusicItem item;
  final List<MusicItem>? queueItems;
  final bool isSelected;
  final bool showSelectionCheckbox;
  final ValueChanged<bool>? onSelect;

  const MusicTrackTile({
    super.key,
    required this.item,
    this.onLongPress,
    this.onDelete,
    this.onRename,
    this.onAddToPlaylist,
    this.onRemoveFromPlaylist,
    this.onToggleFavorite,
    this.queueItems,
    this.isSelected = false,
    this.showSelectionCheckbox = false,
    this.onSelect,
  });

  String _formatDuration(int ms) {
    if (ms <= 0) return '00:00';
    final totalSec = (ms / 1000).floor();
    final h = (totalSec / 3600).floor();
    final m = ((totalSec % 3600) / 60).floor();
    final s = totalSec % 60;
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  bool _isSameQueue(List<MusicItem> currentQueue, List<MusicItem> nextQueue) {
    if (currentQueue.length != nextQueue.length) return false;
    for (var i = 0; i < currentQueue.length; i++) {
      if (currentQueue[i].id != nextQueue[i].id) return false;
    }
    return true;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  void _toggleFavoriteWithMessage(BuildContext context) {
    final wasFavorite = item.isFavorite;
    onToggleFavorite?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasFavorite
              ? '"${item.title}" removed from Favorites'
              : '"${item.title}" added to Favorites',
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: 8.h, bottom: 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _menuOption(
                ctx,
                icon: item.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                label: item.isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                onTap: () {
                  Navigator.pop(ctx);
                  _toggleFavoriteWithMessage(context);
                },
              ),
              _menuOption(
                ctx,
                icon: Icons.playlist_add_rounded,
                label: 'Add to Playlist',
                onTap: () {
                  Navigator.pop(ctx);
                  onAddToPlaylist?.call();
                },
              ),
              if (onRemoveFromPlaylist != null)
                _menuOption(
                  ctx,
                  icon: Icons.playlist_remove_rounded,
                  label: 'Remove from Playlist',
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    onRemoveFromPlaylist?.call();
                  },
                ),
              _menuOption(
                ctx,
                icon: Icons.edit_rounded,
                label: 'Rename',
                onTap: () {
                  Navigator.pop(ctx);
                  _showRenameDialog(context);
                },
              ),
              _menuOption(
                ctx,
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteConfirm(context);
                },
              ),
              _menuOption(
                ctx,
                icon: Icons.info_outline_rounded,
                label: 'Properties',
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (_) => AppPropertiesDialog(music: item),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: item.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuraColors.surfaceHigh,
        title: CustomText(
          text: 'Rename',
          textColor: AuraColors.text,
          fontSize: 15.sp,
          fontWeight: FontWeight.w800,
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: AuraColors.text),
          decoration: InputDecoration(
            hintText: 'Enter new name',
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
            child: CustomText(
              text: 'Cancel',
              textColor: AuraColors.muted,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onRename?.call(controller.text);
            },
            child: CustomText(
              text: 'Rename',
              textColor: AuraColors.primary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuraColors.surfaceHigh,
        title: CustomText(
          text: 'Delete Music',
          textColor: AuraColors.text,
          fontSize: 15.sp,
          fontWeight: FontWeight.w800,
        ),
        content: CustomText(
          text: 'Are you sure you want to delete "${item.title}"? This will also delete the file from your device.',
          textColor: AuraColors.muted,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: CustomText(
              text: 'Cancel',
              textColor: AuraColors.muted,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete?.call();
            },
            child: CustomText(
              text: 'Delete',
              textColor: Colors.redAccent,
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuOption(BuildContext context, {required IconData icon, required String label, VoidCallback? onTap, bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.redAccent : AuraColors.primary, size: 22.r),
      title: CustomText(
        text: label,
        textColor: isDestructive ? Colors.redAccent : AuraColors.text,
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
      ),
      onTap: onTap,
      dense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioService = AudioPlayerService();

    return StreamBuilder<MusicItem?>(
      stream: audioService.currentMusicStream,
      initialData: audioService.currentMusic,
      builder: (context, snapshot) {
        final isCurrent = snapshot.data?.id == item.id;

        return InkWell(
      borderRadius: AppBorders.lg,
      onLongPress: showSelectionCheckbox ? null : onLongPress,
      onTap: () {
        if (showSelectionCheckbox) {
          onSelect?.call(!isSelected);
          return;
        }
        final state = context.read<MediaBloc>().state;
        final currentMusic = audioService.currentMusic;
        final nextQueue = queueItems ?? state.musicItems;
        final queueChanged = !_isSameQueue(audioService.currentQueue, nextQueue);

        if (currentMusic == null || currentMusic.id != item.id || queueChanged) {
          audioService.playMusic(item, allItems: nextQueue);
          context.read<MediaBloc>().add(PlayMusicEvent(item));
        }
        context.push(AppRoutes.musicPlayer, extra: item);
      },
      child: Container(
        padding: EdgeInsets.all(10.r),
        decoration: BoxDecoration(
          color: isCurrent
              ? AuraColors.primary.withValues(alpha: 0.12)
              : AuraColors.surfaceHigh.withValues(alpha: 0.70),
          borderRadius: AppBorders.lg,
          border: Border.all(
            color: isCurrent
                ? AuraColors.primary.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.04),
          ),
        ),
        child: Row(
          children: [
            if (showSelectionCheckbox)
              Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: GestureDetector(
                  onTap: () => onSelect?.call(!isSelected),
                  child: Container(
                    width: 24.r,
                    height: 24.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AuraColors.primary : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? AuraColors.primary : AuraColors.muted,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Icon(Icons.check_rounded, color: AuraColors.surface, size: 16.r)
                        : null,
                  ),
                ),
              ),
            ClipRRect(
              borderRadius: AppBorders.md,
              child: SizedBox(
                width: 44.r,
                height: 44.r,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AuraColors.neutral.withValues(alpha: 0.72),
                    borderRadius: AppBorders.md,
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: item.audioQueryId != null
                          ? QueryArtworkWidget(
                              id: item.audioQueryId!,
                              type: ArtworkType.AUDIO,
                              artworkWidth: 44.r,
                              artworkHeight: 44.r,
                              artworkFit: BoxFit.cover,
                              nullArtworkWidget: Icon(Icons.music_note_rounded, color: AuraColors.primary, size: 22.r),
                            )
                          : Icon(Icons.music_note_rounded, color: AuraColors.primary, size: 22.r),
                      ),
                      Positioned(
                        right: 3.w,
                        bottom: 3.h,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            color: AuraColors.neutral.withValues(alpha: 0.85),
                            borderRadius: AppBorders.xs,
                          ),
                          child: CustomText(
                            text: _formatDuration(item.durationMs),
                            textColor: AuraColors.text,
                            fontSize: 6.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: item.title,
                    textColor: isCurrent ? AuraColors.primary : AuraColors.text,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  CustomText(
                    text: item.artist ?? 'Unknown Artist',
                    textColor: AuraColors.muted,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1.h),
                  CustomText(
                    text: _formatSize(item.sizeBytes),
                    textColor: AuraColors.muted.withValues(alpha: 0.6),
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w500,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!showSelectionCheckbox) ...[
              GestureDetector(
                onTap: () => _toggleFavoriteWithMessage(context),
                child: Padding(
                  padding: EdgeInsets.all(8.r),
                  child: Icon(
                    item.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: item.isFavorite ? AuraColors.primary : AuraColors.muted,
                    size: 18.r,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showContextMenu(context),
                child: Padding(
                  padding: EdgeInsets.all(8.r),
                  child: Icon(Icons.more_vert_rounded, color: AuraColors.muted, size: 18.r),
                ),
              ),
            ],
          ],
        ),
      ),
    );
      },
    );
  }
}
