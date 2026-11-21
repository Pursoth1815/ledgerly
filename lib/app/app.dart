import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings/theme_setting.dart';
import '../design_system/loopd_theme.dart';
import '../features/app_lock/app_lock.dart';
import 'router/app_router.dart';

/// The root widget: Loopd's own themes, dark and light (proposal section 18),
/// and the theme the owner chose.
class LoopdApp extends ConsumerWidget {
  const LoopdApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Loopd',
    debugShowCheckedModeBanner: false,
    theme: loopdTheme(Brightness.light),
    darkTheme: loopdTheme(Brightness.dark),
    themeMode: ref.watch(themeSettingProvider),
    // The theme switch is instant, as in the mockups.
    themeAnimationDuration: Duration.zero,
    routerConfig: ref.watch(appRouterProvider),
    // App lock covers everything, sheets and toasts included.
    builder: (context, child) => AppLockGate(child: child ?? const SizedBox.shrink()),
  );
}
