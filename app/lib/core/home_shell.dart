import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';

/// Bottom navigation: My week · Circles · Friends · Profile.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.wb_twilight_outlined),
            selectedIcon: const Icon(Icons.wb_twilight_rounded),
            label: l10n.navMyWeek,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bubble_chart_outlined),
            selectedIcon: const Icon(Icons.bubble_chart_rounded),
            label: l10n.navCircles,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_alt_outlined),
            selectedIcon: const Icon(Icons.people_alt_rounded),
            label: l10n.navFriends,
          ),
          NavigationDestination(
            icon: const Icon(Icons.face_outlined),
            selectedIcon: const Icon(Icons.face_rounded),
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}
