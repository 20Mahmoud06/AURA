import 'package:flutter/material.dart';

class MediaFolderItem {
  const MediaFolderItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}
