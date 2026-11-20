@Tags(['golden'])
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

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
import 'package:loopd/features/backup/presentation/passphrase_sheet.dart';
import 'package:loopd/features/backup/presentation/restore_sheet.dart';

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
    final data = Directory('${work.path}/data')..createSync();
    final engine = BackupEngine(
      database,
      FakeBackupPlatform(),
      workDir: () async => work,
      dataDir: () async => data,
      phoneKey: () async => Uint8List(32),
      clock: () => clock,
    );
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

    Future<void> openRestore(WidgetTester tester, String passphrase) async {
      await pump(tester, brightness, backedUpAt: now.subtract(const Duration(days: 9)));
      await tester.ensureVisible(find.text('Restore from a backup file'));
      await tester.tap(find.text('Restore from a backup file'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(of: find.byKey(RestoreSheet.passphraseKey), matching: find.byType(TextField)),
        passphrase,
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Replace with this backup'));
      await tester.pumpAndSettle();
    }

    testWidgets('Restore from a backup, a wrong passphrase, $name', (tester) async {
      await openRestore(tester, 'not the right one');
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/restore_wrong_$name.png'));
    });

    testWidgets('Restore from a backup, done, $name', (tester) async {
      await openRestore(tester, 'a long made up phrase');
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/restore_done_$name.png'));
    });

    testWidgets('Change passphrase, $name', (tester) async {
      await pump(tester, brightness, backedUpAt: now.subtract(const Duration(days: 9)));
      await tester.tap(find.bySemanticsLabel('Change').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(of: find.byKey(PassphraseSheet.newKey), matching: find.byType(TextField)),
        'a brand new phrase',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/passphrase_change_$name.png'));
    });

    testWidgets('Forgot passphrase, $name', (tester) async {
      await pump(tester, brightness, backedUpAt: now.subtract(const Duration(days: 9)));
      await tester.tap(find.bySemanticsLabel('Change').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forgot it?'));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/passphrase_forgot_$name.png'));
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
