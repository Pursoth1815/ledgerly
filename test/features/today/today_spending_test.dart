import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/core/database/app_database.dart';
import 'package:loopd/core/ledger/ledger_engine.dart';
import 'package:loopd/core/ledger/ledger_types.dart';
import 'package:loopd/design_system/loopd_theme.dart';
import 'package:loopd/features/today/today.dart';

import '../expenses/money_seed.dart';

/// Today's Spending card over an in-memory database with a made-up November
/// (no real names or digits).
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final now = DateTime(2026, 11, 15, 10); // a Sunday

  Future<(LedgerEngine, List<BuildContext>)> pumpToday(
    WidgetTester tester, {
    Future<void> Function(LedgerEngine ledger)? seed,
  }) async {
    final database = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    addTearDown(database.close);
    final ledger = LedgerEngine(database, clock: () => now);
    await ledger.ensureDefaults();
    await seed?.call(ledger);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final opened = <BuildContext>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database), ledgerEngineProvider.overrideWithValue(ledger)],
        child: MaterialApp(
          theme: loopdTheme(Brightness.dark),
          home: TodayScreen(onBackUp: (_) async {}, clock: () => now),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (ledger, opened);
  }

  testWidgets('with nothing spent and no cash, Today is all clear', (tester) async {
    await pumpToday(tester);
    expect(find.text('All clear'), findsOneWidget);
    expect(find.text('Spending'), findsNothing);
  });

  testWidgets('today and the month so far, split by method; a method with nothing is left out', (tester) async {
    await pumpToday(tester, seed: seedNovember);
    expect(find.text('All clear'), findsNothing);
    expect(find.bySemanticsLabel('Today, ₹320'), findsOneWidget);
    expect(find.bySemanticsLabel('November so far, ₹9,140'), findsOneWidget);
    expect(find.bySemanticsLabel('UPI ₹2,140, Credit Card ₹7,000'), findsOneWidget, reason: 'no cash spent');
    expect(find.textContaining('Cash in hand'), findsNothing);
  });

  testWidgets('a new expense shows at once, cash included', (tester) async {
    final (ledger, _) = await pumpToday(tester, seed: seedNovember);
    await tester.runAsync(
      () => ledger.recordExpense(
        amountPaise: 15000,
        method: PaymentMethod.cash,
        fundingAccountId: SystemAccounts.cash,
        categoryId: 'category-food',
        occurredAt: DateTime(2026, 11, 15, 9),
        merchant: 'Tea stall',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Today, ₹470'), findsOneWidget);
    expect(find.bySemanticsLabel('November so far, ₹9,290'), findsOneWidget);
    expect(find.bySemanticsLabel('UPI ₹2,140, Credit Card ₹7,000, Cash ₹150'), findsOneWidget);
  });

  testWidgets('with nothing spent this month the card stays away, whatever cash was counted', (tester) async {
    await pumpToday(tester, seed: (ledger) => ledger.countCash(50000, at: DateTime(2026, 11, 1, 9)));
    expect(find.text('Spending'), findsNothing);
    expect(find.text('All clear'), findsOneWidget);
  });
}
