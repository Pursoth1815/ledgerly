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
import 'package:loopd/features/accounts/accounts.dart';
import 'package:loopd/features/accounts/presentation/add_account_sheet.dart';

import '../../support/golden_fonts.dart';

/// Visual tests for Accounts and cards and its Add sheet, in both themes
/// (Mac only). The data is made up, as in the mockups.
void main() {
  setUpAll(loadGoldenFonts);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  /// Returns the ids of Primary, Savings, Salary and Kiwi.
  Future<List<String>> seed(LedgerEngine ledger) async {
    Future<String> add(
      AccountKind kind,
      String name,
      String bank,
      String code,
      String last4, {
      bool makeDefault = false,
    }) => ledger.addAccount(
      kind: kind,
      name: name,
      bankName: bank,
      bankCode: code,
      last4: last4,
      makeDefault: makeDefault,
    );
    final primary = await add(AccountKind.bank, 'Primary', 'Federal Bank', 'FEDBNK', '2210', makeDefault: true);
    final savings = await add(AccountKind.bank, 'Savings', 'HDFC Bank', 'HDFCBK', '8124');
    final salary = await add(AccountKind.bank, 'Salary', 'ICICI Bank', 'ICICIT', '5530');
    final kiwi = await add(AccountKind.creditCard, 'Kiwi', 'YES BANK', 'YESBNK', '4417', makeDefault: true);
    await add(AccountKind.creditCard, 'Amazon Pay', 'ICICI Bank', 'ICICIT', '7781');
    Future<void> spend(int rupees, String from, PaymentMethod method) => ledger.recordExpense(
      amountPaise: rupees * 100,
      method: method,
      fundingAccountId: from,
      categoryId: 'category-food',
      occurredAt: DateTime(2026, 11, 14, 13),
    );
    await spend(1830, primary, PaymentMethod.upi);
    await spend(2350, savings, PaymentMethod.upi);
    await spend(9860, kiwi, PaymentMethod.creditCard);
    await spend(650, SystemAccounts.cash, PaymentMethod.cash);
    return [primary, savings, salary, kiwi];
  }

  Future<void> pump(WidgetTester tester, Brightness brightness, {bool withData = true}) async {
    final database = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    addTearDown(database.close);
    final ledger = LedgerEngine(database, clock: () => DateTime(2026, 11, 1, 9));
    await ledger.ensureDefaults();
    final ids = withData ? await seed(ledger) : const <String>[];
    if (withData) await ledger.saveAccountDetails(ids[3], nickname: 'Kiwi', isDefault: true, billDueDay: 5);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: MaterialApp(debugShowCheckedModeBanner: false, theme: loopdTheme(brightness), home: const Scaffold()),
      ),
    );
    unawaited(showAccountsSheet(tester.element(find.byType(Scaffold)), clock: () => DateTime(2026, 11, 17, 9)));
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    final name = brightness.name;

    testWidgets('Accounts and cards, $name', (tester) async {
      await pump(tester, brightness);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/accounts_$name.png'));
    });

    testWidgets('A credit card opened, its details and bill due date, $name', (tester) async {
      await pump(tester, brightness);
      await tester.tapAt(tester.getTopLeft(find.bySemanticsLabel(RegExp(r'^Kiwi, ₹'))) + const Offset(120, 24));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/wallet_card_$name.png'));
      await tester.tap(find.text('Card details'));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/card_details_$name.png'));
      await tester.tap(find.text('5th of every month ›'));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/bill_due_$name.png'));
    });

    testWidgets('A bank account opened, $name', (tester) async {
      await pump(tester, brightness);
      await tester.tapAt(tester.getTopLeft(find.bySemanticsLabel(RegExp(r'^Primary, ₹'))) + const Offset(120, 24));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/wallet_bank_$name.png'));
    });

    testWidgets('Accounts and cards, empty, $name', (tester) async {
      await pump(tester, brightness, withData: false);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/accounts_empty_$name.png'));
    });

    testWidgets('Add bank account, searching, $name', (tester) async {
      await pump(tester, brightness, withData: false);
      await tester.tap(find.text('+ Add account or card'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(AddAccountSheet.bankFieldKey), 'hd');
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/add_bank_$name.png'));
    });

    testWidgets('Add bank account, a bank not in the list, $name', (tester) async {
      await pump(tester, brightness, withData: false);
      await tester.tap(find.text('+ Add account or card'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(AddAccountSheet.bankFieldKey), 'Zeta Bank');
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/add_bank_new_$name.png'));
      await tester.tap(find.text('Add “Zeta Bank” as a new bank'));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/add_bank_new_chosen_$name.png'));
    });

    testWidgets('Add bank account, digits already saved, $name', (tester) async {
      await pump(tester, brightness);
      await tester.tap(find.text('+ Add account or card'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(AddAccountSheet.bankFieldKey), 'hd');
      await tester.pumpAndSettle();
      await tester.tap(find.text('HDFC Bank').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(AddAccountSheet.last4FieldKey), '2210');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Add account'));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/add_bank_taken_$name.png'));
    });

    testWidgets('Add credit card, filled in, $name', (tester) async {
      await pump(tester, brightness, withData: false);
      await tester.tap(find.text('+ Add account or card'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Credit card'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(AddAccountSheet.bankFieldKey), 'yes');
      await tester.pumpAndSettle();
      await tester.tap(find.text('YES BANK'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(AddAccountSheet.nicknameFieldKey), 'Kiwi');
      await tester.enterText(find.byKey(AddAccountSheet.last4FieldKey), '4417');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/add_card_$name.png'));
    });
  }
}
