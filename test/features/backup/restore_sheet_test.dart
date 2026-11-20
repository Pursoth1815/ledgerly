import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/core/backup/backup_engine.dart';
import 'package:loopd/core/backup/backup_platform.dart';
import 'package:loopd/core/database/app_database.dart';
import 'package:loopd/core/database/database_opener.dart';
import 'package:loopd/core/ledger/ledger_engine.dart';
import 'package:loopd/design_system/components/loopd_button.dart';
import 'package:loopd/design_system/loopd_theme.dart';
import 'package:loopd/features/backup/presentation/restore_sheet.dart';
import 'package:path/path.dart' as p;

import '../../support/fake_backup_platform.dart';

/// Restore from a backup on a phone-sized screen, with the native half faked
/// and a real database copy made by a backup first.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final now = DateTime(2026, 11, 18, 9);
  const folder = (uri: 'content://tree/loopd', name: 'Phone › Loopd');

  Future<(FakeBackupPlatform, Directory)> pumpSheet(WidgetTester tester, {BackupFolder? known = folder}) async {
    final database = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    addTearDown(database.close);
    final work = Directory.systemTemp.createTempSync('loopd_restore_sheet');
    addTearDown(() => work.deleteSync(recursive: true));
    final data = Directory(p.join(work.path, 'data'))..createSync();
    final platform = FakeBackupPlatform();
    final engine = BackupEngine(
      database,
      platform,
      workDir: () async => work,
      dataDir: () async => data,
      phoneKey: () async => Uint8List(32),
      clock: () => now,
    );
    // A backup to restore: the fake keeps its database copy.
    await tester.runAsync(() async {
      await LedgerEngine(database).ensureDefaults();
      await engine.setUp(passphrase: 'a long made up phrase', folder: folder);
      await engine.backUpNow();
    });
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database), backupEngineProvider.overrideWithValue(engine)],
        child: MaterialApp(theme: loopdTheme(Brightness.dark), home: const Scaffold()),
      ),
    );
    unawaited(showRestoreSheet(tester.element(find.byType(Scaffold)), folder: known));
    await tester.pumpAndSettle();
    return (platform, data);
  }

  LoopdButton button(WidgetTester tester, String label) =>
      tester.widget<LoopdButton>(find.byWidgetPredicate((w) => w is LoopdButton && w.label == label));

  Future<void> typePassphrase(WidgetTester tester, String text) async {
    await tester.enterText(
      find.descendant(of: find.byKey(RestoreSheet.passphraseKey), matching: find.byType(TextField)),
      text,
    );
    await tester.pump();
  }

  testWidgets('the newest backup in the folder is chosen; Replace waits for a passphrase', (tester) async {
    await pumpSheet(tester);
    expect(find.text('loopd-20261115-020000-aaaa.lpdb'), findsOneWidget);
    expect(find.text('Backed up Sun 15 Nov, 02:00 · 44 KB · 1 part'), findsOneWidget);
    expect(button(tester, 'Replace with this backup').onTap, isNull);
    await typePassphrase(tester, 'something');
    expect(button(tester, 'Replace with this backup').onTap, isNotNull);
  });

  testWidgets('Change lists every backup; picking one switches the card', (tester) async {
    await pumpSheet(tester);
    await tester.tap(find.bySemanticsLabel('Change'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a backup'), findsOneWidget);
    await tester.tap(find.text('Backed up Sun 8 Nov, 02:00 · 41 KB · 1 part'));
    await tester.pumpAndSettle();
    expect(find.text('loopd-20261108-020000-bbbb.lpdb'), findsOneWidget);
  });

  testWidgets('a wrong passphrase says so in the red box, and nothing changes', (tester) async {
    final (_, data) = await pumpSheet(tester);
    await typePassphrase(tester, 'not the right one');
    await tester.tap(find.text('Replace with this backup'));
    await tester.pumpAndSettle();
    expect(find.textContaining('That passphrase doesn’t open this backup'), findsOneWidget);
    expect(File(p.join(data.path, restoreFileName)).existsSync(), isFalse);
  });

  testWidgets('the right passphrase ticks off the steps; Restart Loopd finishes it', (tester) async {
    final (platform, data) = await pumpSheet(tester);
    await typePassphrase(tester, 'a long made up phrase');
    await tester.tap(find.text('Replace with this backup'));
    await tester.pumpAndSettle();

    expect(find.text('Everything is back. Loopd restarts to finish.'), findsOneWidget);
    expect(find.bySemanticsLabel('Ready to switch over, done'), findsOneWidget);
    expect(File(p.join(data.path, restoreFileName)).existsSync(), isTrue, reason: 'waits for the restart');
    await tester.tap(find.text('Restart Loopd'));
    await tester.pump();
    expect(platform.calls.last, 'restart');
  });

  testWidgets('on a new phone, the folder is chosen first', (tester) async {
    await pumpSheet(tester, known: null);
    expect(find.text('Choose the folder with your backups'), findsOneWidget);
    await tester.tap(find.text('Choose the folder with your backups'));
    await tester.pumpAndSettle();
    expect(find.text('loopd-20261115-020000-aaaa.lpdb'), findsOneWidget);
  });
}
