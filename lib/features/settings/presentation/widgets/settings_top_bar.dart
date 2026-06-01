import 'package:flutter/material.dart';
import 'package:aura/shared/widgets/aura_app_bar.dart';

class SettingsTopBar extends StatelessWidget {
  const SettingsTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuraAppBar(
      showBackButton: true,
      showSettingsButton: false,
    );
  }
}
