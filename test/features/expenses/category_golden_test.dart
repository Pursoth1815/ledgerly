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

import '../../support/fill_categories.dart';
import '../../support/golden_fonts.dart';

/// Visual tests for Expense categories, screens 10c and 10d, in both themes
/// (Mac only). The amounts are made up, as in the mockups.
void main() {
  setUpAll(loadGoldenFonts);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final now = DateTime(2026, 11, 15, 10);

  Future<void> pump(WidgetTester tester, Brightness brightness, {bool full = false}) async {
    final database = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    addTearDown(database.close);
    final ledger = LedgerEngine(database, clock: () => now);
    await ledger.ensureDefaults();
    final primary = await ledger.addAccount(kind: AccountKind.bank, name: 'Primary', last4: '2210');
    for (final (category, rupees) in [('food', 3240), ('snacks', 860), ('groceries', 2150), ('travel', 1890)]) {
      await ledger.recordExpense(
        amountPaise: rupees * 100,
        method: PaymentMethod.upi,
        fundingAccountId: primary,
        categoryId: 'category-$category',
        occurredAt: DateTime(2026, 11, 10, 13),
      );
    }
    if (full) {
      final added = await fillCategories(ledger);
      await ledger.recordExpense(
        amountPaise: 45000,
        method: PaymentMethod.upi,
        fundingAccountId: primary,
        categoryId: added.first,
        occurredAt: DateTime(2026, 11, 12, 9),
      );
    }
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database), ledgerEngineProvider.overrideWithValue(ledger)],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: loopdTheme(brightness),
          // Still pictures: the delete shake stays put.
          builder: (context, child) =>
              MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
          home: const Scaffold(),
        ),
      ),
    );
    unawaited(showCategorySheet(tester.element(find.byType(Scaffold)), clock: () => now));
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    final name = brightness.name;

    testWidgets('Expense categories, $name', (tester) async {
      await pump(tester, brightness);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/categories_$name.png'));
    });

    testWidgets('New category, $name', (tester) async {
      await pump(tester, brightness);
      await tester.tap(find.text('New category'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(CategorySheet.nameFieldKey), 'Movies');
      await tester.tap(find.bySemanticsLabel('Film icon'));
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/category_new_$name.png'));
    });

    testWidgets('Edit category, a name already used, $name', (tester) async {
      await pump(tester, brightness);
      await tester.tap(find.bySemanticsLabel('Snacks, ₹860 this month'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(CategorySheet.nameFieldKey), 'Food');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/category_edit_taken_$name.png'));
    });

    testWidgets('Expense categories at the limit, $name', (tester) async {
      await pump(tester, brightness, full: true);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/categories_full_$name.png'));
    });

    testWidgets('Delete categories, two ticked, $name', (tester) async {
      await pump(tester, brightness, full: true);
      await tester.tap(find.text('Delete categories'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(SingleChildScrollView).last, const Offset(0, -560));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Delete Extra 1'));
      await tester.tap(find.bySemanticsLabel('Delete Extra 3'));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/category_delete_choose_$name.png'));
    });

    testWidgets('Delete categories, where the expenses go, $name', (tester) async {
      await pump(tester, brightness, full: true);
      await tester.tap(find.text('Delete categories'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(SingleChildScrollView).last, const Offset(0, -560));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Delete Extra 1'));
      await tester.tap(find.bySemanticsLabel('Delete Extra 3'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete 2 categories'));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/category_delete_move_$name.png'));
    });
  }
}
