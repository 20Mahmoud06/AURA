import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/shared/widgets/custom_text.dart';
import 'package:aura/shared/widgets/video_thumbnail_image.dart';

class PlaylistCard extends StatelessWidget {
  const PlaylistCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.thumbnailPath,
    this.videoAssetId,
    this.isFavorites = false,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? thumbnailPath;
  final String? videoAssetId;
  final bool isFavorites;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AuraColors.surfaceHigh.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
                child: videoAssetId != null
                    ? VideoThumbnailImage(
                        assetId: videoAssetId,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: _buildPlaceholder(),
                      )
                    : imageUrl != null && imageUrl!.isNotEmpty
                        ? Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isFavorites) ...[
                        Icon(Icons.favorite_rounded, color: AuraColors.primary, size: 14.r),
                        SizedBox(width: 4.w),
                      ],
                      Expanded(
                        child: CustomText(
                          text: title,
                          textColor: AuraColors.text,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  CustomText(
                    text: subtitle,
                    textColor: AuraColors.muted,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AuraColors.surfaceHigh,
      child: Center(
        child: Icon(
          isFavorites ? Icons.favorite_rounded : Icons.playlist_play_rounded,
          size: 36.r,
          color: isFavorites ? AuraColors.primary : AuraColors.muted,
        ),
      ),
    );
  }
}
