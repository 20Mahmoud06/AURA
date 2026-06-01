import 'package:flutter/material.dart';

import 'package:aura/shared/widgets/aura_app_bar.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
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