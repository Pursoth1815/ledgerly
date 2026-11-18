import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/core/database/app_database.dart';
import 'package:loopd/core/ledger/ledger_engine.dart';
import 'package:loopd/design_system/loopd_theme.dart';
import 'package:loopd/features/expenses/expenses.dart';

import 'money_seed.dart';

/// The Money tab on a phone-sized screen, over an in-memory database with a
/// made-up November (no real names or digits).
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final now = DateTime(2026, 11, 15, 10); // a Sunday

  Future<(LedgerEngine, List<BuildContext>)> pumpMoney(WidgetTester tester, {bool seed = true}) async {
    final database = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    addTearDown(database.close);
    final ledger = LedgerEngine(database, clock: () => now);
    await ledger.ensureDefaults();
    if (seed) await seedNovember(ledger);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final opened = <BuildContext>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database), ledgerEngineProvider.overrideWithValue(ledger)],
        child: MaterialApp(
          theme: loopdTheme(Brightness.dark),
          home: MoneyScreen(onOpenAccounts: (context) async => opened.add(context), clock: () => now),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (ledger, opened);
  }

  Finder scrollable() => find.byType(Scrollable).first;

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.dragUntilVisible(finder, scrollable(), const Offset(0, -250));
    await tester.pumpAndSettle();
  }

  testWidgets("the month's total, split by method; a method with nothing is left out", (tester) async {
    await pumpMoney(tester);
    expect(find.text('Spent in November'), findsOneWidget);
    expect(find.text('November 2026'), findsOneWidget);
    expect(find.bySemanticsLabel('Spent in November, ₹9,140'), findsOneWidget);
    expect(
      find.bySemanticsLabel('UPI ₹2,140, Credit Card ₹7,000'),
      findsOneWidget,
      reason: 'no cash spent, so no Cash',
    );
  });

  testWidgets('a card in "Spent from" filters everything below it; Show all clears it', (tester) async {
    await pumpMoney(tester);
    await tester.tap(find.bySemanticsLabel('Kiwi, ₹7,000'));
    await tester.pumpAndSettle();
    expect(find.text('Spent in November from Kiwi'), findsOneWidget);
    expect(find.bySemanticsLabel('Credit Card ₹7,000'), findsOneWidget);
    await reveal(tester, find.text('Categories · Kiwi'));
    expect(find.text('Categories · Kiwi'), findsOneWidget);

    await tester.dragUntilVisible(find.text('Spent from'), scrollable(), const Offset(0, 250));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Show all'));
    await tester.pumpAndSettle();
    expect(find.text('Show all'), findsNothing, reason: 'nothing chosen');
    expect(find.bySemanticsLabel('Kiwi, ₹7,000'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Kiwi, .*filter')), findsNothing);
  });

  testWidgets('Day and Week, stepping back; Later is off on the current period', (tester) async {
    await pumpMoney(tester);
    await tester.tap(find.bySemanticsLabel('Day'));
    await tester.pumpAndSettle();
    expect(find.text('Sunday, 15 November'), findsOneWidget);
    expect(find.bySemanticsLabel('Spent today, ₹320'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Later'));
    await tester.pumpAndSettle();
    expect(find.text('Sunday, 15 November'), findsOneWidget, reason: 'nothing after today');

    await tester.tap(find.bySemanticsLabel('Earlier'));
    await tester.pumpAndSettle();
    expect(find.text('Spent yesterday'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Later'));
    await tester.pumpAndSettle();
    expect(find.text('Spent today'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Week'));
    await tester.pumpAndSettle();
    expect(find.text('9 – 15 November'), findsOneWidget);
    expect(find.text('Spent this week'), findsOneWidget);
  });

  testWidgets('switching the period never blanks the screen while the new one loads', (tester) async {
    await pumpMoney(tester);
    for (final kind in ['Day', 'Week', 'Month']) {
      await tester.tap(find.bySemanticsLabel(kind));
      // The very next frame, before the new period has loaded.
      await tester.pump();
      expect(
        find.textContaining(RegExp(r'^Spent (today|this week|in November)$')),
        findsOneWidget,
        reason: '$kind: the total stays on screen',
      );
      expect(find.text('Spent from'), findsOneWidget, reason: kind);
      await tester.pumpAndSettle();
    }
    expect(find.text('Spent in November'), findsOneWidget);
  });

  testWidgets('the top five categories, and Show all opens every one in a sheet', (tester) async {
    await pumpMoney(tester);
    await reveal(tester, find.bySemanticsLabel(RegExp(r'^Bills, ')));
    expect(find.bySemanticsLabel('Bills, ₹3,120, 34 percent'), findsOneWidget, reason: 'the largest, first');
    await reveal(tester, find.text('Show all 6'));
    await tester.tap(find.text('Show all 6'));
    await tester.pumpAndSettle();
    expect(find.byType(SpendingSheet), findsOneWidget);
    expect(find.text('November 2026 · 6 categories'), findsOneWidget);
    expect(find.bySemanticsLabel('All accounts and cards, ₹9,140, spent in november'), findsOneWidget);
  });

  testWidgets('expenses by day, newest first; a refund of an October purchase counts in October', (tester) async {
    await pumpMoney(tester);
    await reveal(tester, find.byKey(MoneyScreen.listKey));
    expect(find.text('Today · Sun 15 Nov'), findsOneWidget);
    await reveal(tester, find.textContaining('Refund · Shoes'));
    expect(find.text('+₹2,499'), findsOneWidget);
    expect(find.text('Counts in Oct'), findsOneWidget);
    expect(find.bySemanticsLabel('Spent in November, ₹9,140'), findsNothing, reason: 'scrolled away');
  });

  testWidgets('tapping an expense opens Edit expense', (tester) async {
    await pumpMoney(tester);
    await reveal(tester, find.textContaining('Saravana Bhavan'));
    await tester.tap(find.textContaining('Saravana Bhavan'));
    await tester.pumpAndSettle();
    expect(find.text('Edit expense'), findsOneWidget);
  });

  testWidgets('Show all expenses lists every entry in the sheet', (tester) async {
    await pumpMoney(tester);
    await reveal(tester, find.text('Show all 12'));
    await tester.tap(find.text('Show all 12'));
    await tester.pumpAndSettle();
    expect(find.text('November 2026 · 12 entries'), findsOneWidget);
  });

  testWidgets('Lending says when it comes; the wallet opens Accounts and cards', (tester) async {
    final (_, opened) = await pumpMoney(tester);
    await tester.tap(find.bySemanticsLabel('Accounts and cards'));
    expect(opened, hasLength(1));
    await tester.tap(find.bySemanticsLabel('Lending'));
    await tester.pump();
    expect(find.text('Lending is built in Phase 4'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('with nothing spent, it says so', (tester) async {
    await pumpMoney(tester, seed: false);
    await reveal(tester, find.text('Nothing spent in this period.'));
    expect(find.text('Nothing spent in this period.'), findsOneWidget);
    expect(find.bySemanticsLabel('Cash, ₹0'), findsOneWidget, reason: 'Cash in hand is always there');
  });
}
