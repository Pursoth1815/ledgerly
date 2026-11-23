@Tags(['golden'])
library;

import 'dart:io';

import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/core/backup/backup_engine.dart';
import 'package:loopd/core/database/app_database.dart';
import 'package:loopd/core/ledger/ledger_engine.dart';
import 'package:loopd/core/ledger/ledger_types.dart';
import 'package:loopd/design_system/loopd_theme.dart';
import 'package:loopd/features/today/today.dart';

import '../../support/fake_backup_platform.dart';
import '../../support/golden_fonts.dart';
import '../expenses/money_seed.dart';

/// Today with the Spending card (screen 1), in both themes (Mac only). The
/// data is the made-up November from the Money tab, plus some cash and a
/// backup nine days old.
void main() {
  setUpAll(loadGoldenFonts);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final now = DateTime(2026, 11, 15, 10);

  for (final brightness in Brightness.values) {
    testWidgets('Today with spending, ${brightness.name}', (tester) async {
      final database = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
      addTearDown(database.close);
      final ledger = LedgerEngine(database, clock: () => now);
      await ledger.ensureDefaults();
      await seedNovember(ledger);
      await ledger.recordExpense(
        amountPaise: 15000,
        method: PaymentMethod.cash,
        fundingAccountId: SystemAccounts.cash,
        categoryId: 'category-food',
        occurredAt: DateTime(2026, 11, 15, 9),
        merchant: 'Tea stall',
      );
      final work = Directory.systemTemp.createTempSync('loopd_today_golden');
      addTearDown(() => work.deleteSync(recursive: true));
      var backupNow = DateTime(2026, 11, 6, 10);
      final backup = BackupEngine(database, FakeBackupPlatform(), workDir: () async => work, clock: () => backupNow);
      await tester.runAsync(() async {
        await backup.setUp(
          passphrase: 'a long made up phrase',
          folder: (uri: 'content://tree/loopd', name: 'Phone › Loopd'),
        );
        await backup.backUpNow();
      });
      backupNow = now;
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            ledgerEngineProvider.overrideWithValue(ledger),
            backupEngineProvider.overrideWithValue(backup),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: loopdTheme(brightness),
            home: TodayScreen(onBackUp: (_) async {}, clock: () => now),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/today_spending_${brightness.name}.png'));
    });
  }
}
