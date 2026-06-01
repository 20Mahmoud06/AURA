import 'package:flutter/material.dart';

class MusicPlaylistItem {
  const MusicPlaylistItem({
    required this.title,
    required this.subtitle,
    required this.colors,
  });

  final String title;
  final String subtitle;
  final List<Color> colors;
}
