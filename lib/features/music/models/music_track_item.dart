import 'package:flutter/material.dart';

class MusicTrackItem {
  const MusicTrackItem({
    required this.title,
    required this.artist,
    required this.icon,
    this.isFavorite = false,
  });

  final String title;
  final String artist;
  final IconData icon;
  final bool isFavorite;
}
