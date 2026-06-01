import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/core/services/video_thumbnail_cache.dart';

/// Shows a video thumbnail from the gallery [assetId] via in-memory bytes (not Image.file).
class VideoThumbnailImage extends StatefulWidget {
  const VideoThumbnailImage({
    super.key,
    required this.assetId,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
  });

  final String? assetId;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;

  @override
  State<VideoThumbnailImage> createState() => _VideoThumbnailImageState();
}

class _VideoThumbnailImageState extends State<VideoThumbnailImage> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(VideoThumbnailImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetId != widget.assetId) {
      _bytes = null;
      _load();
    }
  }

  Future<void> _load() async {
    final bytes = await VideoThumbnailCache.instance.get(widget.assetId);
    if (!mounted) return;
    setState(() => _bytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes != null) {
      return Image.memory(
        _bytes!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
      );
    }

    return widget.placeholder ??
        Container(
          width: widget.width,
          height: widget.height,
          color: AuraColors.surfaceHigh,
          child: Icon(
            Icons.videocam_rounded,
            color: AuraColors.muted,
            size: (widget.height ?? 48) * 0.35,
          ),
        );
  }
}
