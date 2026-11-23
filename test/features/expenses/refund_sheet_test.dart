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

/// Refunds (screens A9 to A12) on a phone-sized screen, over an in-memory
/// database. Names and digits are made up.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final now = DateTime(2026, 11, 17, 9);
  late String kiwi;
  late String shoes;

  Future<LedgerEngine> pumpApp(WidgetTester tester, {Future<void> Function(LedgerEngine ledger)? seed}) async {
    final database = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    addTearDown(database.close);
    final ledger = LedgerEngine(database, clock: () => now);
    await tester.runAsync(() async {
      await ledger.ensureDefaults();
      kiwi = await ledger.addAccount(kind: AccountKind.creditCard, name: 'Kiwi', bankName: 'YES BANK', last4: '4417');
      shoes = await ledger.recordExpense(
        amountPaise: 150000,
        method: PaymentMethod.creditCard,
        fundingAccountId: kiwi,
        categoryId: 'category-shopping',
        occurredAt: DateTime(2026, 11, 12, 12),
        merchant: 'Decathlon',
      );
      await seed?.call(ledger);
    });
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database), ledgerEngineProvider.overrideWithValue(ledger)],
        child: MaterialApp(theme: loopdTheme(Brightness.dark), home: const Scaffold()),
      ),
    );
    return ledger;
  }

  /// Database work finishes on real time, then the frames catch up.
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester, Future<void> Function(BuildContext context) show) async {
    unawaited(show(tester.element(find.byType(Scaffold).first)));
    await settle(tester);
  }

  Finder button(String label) => find.byWidgetPredicate((w) => w is LoopdButton && w.label == label);
  bool enabled(WidgetTester tester, String label) => tester.widget<LoopdButton>(button(label)).onTap != null;

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await settle(tester);
  }

  Future<void> refund(LedgerEngine ledger, int paise) => ledger.recordRefund(
    originalId: shoes,
    amountPaise: paise,
    method: PaymentMethod.creditCard,
    destinationAccountId: kiwi,
    occurredAt: DateTime(2026, 11, 14, 12),
  );

  testWidgets('starts with what is left, warns above it, and goes back to the card it was paid with', (tester) async {
    final ledger = await pumpApp(tester);
    await open(tester, (context) => showRefundSheet(context, expenseId: shoes, clock: () => now));
    expect(find.text('Add refund'), findsOneWidget);
    expect(find.text('Decathlon · ₹1,500 · 12 Nov'), findsOneWidget);
    expect(find.text('Up to ₹1,500'), findsOneWidget);
    expect(find.text('Refunded to'), findsNothing, reason: 'no balances, so no choice of account');

    await tester.enterText(find.byKey(RefundSheet.amountFieldKey), '2000');
    await tester.pumpAndSettle();
    expect(find.text('More than the ₹1,500 left to refund'), findsOneWidget);
    expect(enabled(tester, 'Save refund ₹2,000'), isFalse);

    await tester.enterText(find.byKey(RefundSheet.amountFieldKey), '500');
    await tester.pumpAndSettle();
    await tap(tester, button('Save refund ₹500'));
    expect(find.text('Refund of ₹500 saved'), findsOneWidget);
    expect(await tester.runAsync(() => ledger.refundedPaise(shoes)), 50000);
    final saved = (await tester.runAsync(() => ledger.refundsOf(shoes)))!.single;
    expect((saved.destinationAccountId, saved.method), (kiwi, PaymentMethod.creditCard));
  });

  testWidgets('a refund can still go back to a card removed since', (tester) async {
    final ledger = await pumpApp(tester, seed: (ledger) => ledger.removeAccount(kiwi));
    await open(tester, (context) => showRefundSheet(context, expenseId: shoes, clock: () => now));
    await tap(tester, button('Save refund ₹1,500'));
    expect(find.text('Refund of ₹1,500 saved'), findsOneWidget);
    expect(await tester.runAsync(() => ledger.refundedPaise(shoes)), 150000);
  });

  testWidgets('a saved refund opens to edit, and deletes with Undo', (tester) async {
    late String id;
    final ledger = await pumpApp(
      tester,
      seed: (ledger) async {
        await refund(ledger, 50000);
        id = (await ledger.refundsOf(shoes)).single.id;
      },
    );
    await open(tester, (context) => showRefundSheet(context, expenseId: shoes, refundId: id, clock: () => now));
    expect(find.text('Edit refund'), findsOneWidget);
    expect(find.text('Up to ₹1,500'), findsOneWidget, reason: 'its own amount does not count against it');
    await tester.enterText(find.byKey(RefundSheet.amountFieldKey), '600');
    await tester.pumpAndSettle();
    await tap(tester, button('Save changes'));
    expect(await tester.runAsync(() => ledger.refundedPaise(shoes)), 60000);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await open(tester, (context) => showRefundSheet(context, expenseId: shoes, refundId: id, clock: () => now));
    await tap(tester, button('Delete refund'));
    expect(find.text('Deleted ₹600'), findsOneWidget);
    expect(await tester.runAsync(() => ledger.refundedPaise(shoes)), 0);
    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(find.text('Brought back ₹600'), findsOneWidget);
    expect(await tester.runAsync(() => ledger.refundedPaise(shoes)), 60000);
  });

  group('from Edit expense', () {
    Future<void> reveal(WidgetTester tester, Finder finder) async {
      await tester.dragUntilVisible(finder, find.byKey(ExpenseSheet.formKey), const Offset(0, -250));
      await tester.pumpAndSettle();
    }

    testWidgets('offers Add refund, and shows what has come back', (tester) async {
      await pumpApp(tester, seed: (ledger) => refund(ledger, 30000));
      await open(tester, (context) => showExpenseSheet(context, expenseId: shoes, clock: () => now));
      await reveal(tester, find.text('Add refund'));
      expect(find.textContaining('₹300 refunded'), findsOneWidget);
      await tester.tap(find.text('Add refund'));
      await settle(tester);
      expect(find.text('Up to ₹1,200'), findsOneWidget);
    });

    testWidgets('a fully refunded purchase offers no more refunds', (tester) async {
      await pumpApp(tester, seed: (ledger) => refund(ledger, 150000));
      await open(tester, (context) => showExpenseSheet(context, expenseId: shoes, clock: () => now));
      await reveal(tester, find.text('Fully refunded.'));
      expect(enabled(tester, 'Add refund'), isFalse);
    });

    testWidgets('deleting lists the refunds; Keep keeps, Delete all removes, Undo restores', (tester) async {
      final ledger = await pumpApp(
        tester,
        seed: (ledger) async {
          await refund(ledger, 30000);
          await refund(ledger, 20000);
        },
      );
      Future<void> tapDelete() async {
        await reveal(tester, find.bySemanticsLabel('Delete expense'));
        await tester.tap(find.bySemanticsLabel('Delete expense'));
        await settle(tester);
      }

      await open(tester, (context) => showExpenseSheet(context, expenseId: shoes, clock: () => now));
      await tapDelete();
      expect(find.text('Delete this expense?'), findsOneWidget);
      expect(find.text('Decathlon, ₹1,500, has 2 refunds. They will be deleted with it.'), findsOneWidget);
      expect(find.text('Refunded to Kiwi'), findsNWidgets(2));

      await tester.tap(find.text('Keep'));
      await settle(tester);
      expect(await tester.runAsync(() => ledger.getExpense(shoes)), isNotNull);

      await tapDelete();
      await tester.tap(find.text('Delete all'));
      await settle(tester);
      expect(find.text('Deleted ₹1,500 and its 2 refunds'), findsOneWidget);
      expect(await tester.runAsync(() => ledger.getExpense(shoes)), isNull);

      await tester.tap(find.text('Undo'));
      await settle(tester);
      expect(find.text('Brought back ₹1,500 and its 2 refunds'), findsOneWidget);
      expect(await tester.runAsync(() => ledger.refundedPaise(shoes)), 50000);
    });

    testWidgets('a problem saving shows on screen, above the button', (tester) async {
      await pumpApp(tester, seed: (ledger) => refund(ledger, 100000));
      await open(tester, (context) => showExpenseSheet(context, expenseId: shoes, clock: () => now));
      await tester.enterText(find.byKey(ExpenseSheet.amountFieldKey), '500');
      await tester.pumpAndSettle();
      await tester.tap(button('Save ₹500'));
      await settle(tester);
      expect(find.text('Its refunds already add up to more than that amount.').hitTestable(), findsOneWidget);
    });
  });
}
