import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/loopd_colors.dart';
import 'router/app_router.dart';

/// The root widget. Stock Material themes on the mockup backgrounds until the
/// design system (Phase 1).
class LoopdApp extends ConsumerWidget {
  const LoopdApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Loopd',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(scaffoldBackgroundColor: LoopdColors.light.background),
    darkTheme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: LoopdColors.dark.background),
    routerConfig: ref.watch(appRouterProvider),
  );
}
