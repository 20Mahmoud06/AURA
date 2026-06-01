import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/core/theme/app_borders.dart';
import 'package:aura/database/models/video_item.dart';
import 'package:aura/shared/widgets/custom_text.dart';
import 'package:aura/features/video/widgets/thumb_painter.dart';
import 'package:aura/shared/widgets/app_properties_dialog.dart';
import 'package:aura/shared/widgets/video_thumbnail_image.dart';

class VideoListTile extends StatelessWidget {
  const VideoListTile({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
    this.onDelete,
    this.onRename,
    this.onAddToPlaylist,
    this.onRemoveFromPlaylist,
    this.onToggleFavorite,
    this.isSelected = false,
    this.showSelectionCheckbox = false,
    this.onSelect,
  });

  final VideoItem item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onRename;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onRemoveFromPlaylist;
  final VoidCallback? onToggleFavorite;
  final bool isSelected;
  final bool showSelectionCheckbox;
  final ValueChanged<bool>? onSelect;

  String _formatDuration(int ms) {
    if (ms <= 0) return '00:00';
    final totalSec = (ms / 1000).floor();
    final h = (totalSec / 3600).floor();
    final m = ((totalSec % 3600) / 60).floor();
    final s = totalSec % 60;
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '$m:${s.toString().padLeft(2, '0')}';
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
                    builder: (_) => AppPropertiesDialog(video: item),
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
          text: 'Delete Video',
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
    return GestureDetector(
      onTap: showSelectionCheckbox ? () => onSelect?.call(!isSelected) : onTap,
      onLongPress: showSelectionCheckbox ? null : (onLongPress ?? () => _showContextMenu(context)),
      child: Container(
        padding: EdgeInsets.all(10.r),
        decoration: BoxDecoration(
          color: AuraColors.surfaceHigh,
          borderRadius: AppBorders.lg,
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
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
                width: 82.w,
                height: 52.h,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AuraColors.primary, AuraColors.surfaceHigh],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: VideoThumbnailImage(
                          assetId: item.assetId,
                          fit: BoxFit.cover,
                          placeholder: CustomPaint(
                            painter: ThumbPainter(AuraColors.surfaceHigh),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 5.w,
                        bottom: 4.h,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AuraColors.neutral.withValues(alpha: 0.8),
                            borderRadius: AppBorders.xs,
                          ),
                          child: CustomText(
                            text: _formatDuration(item.durationMs),
                            textColor: AuraColors.text,
                            fontSize: 7.sp,
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
                    textColor: AuraColors.text,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 5.h),
                  CustomText(
                    text: _formatSize(item.sizeBytes),
                    textColor: AuraColors.muted,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
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
                    size: 20.r,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showContextMenu(context),
                child: Padding(
                  padding: EdgeInsets.all(8.r),
                  child: Icon(Icons.more_vert_rounded, color: AuraColors.muted, size: 20.r),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


