@Tags(['golden'])
library;

import 'dart:async';

import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/core/database/app_database.dart';
import 'package:loopd/core/ledger/ledger_engine.dart';
import 'package:loopd/core/ledger/ledger_types.dart';
import 'package:loopd/design_system/loopd_theme.dart';
import 'package:loopd/features/expenses/expenses.dart';
import 'package:loopd/features/expenses/presentation/spending_period.dart';
import 'package:loopd/features/expenses/presentation/spending_sheet.dart' show showSpendingSheet;

import '../../support/golden_fonts.dart';
import 'money_seed.dart';

/// Visual tests for the Money tab and its Show all sheet, screens 5a to 5c,
/// in both themes (Mac only). The data is made up, as in the mockups.
void main() {
  setUpAll(loadGoldenFonts);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final now = DateTime(2026, 11, 15, 10);

  Future<LedgerEngine> pump(WidgetTester tester, Brightness brightness) async {
    final database = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    addTearDown(database.close);
    final ledger = LedgerEngine(database, clock: () => now);
    await ledger.ensureDefaults();
    await seedNovember(ledger);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database), ledgerEngineProvider.overrideWithValue(ledger)],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: loopdTheme(brightness),
          home: MoneyScreen(onOpenAccounts: (_) async {}, clock: () => now),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return ledger;
  }

  for (final brightness in Brightness.values) {
    final name = brightness.name;

    testWidgets('Money tab, $name', (tester) async {
      await pump(tester, brightness);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/money_$name.png'));
    });

    testWidgets('Money tab, categories and expenses, $name', (tester) async {
      await pump(tester, brightness);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -620));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/money_lists_$name.png'));
    });

    testWidgets('Money tab, Kiwi chosen, $name', (tester) async {
      await pump(tester, brightness);
      await tester.tap(find.bySemanticsLabel('Kiwi, ₹7,000'));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/money_kiwi_$name.png'));
    });

    testWidgets('Show all categories, $name', (tester) async {
      await pump(tester, brightness);
      await tester.dragUntilVisible(find.text('Show all 6'), find.byType(Scrollable).first, const Offset(0, -250));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show all 6'));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/money_all_categories_$name.png'));
    });

    testWidgets('Show all expenses, Kiwi, $name', (tester) async {
      final ledger = await pump(tester, brightness);
      final kiwi = (await tester.runAsync(() => ledger.watchAccounts(AccountKind.creditCard).first))!.single;
      unawaited(
        showSpendingSheet(
          tester.element(find.byType(MoneyScreen)),
          view: SpendingView.expenses,
          period: SpendingPeriod.current(PeriodKind.month, now),
          sourceId: kiwi.id,
          onEdit: (_) {},
          clock: () => now,
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/money_all_expenses_$name.png'));
    });
  }
}
