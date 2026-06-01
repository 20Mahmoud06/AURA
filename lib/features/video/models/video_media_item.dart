import 'package:flutter/material.dart';

class VideoMediaItem {
  const VideoMediaItem({
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.colors,
    this.progress = 0,
  });

  final String title;
  final String subtitle;
  final String duration;
  final List<Color> colors;
  final double progress;
}
