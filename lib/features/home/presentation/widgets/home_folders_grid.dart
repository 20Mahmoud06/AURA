import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/database/models/video_item.dart';
import 'package:aura/features/video/models/media_folder_item.dart';
import 'package:aura/features/video/widgets/media_folder_card.dart';

class FoldersGrid extends StatelessWidget {
  final Map<String, List<VideoItem>> folders;
  final ValueChanged<String>? onTapFolder;

  const FoldersGrid({super.key, required this.folders, this.onTapFolder});

  @override
  Widget build(BuildContext context) {
    if (folders.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12.w) / 2;
        final itemHeight = 126.h;

        return GridView.builder(
          itemCount: folders.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: itemWidth / itemHeight,
          ),
          itemBuilder: (context, index) {
            final entry = folders.entries.elementAt(index);
            final item = MediaFolderItem(
              title: entry.key,
              subtitle: '${entry.value.length} items',
              icon: Icons.folder_rounded,
              color: AuraColors.primary,
            );
            return MediaFolderCard(
              item: item,
              onTap: () => onTapFolder?.call(entry.key),
            );
          },
        );
      },
    );
  }
}
