@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/app/shell/loopd_tab_bar.dart';
import 'package:loopd/core/settings/app_lock_setting.dart';
import 'package:loopd/features/app_lock/app_lock.dart';

import '../../support/fake_device_auth.dart';
import '../../support/golden_fonts.dart';
import '../../support/pump_loopd_app.dart';

/// Visual tests for App lock (screen 10m) and Loopd is locked (10n-b), in both
/// themes (Mac only). The rising icons are caught at a fixed moment.
void main() {
  setUpAll(loadGoldenFonts);

  Future<void> phone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
  }

  for (final theme in [ThemeMode.dark, ThemeMode.light]) {
    final name = theme.name;

    testWidgets('Loopd is locked, $name', (tester) async {
      await phone(tester);
      // Held still, so the picture is the same every time.
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await pumpLoopdApp(
        tester,
        theme: theme,
        device: FakeDeviceAuth()..passes = false,
        appLock: const AppLockSettings(enabled: true),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(LockScreen), findsOneWidget);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/locked_$name.png'));
    });

    testWidgets('App lock, on, $name', (tester) async {
      await phone(tester);
      await pumpLoopdApp(tester, theme: theme);
      await tester.tap(find.descendant(of: find.byType(LoopdTabBar), matching: find.text('More')));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
      await tester.pumpAndSettle();
      await tester.tap(find.text('App lock'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Lock Loopd'));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/app_lock_on_$name.png'));
    });
  }
}
