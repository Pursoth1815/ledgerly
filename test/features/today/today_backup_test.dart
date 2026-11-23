import 'dart:io';

import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/core/backup/backup_engine.dart';
import 'package:loopd/core/database/app_database.dart';
import 'package:loopd/core/ledger/ledger_engine.dart';
import 'package:loopd/design_system/loopd_theme.dart';
import 'package:loopd/features/today/today.dart';

import '../../support/fake_backup_platform.dart';

/// Today's Backup nudge, with the native half of backup faked.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final now = DateTime(2026, 11, 15, 10);

  /// Sets backup up when [setUp], and backs up at [backedUpAt] when given.
  Future<List<BuildContext>> pumpToday(WidgetTester tester, {bool setUp = false, DateTime? backedUpAt}) async {
    final database = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    addTearDown(database.close);
    final work = Directory.systemTemp.createTempSync('loopd_today_backup');
    addTearDown(() => work.deleteSync(recursive: true));
    var engineNow = backedUpAt ?? now;
    final backup = BackupEngine(database, FakeBackupPlatform(), workDir: () async => work, clock: () => engineNow);
    final ledger = LedgerEngine(database, clock: () => now);
    await tester.runAsync(() async {
      await ledger.ensureDefaults();
      if (setUp) {
        await backup.setUp(
          passphrase: 'a long made up phrase',
          folder: (uri: 'content://tree/loopd', name: 'Phone › Loopd'),
        );
      }
      if (backedUpAt != null) await backup.backUpNow();
    });
    engineNow = now;
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final opened = <BuildContext>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          ledgerEngineProvider.overrideWithValue(ledger),
          backupEngineProvider.overrideWithValue(backup),
        ],
        child: MaterialApp(
          theme: loopdTheme(Brightness.dark),
          home: TodayScreen(onBackUp: (context) async => opened.add(context), clock: () => now),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return opened;
  }

  testWidgets('while backups are off there is no nudge; Today stays all clear', (tester) async {
    await pumpToday(tester);
    expect(find.text('All clear'), findsOneWidget);
    expect(find.text('Back up'), findsNothing);
  });

  testWidgets('set up but never backed up: "No backup yet", and Back up opens backup', (tester) async {
    final opened = await pumpToday(tester, setUp: true);
    expect(find.text('No backup yet'), findsOneWidget);
    expect(find.text('All clear'), findsNothing, reason: 'All clear is only the empty state');
    await tester.tap(find.bySemanticsLabel('Back up'));
    await tester.pumpAndSettle();
    expect(opened, hasLength(1));
  });

  testWidgets('a backup more than seven days old is nudged', (tester) async {
    await pumpToday(tester, setUp: true, backedUpAt: DateTime(2026, 11, 5, 10));
    expect(find.bySemanticsLabel('Last backup 10 days ago. Encrypted, to a folder you choose'), findsOneWidget);
  });

  testWidgets('a backup from this week needs nothing', (tester) async {
    await pumpToday(tester, setUp: true, backedUpAt: DateTime(2026, 11, 12, 10));
    expect(find.text('Back up'), findsNothing);
    expect(find.text('All clear'), findsOneWidget);
  });
}
