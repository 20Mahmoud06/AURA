import 'package:flutter/material.dart';
import 'package:aura/features/home/presentation/screens/home_page.dart';
import 'package:aura/shared/widgets/aura_bottom_navigation.dart';

class MusicHomePage extends StatelessWidget {
  const MusicHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomePage(initialTab: AuraNavTab.music);
  }
}
