import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/routing/route_paths.dart';
import '../../design_system/gallery/component_gallery.dart';
import '../../features/today/today.dart';
import '../shell/app_shell.dart';
import '../shell/app_tab.dart';
import '../shell/more_page.dart';
import '../shell/placeholder_page.dart';

part 'app_router.g.dart';

/// The app's routes (ADR 0003). Features add their routes here as they are
/// built; they navigate to each other only by path.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final router = GoRouter(
    initialLocation: RoutePaths.today,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          for (final tab in AppTab.values)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: tab.path,
                  builder: (context, state) => switch (tab) {
                    AppTab.today => const TodayScreen(),
                    AppTab.more => const MorePage(),
                    _ => PlaceholderPage(tab: tab),
                  },
                ),
              ],
            ),
        ],
      ),
      // Phase 1: every shared component on one page. Not in release builds.
      if (!kReleaseMode) GoRoute(path: RoutePaths.gallery, builder: (context, state) => const ComponentGallery()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
