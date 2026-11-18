import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/routing/route_paths.dart';
import '../../design_system/gallery/component_gallery.dart';
import '../../features/accounts/accounts.dart';
import '../../features/expenses/expenses.dart';
import '../../features/today/today.dart';
import '../shell/app_shell.dart';
import '../shell/app_tab.dart';
import '../shell/capture_button_visibility.dart';
import '../shell/more_page.dart';
import '../shell/placeholder_page.dart';

part 'app_router.g.dart';

/// The app's routes (ADR 0003). Features add their routes here as they are
/// built; they navigate to each other only by path.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // Every navigator reports its sheets and dialogs, so the capture button
  // can step aside (capture_button_visibility.dart).
  final overlays = ref.read(openOverlaysProvider.notifier);
  final router = GoRouter(
    initialLocation: RoutePaths.today,
    observers: [overlays.observer()],
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          for (final tab in AppTab.values)
            StatefulShellBranch(
              observers: [overlays.observer()],
              routes: [
                GoRoute(
                  path: tab.path,
                  builder: (context, state) => switch (tab) {
                    AppTab.today => const TodayScreen(),
                    // The Accounts and Add account sheets write, so they
                    // are passed in here (architecture rule 3).
                    AppTab.money => MoneyScreen(
                      onOpenAccounts: showAccountsSheet,
                      onAddAccount: (context, kind) => showAddAccountSheet(context, kind: kind),
                    ),
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
  final location = ref.read(shellLocationProvider.notifier);
  void track() => location.update(router.routerDelegate.currentConfiguration.uri.path);
  router.routerDelegate.addListener(track);
  ref.onDispose(() {
    router.routerDelegate.removeListener(track);
    router.dispose();
  });
  return router;
}
