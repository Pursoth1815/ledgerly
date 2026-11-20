@Tags(['golden'])
library;

import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/core/backup/backup_engine.dart';
import 'package:loopd/core/database/app_database.dart';
import 'package:loopd/design_system/loopd_theme.dart';
import 'package:loopd/features/backup/backup.dart';
import 'package:loopd/features/backup/presentation/backup_setup_sheet.dart';

import '../../support/fake_backup_platform.dart';
import '../../support/golden_fonts.dart';

/// Visual tests for the Backup & restore sheet (screen 10f) and Set up backup (10i), in
/// both themes (Mac only).
void main() {
  setUpAll(loadGoldenFonts);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final now = DateTime(2026, 11, 18, 9);
  const folder = (uri: 'content://tree/loopd', name: 'Drive › Loopd backups');

  /// [backedUpAt]: when the one earlier backup was made, if any.
  Future<void> pump(WidgetTester tester, Brightness brightness, {DateTime? backedUpAt}) async {
    final database = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    addTearDown(database.close);
    final work = Directory.systemTemp.createTempSync('loopd_backup_golden');
    addTearDown(() => work.deleteSync(recursive: true));
    var clock = backedUpAt ?? now;
    final engine = BackupEngine(database, FakeBackupPlatform(), workDir: () async => work, clock: () => clock);
    if (backedUpAt != null) {
      await tester.runAsync(() async {
        await engine.setUp(passphrase: 'a long made up phrase', folder: folder);
        await engine.backUpNow();
      });
      clock = now;
    }
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database), backupEngineProvider.overrideWithValue(engine)],
        child: MaterialApp(debugShowCheckedModeBanner: false, theme: loopdTheme(brightness), home: const Scaffold()),
      ),
    );
    unawaited(showBackupSheet(tester.element(find.byType(Scaffold)), clock: () => now));
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    final name = brightness.name;

    testWidgets('Backup & restore, before setup, $name', (tester) async {
      await pump(tester, brightness);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/backup_off_$name.png'));
    });

    testWidgets('Backup & restore, a backup is due, $name', (tester) async {
      await pump(tester, brightness, backedUpAt: now.subtract(const Duration(days: 9)));
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/backup_due_$name.png'));
    });

    testWidgets('Backup & restore, backed up just now, $name', (tester) async {
      await pump(tester, brightness, backedUpAt: now.subtract(const Duration(days: 9)));
      await tester.tap(find.bySemanticsLabel('Back up now'));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/backup_done_$name.png'));
    });

    testWidgets('Set up backup, filled in, $name', (tester) async {
      await pump(tester, brightness);
      await tester.tap(find.bySemanticsLabel('Set up backup'));
      await tester.pumpAndSettle();
      for (final key in [BackupSetupSheet.passphraseKey, BackupSetupSheet.againKey]) {
        await tester.enterText(
          find.descendant(of: find.byKey(key), matching: find.byType(TextField)),
          'a long made up phrase',
        );
      }
      await tester.tap(find.bySemanticsLabel('Choose a folder'));
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/backup_setup_$name.png'));
    });
  }
}
