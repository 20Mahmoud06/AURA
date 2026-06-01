import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/core/theme/app_borders.dart';
import 'package:aura/database/models/video_item.dart';
import 'package:aura/database/models/music_item.dart';
import 'package:aura/shared/widgets/custom_text.dart';

class AppPropertiesDialog extends StatelessWidget {
  const AppPropertiesDialog({super.key, this.video, this.music});

  final VideoItem? video;
  final MusicItem? music;

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatDuration(int ms) {
    final sec = (ms / 1000).floor();
    final h = (sec / 3600).floor();
    final m = ((sec % 3600) / 60).floor();
    final s = sec % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    return '${m}m ${s}s';
  }

  String _formatExtension(String path) {
    final parts = path.split('.');
    if (parts.length > 1) return parts.last.toUpperCase();
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final title = video?.title ?? music?.title ?? 'Unknown';
    final path = video?.path ?? music?.path ?? 'Unknown';
    final sizeBytes = video?.sizeBytes ?? music?.sizeBytes ?? 0;
    final durationMs = video?.durationMs ?? music?.durationMs ?? 0;
    
    return Dialog(
      backgroundColor: AuraColors.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorders.lg,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CustomText(
                text: 'Properties',
                textColor: AuraColors.text,
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 20.h),
            _propRow(Icons.title_rounded, 'Name', title),
            if (music?.artist != null && music!.artist!.isNotEmpty && music!.artist != '<unknown>')
              _propRow(Icons.person_rounded, 'Artist', music!.artist!),
            if (music?.album != null && music!.album!.isNotEmpty && music!.album != '<unknown>')
              _propRow(Icons.album_rounded, 'Album', music!.album!),
            _propRow(Icons.folder_rounded, 'Location', path),
            _propRow(Icons.storage_rounded, 'Size', _formatSize(sizeBytes)),
            _propRow(Icons.audiotrack_rounded, 'Format', _formatExtension(path)),
            _propRow(Icons.timer_rounded, 'Duration', _formatDuration(durationMs)),
            SizedBox(height: 20.h),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: CustomText(
                  text: 'Close',
                  textColor: AuraColors.primary,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _propRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AuraColors.primary, size: 18.r),
          SizedBox(width: 12.w),
          SizedBox(
            width: 70.w,
            child: CustomText(
              text: label,
              textColor: AuraColors.muted,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: CustomText(
              text: value,
              textColor: AuraColors.text,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}