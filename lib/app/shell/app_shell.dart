import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'loopd_tab_bar.dart';

/// The five-tab shell (ADR 0003). Each tab keeps its own navigator and history.
///
/// The tab bar follows the mockups; the capture button and the rest of the
/// design system arrive in Phase 1.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: navigationShell,
    bottomNavigationBar: LoopdTabBar(
      currentIndex: navigationShell.currentIndex,
      onSelected: (index) => navigationShell.goBranch(
        index,
        // Tapping the current tab again returns to its first page.
        initialLocation: index == navigationShell.currentIndex,
      ),
    ),
  );
}
