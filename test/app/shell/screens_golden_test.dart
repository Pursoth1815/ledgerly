@Tags(['golden'])
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/app/config/app_config.dart';
import 'package:loopd/app/shell/more_page.dart';
import 'package:loopd/core/database/app_database.dart';
import 'package:loopd/design_system/loopd_theme.dart';
import 'package:loopd/features/capture/capture.dart';
import 'package:loopd/features/today/today.dart';

import '../../support/golden_fonts.dart';

/// Visual tests for the Phase 1 screens in both themes (Mac only; see
/// dart_test.yaml). Today uses a fixed date so the picture does not change.
void main() {
  setUpAll(loadGoldenFonts);

  Future<void> pumpScreen(WidgetTester tester, Widget screen, Brightness brightness) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final database = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    addTearDown(database.close);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(const AppConfig(distribution: Distribution.personal)),
          appDatabaseProvider.overrideWithValue(database),
        ],
        child: MaterialApp(debugShowCheckedModeBanner: false, theme: loopdTheme(brightness), home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    final name = brightness.name;

    testWidgets('Today, empty, $name', (tester) async {
      await pumpScreen(tester, TodayScreen(onBackUp: (_) async {}, clock: () => DateTime(2026, 11, 15)), brightness);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/today_$name.png'));
    });

    testWidgets('More, $name', (tester) async {
      await pumpScreen(tester, const MorePage(), brightness);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/more_$name.png'));
    });

    testWidgets('Capture sheet, $name', (tester) async {
      await pumpScreen(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(onPressed: () => showCaptureSheet(context), child: const Text('open')),
            ),
          ),
        ),
        brightness,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/capture_$name.png'));
    });
  }
}
