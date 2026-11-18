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
import 'package:loopd/design_system/components/loopd_switch.dart';
import 'package:loopd/design_system/loopd_theme.dart';
import 'package:loopd/features/accounts/accounts.dart';
import 'package:loopd/features/accounts/presentation/add_account_sheet.dart';
import 'package:loopd/features/accounts/presentation/update_count_sheet.dart';

/// The Accounts and cards sheet on a phone-sized screen, over an in-memory database.
/// Names and digits are made up.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Future<LedgerEngine> pumpAccounts(WidgetTester tester, {Future<void> Function(LedgerEngine ledger)? seed}) async {
    final database = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    addTearDown(database.close);
    final ledger = LedgerEngine(database);
    await ledger.ensureDefaults();
    await seed?.call(ledger);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: MaterialApp(theme: loopdTheme(Brightness.dark), home: const Scaffold()),
      ),
    );
    unawaited(showAccountsSheet(tester.element(find.byType(Scaffold)), clock: () => DateTime(2026, 11, 17, 9)));
    await tester.pumpAndSettle();
    return ledger;
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  LoopdButton button(WidgetTester tester, String label) =>
      tester.widget<LoopdButton>(find.byWidgetPredicate((w) => w is LoopdButton && w.label == label));

  testWidgets('starts with Cash in hand not counted and nothing added', (tester) async {
    await pumpAccounts(tester);
    expect(find.text('Accounts and cards'), findsOneWidget);
    expect(find.text('₹0'), findsOneWidget, reason: 'Cash in hand starts at ₹0');
    expect(find.text('Count your wallet to set it'), findsOneWidget);
    expect(find.text('₹0 in Nov'), findsOneWidget, reason: 'cash spending this month');
    expect(find.text('+ Add bank account'), findsOneWidget);
    expect(find.text('+ Add credit card'), findsOneWidget);
  });

  testWidgets('adds a bank account picked from the searchable list', (tester) async {
    await pumpAccounts(tester);
    await tapText(tester, '+ Add bank account');
    expect(find.text('Add bank account'), findsOneWidget);
    expect(button(tester, 'Add account').onTap, isNull, reason: 'no bank or digits yet');

    await tester.enterText(find.byKey(AddAccountSheet.bankFieldKey), 'hd');
    await tester.pumpAndSettle();
    expect(find.text('HDFC Bank'), findsOneWidget);
    expect(find.text('HDFC Bank Credit Cards'), findsNothing, reason: 'listed only for cards');
    await tester.tap(find.text('HDFC Bank'));
    await tester.pumpAndSettle();
    expect(find.text('SMS from HDFCBK will be linked here, whatever the prefix.'), findsOneWidget);

    await tester.enterText(find.byKey(AddAccountSheet.nicknameFieldKey), 'Savings');
    await tester.enterText(find.byKey(AddAccountSheet.last4FieldKey), '81x24');
    await tester.pumpAndSettle();
    expect(find.text('•••• 8124'), findsOneWidget, reason: 'the preview shows digits only');
    await tapText(tester, 'Add account');

    expect(find.text('Added Savings'), findsOneWidget);
    expect(find.text('Savings'), findsOneWidget);
    expect(find.text('HDFC Bank ••8124'), findsOneWidget);
    expect(find.text('Default'), findsNothing, reason: 'only when the switch is turned on');
  });

  testWidgets('finds SBI by its short name', (tester) async {
    await pumpAccounts(tester);
    await tapText(tester, '+ Add bank account');
    await tester.enterText(find.byKey(AddAccountSheet.bankFieldKey), 'sbi');
    await tester.pumpAndSettle();
    expect(find.text('State Bank of India (SBI)'), findsOneWidget);
  });

  testWidgets('the arrow and a tap outside a field put the keyboard away', (tester) async {
    await pumpAccounts(tester);
    await tapText(tester, '+ Add bank account');
    bool focused(Key key) => tester
        .widget<EditableText>(find.descendant(of: find.byKey(key), matching: find.byType(EditableText)))
        .focusNode
        .hasFocus;

    await tester.tap(find.byKey(AddAccountSheet.bankFieldKey));
    await tester.pumpAndSettle();
    expect(focused(AddAccountSheet.bankFieldKey), isTrue);
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pumpAndSettle();
    expect(focused(AddAccountSheet.bankFieldKey), isFalse, reason: 'the arrow closes the keyboard');

    await tester.tap(find.byKey(AddAccountSheet.nicknameFieldKey));
    await tester.pumpAndSettle();
    expect(focused(AddAccountSheet.nicknameFieldKey), isTrue);
    await tester.tap(find.text('Bank'));
    await tester.pumpAndSettle();
    expect(focused(AddAccountSheet.nicknameFieldKey), isFalse, reason: 'a tap outside the field closes it');
  });

  testWidgets('the default switch starts off, even for the first account', (tester) async {
    await pumpAccounts(tester);
    await tapText(tester, '+ Add bank account');
    await tester.enterText(find.byKey(AddAccountSheet.bankFieldKey), 'hd');
    await tester.pumpAndSettle();
    await tester.tap(find.text('HDFC Bank'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(AddAccountSheet.last4FieldKey), '8124');
    await tester.tap(find.byType(LoopdSwitch));
    await tester.pumpAndSettle();
    await tapText(tester, 'Add account');
    expect(find.text('Default'), findsOneWidget, reason: 'turned on by hand');
  });

  testWidgets('adds a credit card from a bank typed by hand; the nickname falls back to it', (tester) async {
    await pumpAccounts(tester);
    await tapText(tester, '+ Add credit card');
    expect(find.text('Add credit card'), findsWidgets);

    await tester.enterText(find.byKey(AddAccountSheet.bankFieldKey), 'Zeta Bank');
    await tester.pumpAndSettle();
    await tapText(tester, 'Add “Zeta Bank” as a new bank');
    expect(
      find.text('This bank is not in the list yet, so its SMS are not linked. You can still add its expenses by hand.'),
      findsOneWidget,
    );
    await tester.enterText(find.byKey(AddAccountSheet.last4FieldKey), '1234');
    await tester.pumpAndSettle();
    await tapText(tester, 'Add card');

    expect(find.text('Added Zeta Bank'), findsOneWidget);
    expect(find.text('•••• 1234'), findsOneWidget);
  });

  testWidgets('the type switch turns the sheet into the other kind', (tester) async {
    await pumpAccounts(tester);
    await tapText(tester, '+ Add bank account');
    await tester.tap(find.text('Credit card'));
    await tester.pumpAndSettle();
    expect(find.text('Add credit card'), findsOneWidget);
    expect(find.text('Default credit card'), findsOneWidget);
  });

  testWidgets('digits already saved are flagged as you type, for each kind apart', (tester) async {
    await pumpAccounts(
      tester,
      seed: (ledger) => ledger.addAccount(
        kind: AccountKind.bank,
        name: 'Primary',
        bankName: 'Federal Bank',
        bankCode: 'FEDBNK',
        last4: '2210',
      ),
    );
    await tapText(tester, '+ Add bank account');
    await tester.enterText(find.byKey(AddAccountSheet.bankFieldKey), 'hd');
    await tester.pumpAndSettle();
    await tester.tap(find.text('HDFC Bank'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(AddAccountSheet.last4FieldKey), '2210');
    await tester.pumpAndSettle();
    const taken = 'Primary already ends ••2210. Each bank account needs its own last four digits.';
    expect(find.text(taken), findsOneWidget, reason: 'another bank, the same digits');
    expect(button(tester, 'Add account').onTap, isNull);

    await tester.enterText(find.byKey(AddAccountSheet.last4FieldKey), '2211');
    await tester.pumpAndSettle();
    expect(find.text(taken), findsNothing);
    expect(button(tester, 'Add account').onTap, isNotNull);

    await tester.enterText(find.byKey(AddAccountSheet.last4FieldKey), '2210');
    await tester.tap(find.text('Credit card'));
    await tester.pumpAndSettle();
    expect(find.textContaining('already ends'), findsNothing, reason: 'cards are checked apart from bank accounts');
    expect(button(tester, 'Add card').onTap, isNotNull);
  });

  testWidgets('a toast shows at the top of the screen', (tester) async {
    await pumpAccounts(tester);
    await tapText(tester, 'Update count');
    await tester.enterText(find.byKey(UpdateCountSheet.amountFieldKey), '500');
    await tester.pumpAndSettle();
    await tapText(tester, 'Save count');
    final toast = find.text('Cash in hand is now ₹500');
    expect(toast, findsOneWidget);
    expect(tester.getTopLeft(toast).dy, lessThan(120), reason: 'under the status bar, not by the tab bar');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(toast, findsNothing, reason: 'it leaves by itself');
  });

  testWidgets('Update count sets Cash in hand, and a new count replaces it', (tester) async {
    await pumpAccounts(tester);
    await tapText(tester, 'Update count');
    expect(find.text('Loopd has ₹0 now. Your count replaces it.'), findsOneWidget);
    await tester.enterText(find.byKey(UpdateCountSheet.amountFieldKey), '2,350');
    await tester.pumpAndSettle();
    await tapText(tester, 'Save count');
    expect(find.text('Cash in hand is now ₹2,350'), findsOneWidget);
    expect(find.text('₹2,350'), findsOneWidget);

    await tapText(tester, 'Update count');
    await tester.enterText(find.byKey(UpdateCountSheet.amountFieldKey), '2200');
    await tester.pumpAndSettle();
    expect(
      find.text('₹150 less than Loopd has. Your count replaces it; the difference is not spending.'),
      findsOneWidget,
    );
    await tapText(tester, 'Save count');
    expect(find.text('₹2,200'), findsOneWidget);
    expect(find.text('₹0 in Nov'), findsOneWidget, reason: 'a count is not spending');
  });

  testWidgets('shows this month\'s spending for each account and section', (tester) async {
    await pumpAccounts(
      tester,
      seed: (ledger) async {
        final primary = await ledger.addAccount(kind: AccountKind.bank, name: 'Primary', last4: '2210');
        await ledger.recordExpense(
          amountPaise: 183000,
          method: PaymentMethod.upi,
          fundingAccountId: primary,
          categoryId: 'category-food',
          occurredAt: DateTime(2026, 11, 10, 13),
        );
      },
    );
    expect(find.text('₹1,830 in Nov'), findsOneWidget);
    expect(find.text('₹1,830'), findsOneWidget);
  });

  testWidgets('an account can become the default, or be removed', (tester) async {
    await pumpAccounts(
      tester,
      seed: (ledger) async {
        await ledger.addAccount(
          kind: AccountKind.bank,
          name: 'Primary',
          bankName: 'Federal Bank',
          last4: '2210',
          makeDefault: true,
        );
        await ledger.addAccount(kind: AccountKind.bank, name: 'Savings', bankName: 'HDFC Bank', last4: '8124');
      },
    );
    await tapText(tester, 'Savings');
    expect(find.text('Default'), findsOneWidget, reason: 'only Primary so far');
    await tapText(tester, 'Make default for UPI');
    expect(find.text('Savings is now the default for UPI'), findsOneWidget);

    await tapText(tester, 'Primary');
    expect(find.text('Make default for UPI'), findsOneWidget);
    await tapText(tester, 'Remove');
    expect(find.text('Remove Primary?'), findsOneWidget);
    await tapText(tester, 'Remove');
    expect(find.text('Removed Primary'), findsOneWidget);
    expect(find.text('Federal Bank ••2210'), findsNothing);
    expect(find.text('Savings'), findsOneWidget);
  });
}
