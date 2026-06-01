import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:aura/core/constants/aura_colors.dart';

import 'package:on_audio_query/on_audio_query.dart';

class PlayerAlbumArt extends StatefulWidget {
  const PlayerAlbumArt({super.key, this.artworkPath, this.audioQueryId, this.isPlaying = false});

  final String? artworkPath;
  final int? audioQueryId;
  final bool isPlaying;

  @override
  State<PlayerAlbumArt> createState() => _PlayerAlbumArtState();
}

class _PlayerAlbumArtState extends State<PlayerAlbumArt> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
    if (widget.isPlaying) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant PlayerAlbumArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240.r,
      height: 240.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AuraColors.surfaceHigh,
        boxShadow: [
          BoxShadow(
            color: AuraColors.primary.withValues(alpha: 0.2),
            blurRadius: 48.r,
            spreadRadius: 8.r,
          ),
          BoxShadow(
            color: AuraColors.primary.withValues(alpha: 0.4),
            blurRadius: 18.r,
            spreadRadius: 2.r,
          ),
        ],
        border: Border.all(
          color: AuraColors.primary.withValues(alpha: 0.5),
          width: 2.r,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotationTransition(
            turns: _rotationController,
            child: ClipOval(
              child: _buildArtwork(),
            ),
          ),
          // Center Hole (like a vinyl)
          Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AuraColors.surface,
              border: Border.all(
                color: AuraColors.primary.withValues(alpha: 0.2),
                width: 1.r,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtwork() {
    final path = widget.artworkPath;
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      return Image.file(
        File(path),
        width: 240.r,
        height: 240.r,
        fit: BoxFit.cover,
      );
    }

    if (widget.audioQueryId != null) {
      return QueryArtworkWidget(
        id: widget.audioQueryId!,
        type: ArtworkType.AUDIO,
        artworkWidth: 240.r,
        artworkHeight: 240.r,
        artworkFit: BoxFit.cover,
        nullArtworkWidget: _buildPlaceholder(),
        keepOldArtwork: true,
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 240.r,
      height: 240.r,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AuraColors.surfaceHigh,
            AuraColors.primary.withValues(alpha: 0.14),
          ],
        ),
      ),
      child: Icon(
        Icons.music_note_rounded,
        size: 74.r,
        color: AuraColors.primary.withValues(alpha: 0.3),
      ),
    );
  }
}
