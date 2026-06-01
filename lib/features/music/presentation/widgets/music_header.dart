import 'package:flutter/material.dart';

import 'package:aura/shared/widgets/aura_app_bar.dart';

class MusicHeader extends StatelessWidget {
  const MusicHeader({
    super.key,
    this.onSearchTap,
    this.isSearchActive = false,
  });

  final VoidCallback? onSearchTap;
  final bool isSearchActive;

  @override
  Widget build(BuildContext context) {
    return AuraAppBar(
      onSearchTap: onSearchTap,
      isSearchActive: isSearchActive,
    );
  }
}
