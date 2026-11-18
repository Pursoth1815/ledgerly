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

import '../../support/golden_fonts.dart';

/// Visual tests for the expense form, screens 3, 3b and 3c, in both themes
/// (Mac only). The data is made up, as in the mockups.
void main() {
  setUpAll(loadGoldenFonts);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final now = DateTime(2026, 11, 15, 10, 29);

  Future<void> seed(LedgerEngine ledger) async {
    Future<String> add(AccountKind kind, String name, String bank, String last4, {bool makeDefault = false}) =>
        ledger.addAccount(kind: kind, name: name, bankName: bank, last4: last4, makeDefault: makeDefault);
    await add(AccountKind.bank, 'Primary', 'Federal Bank', '2210', makeDefault: true);
    await add(AccountKind.bank, 'Savings', 'HDFC Bank', '8124');
    await add(AccountKind.bank, 'Salary', 'ICICI Bank', '5530');
    await add(AccountKind.creditCard, 'Kiwi', 'YES BANK', '4417', makeDefault: true);
    await add(AccountKind.creditCard, 'Amazon Pay', 'ICICI Bank', '7781');
    await ledger.countCash(235000);
  }

  Future<void> pump(WidgetTester tester, Brightness brightness) async {
    final database = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    addTearDown(database.close);
    final ledger = LedgerEngine(database, clock: () => now);
    await ledger.ensureDefaults();
    await seed(ledger);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database), ledgerEngineProvider.overrideWithValue(ledger)],
        child: MaterialApp(debugShowCheckedModeBanner: false, theme: loopdTheme(brightness), home: const Scaffold()),
      ),
    );
    unawaited(showExpenseSheet(tester.element(find.byType(Scaffold)), clock: () => now));
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester, {required String amount, String? merchant, String? method}) async {
    await tester.enterText(find.byKey(ExpenseSheet.amountFieldKey), amount);
    if (merchant != null) await tester.enterText(find.byKey(ExpenseSheet.merchantFieldKey), merchant);
    if (method != null) await tester.tap(find.text(method));
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  Future<void> chooseCategory(WidgetTester tester, String name) async {
    await tester.ensureVisible(find.text(name));
    await tester.pumpAndSettle();
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    final name = brightness.name;

    testWidgets('Add expense, empty, $name', (tester) async {
      await pump(tester, brightness);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/expense_empty_$name.png'));
    });

    testWidgets('Add expense, UPI, $name', (tester) async {
      await pump(tester, brightness);
      await fill(tester, amount: '250');
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/expense_upi_$name.png'));
      await chooseCategory(tester, 'Food');
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/expense_upi_category_$name.png'));
    });

    testWidgets('Add expense, Credit Card, $name', (tester) async {
      await pump(tester, brightness);
      await fill(tester, amount: '1299', merchant: 'Amazon', method: 'Credit Card');
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/expense_card_$name.png'));
    });

    testWidgets('Add expense, Cash, $name', (tester) async {
      await pump(tester, brightness);
      await fill(tester, amount: '120', merchant: 'Tea stall', method: 'Cash');
      await chooseCategory(tester, 'Snacks');
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/expense_cash_$name.png'));
    });
  }
}
