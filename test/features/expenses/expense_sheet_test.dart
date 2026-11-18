import 'dart:async';

import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/core/database/app_database.dart';
import 'package:loopd/core/ledger/ledger_engine.dart';
import 'package:loopd/core/ledger/ledger_types.dart';
import 'package:loopd/design_system/components/loopd_button.dart';
import 'package:loopd/design_system/loopd_theme.dart';
import 'package:loopd/features/expenses/expenses.dart';

/// The expense form on a phone-sized screen, over an in-memory database.
/// Names and digits are made up.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final now = DateTime(2026, 11, 17, 9);

  Future<LedgerEngine> pumpForm(
    WidgetTester tester, {
    Future<void> Function(LedgerEngine ledger)? seed,
    String? Function()? expenseId,
    AddAccountAction? onAddAccount,
  }) async {
    final database = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    addTearDown(database.close);
    final ledger = LedgerEngine(database, clock: () => now);
    await ledger.ensureDefaults();
    await seed?.call(ledger);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database), ledgerEngineProvider.overrideWithValue(ledger)],
        child: MaterialApp(theme: loopdTheme(Brightness.dark), home: const Scaffold()),
      ),
    );
    unawaited(
      showExpenseSheet(
        tester.element(find.byType(Scaffold)),
        expenseId: expenseId?.call(),
        onAddAccount: onAddAccount,
        clock: () => now,
      ),
    );
    await tester.pumpAndSettle();
    return ledger;
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  /// Types into the amount, scrolling back up to it first.
  Future<void> typeAmount(WidgetTester tester, String text) async {
    final field = find.byKey(ExpenseSheet.amountFieldKey);
    await tester.scrollUntilVisible(
      field,
      -200,
      scrollable: find.descendant(of: find.byKey(ExpenseSheet.formKey), matching: find.byType(Scrollable)).first,
    );
    await tester.enterText(field, text);
    await tester.pumpAndSettle();
  }

  LoopdButton save(WidgetTester tester) =>
      tester.widget<LoopdButton>(find.byWidgetPredicate((w) => w is LoopdButton && w.label.startsWith('Save')));

  Future<String> addPrimary(LedgerEngine ledger, {bool makeDefault = true}) => ledger.addAccount(
    kind: AccountKind.bank,
    name: 'Primary',
    bankName: 'Federal Bank',
    bankCode: 'FEDBNK',
    last4: '2210',
    makeDefault: makeDefault,
  );

  Future<int> spentIn(LedgerEngine ledger, String accountId) async =>
      (await ledger.watchMonthSpending(now).first)[accountId] ?? 0;

  testWidgets('adds a UPI expense from the default account, then Undo removes it', (tester) async {
    late String primary;
    final ledger = await pumpForm(
      tester,
      seed: (ledger) async {
        primary = await addPrimary(ledger);
        await ledger.addAccount(kind: AccountKind.bank, name: 'Savings', bankName: 'HDFC Bank', last4: '8124');
      },
    );
    expect(find.text('Add expense'), findsOneWidget);
    expect(find.text('Today, 9:00 am ›'), findsOneWidget);
    expect(save(tester).label, 'Save');
    expect(save(tester).onTap, isNull, reason: 'no amount or category yet');

    await typeAmount(tester, '250');
    expect(save(tester).label, 'Save ₹250');
    expect(save(tester).onTap, isNull, reason: 'no category yet');
    await tester.enterText(find.byKey(ExpenseSheet.merchantFieldKey), 'Swiggy');
    await tapText(tester, 'Food');
    expect(save(tester).onTap, isNotNull, reason: 'Primary is the default, so it is chosen');

    await tapText(tester, 'Save ₹250');
    expect(find.text('Add expense'), findsNothing, reason: 'the sheet closes');
    expect(find.text('Saved ₹250 · Food'), findsOneWidget);
    expect(await spentIn(ledger, primary), 25000);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Removed ₹250'), findsOneWidget);
    expect(await spentIn(ledger, primary), 0);
  });

  testWidgets('with no default and two accounts, one must be picked', (tester) async {
    await pumpForm(
      tester,
      seed: (ledger) async {
        await addPrimary(ledger, makeDefault: false);
        await ledger.addAccount(kind: AccountKind.bank, name: 'Savings', bankName: 'HDFC Bank', last4: '8124');
      },
    );
    await typeAmount(tester, '99');
    await tapText(tester, 'Snacks');
    expect(save(tester).onTap, isNull);
    await tapText(tester, 'Savings');
    expect(save(tester).onTap, isNotNull);
  });

  testWidgets('Credit Card lists the cards, and Cash says what is left', (tester) async {
    late String kiwi;
    final ledger = await pumpForm(
      tester,
      seed: (ledger) async {
        await addPrimary(ledger);
        kiwi = await ledger.addAccount(
          kind: AccountKind.creditCard,
          name: 'Kiwi',
          bankName: 'YES BANK',
          last4: '4417',
          makeDefault: true,
        );
        await ledger.countCash(235000);
      },
    );
    await typeAmount(tester, '120');
    await tapText(tester, 'Credit Card');
    expect(find.text('Kiwi'), findsOneWidget);
    expect(find.text('Primary'), findsNothing);

    await tapText(tester, 'Cash');
    expect(find.text('₹2,350 now · ₹2,230 after this'), findsOneWidget);
    await typeAmount(tester, '3000');
    expect(find.text('₹2,350 now · more than you have · update your cash'), findsOneWidget);

    await tapText(tester, 'Credit Card');
    await tapText(tester, 'Shopping');
    await tapText(tester, 'Save ₹3,000');
    expect(await spentIn(ledger, kiwi), 300000);
  });

  testWidgets('the amount is grouped as you type, and a third decimal is refused', (tester) async {
    await pumpForm(tester, seed: addPrimary);
    final field = find.byKey(ExpenseSheet.amountFieldKey);
    await tester.enterText(field, '123456');
    await tester.pump();
    expect(find.text('1,23,456'), findsOneWidget);
    await tester.enterText(field, '62.505');
    await tester.pump();
    expect(find.text('1,23,456'), findsOneWidget, reason: 'refused, so the old text stays');
  });

  testWidgets('with no bank account, it offers to add one', (tester) async {
    AccountKind? asked;
    await pumpForm(tester, onAddAccount: (context, kind) async => asked = kind);
    expect(find.text('No bank accounts yet. UPI is paid from one.'), findsOneWidget);
    await tapText(tester, '+ Add bank account');
    expect(asked, AccountKind.bank);
    await tapText(tester, 'Credit Card');
    await tapText(tester, '+ Add credit card');
    expect(asked, AccountKind.creditCard);
  });

  testWidgets('the date and time can be changed', (tester) async {
    await pumpForm(tester, seed: addPrimary);
    await tester.tap(find.byKey(ExpenseSheet.whenKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('10 Nov, 9:00 am ›'), findsOneWidget);
  });

  group('editing', () {
    late String id;
    late String primary;

    Future<void> seedOne(LedgerEngine ledger) async {
      primary = await addPrimary(ledger);
      id = await ledger.recordExpense(
        amountPaise: 25000,
        method: PaymentMethod.upi,
        fundingAccountId: primary,
        categoryId: 'category-food',
        occurredAt: DateTime(2026, 11, 16, 13, 5),
        merchant: 'Swiggy',
      );
    }

    testWidgets('loads the expense, saves a change, and Undo brings the old one back', (tester) async {
      final ledger = await pumpForm(tester, seed: seedOne, expenseId: () => id);
      expect(find.text('Edit expense'), findsOneWidget);
      expect(find.text('250'), findsOneWidget);
      expect(find.text('Swiggy'), findsOneWidget);
      expect(find.text('Yesterday, 1:05 pm ›'), findsOneWidget);
      expect(save(tester).onTap, isNotNull, reason: 'everything is already filled in');

      await typeAmount(tester, '300');
      await tapText(tester, 'Save ₹300');
      expect(find.text('Saved changes'), findsOneWidget);
      expect((await ledger.getExpense(id))!.amountPaise, 30000);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('Change undone'), findsOneWidget);
      expect((await ledger.getExpense(id))!.amountPaise, 25000);
    });

    testWidgets('Delete removes it, and Undo brings it back', (tester) async {
      final ledger = await pumpForm(tester, seed: seedOne, expenseId: () => id);
      await tester.tap(find.bySemanticsLabel('Delete expense'));
      await tester.pumpAndSettle();
      expect(find.text('Deleted ₹250'), findsOneWidget);
      expect(await ledger.getExpense(id), isNull);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('Brought back ₹250'), findsOneWidget);
      expect((await ledger.getExpense(id))!.amountPaise, 25000);
    });

    testWidgets('an account removed since still shows, marked Removed', (tester) async {
      await pumpForm(
        tester,
        seed: (ledger) async {
          await seedOne(ledger);
          await ledger.removeAccount(primary);
        },
        expenseId: () => id,
      );
      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('Removed'), findsOneWidget);
      expect(save(tester).onTap, isNotNull);
    });

    testWidgets('an expense that no longer exists says so', (tester) async {
      await pumpForm(
        tester,
        seed: (ledger) async {
          await seedOne(ledger);
          await ledger.delete(id);
        },
        expenseId: () => id,
      );
      expect(find.text('This expense no longer exists.'), findsOneWidget);
      expect(save(tester).onTap, isNull);
    });
  });
}
