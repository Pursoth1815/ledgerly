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
import 'package:loopd/features/accounts/presentation/account_details_sheet.dart';
import 'package:loopd/features/accounts/presentation/add_account_sheet.dart';

/// The Accounts and cards sheet on a phone-sized screen, over an in-memory database.
/// Names and digits are made up.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Future<LedgerEngine> pumpAccounts(
    WidgetTester tester, {
    Future<void> Function(LedgerEngine ledger)? seed,
    ViewAccountExpenses? onViewExpenses,
  }) async {
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
    unawaited(
      showAccountsSheet(
        tester.element(find.byType(Scaffold)),
        onViewExpenses: onViewExpenses,
        clock: () => DateTime(2026, 11, 17, 9),
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

  LoopdButton button(WidgetTester tester, String label) =>
      tester.widget<LoopdButton>(find.byWidgetPredicate((w) => w is LoopdButton && w.label == label));

  testWidgets('starts with Cash alone, and offers to add an account or card', (tester) async {
    await pumpAccounts(tester);
    expect(find.bySemanticsLabel('Accounts and cards, ₹0 spent in November'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Cash, ₹0 spent')), findsOneWidget);
    expect(find.text('Update cash'), findsNothing);
    expect(find.text('Cash in hand'), findsNothing);
    expect(find.text('+ Add account or card'), findsOneWidget);
  });

  testWidgets('adds a bank account picked from the searchable list', (tester) async {
    await pumpAccounts(tester);
    await tapText(tester, '+ Add account or card');
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
    expect(find.text('A/C •• 8124'), findsOneWidget);
    expect(find.text('Default'), findsNothing, reason: 'only when the switch is turned on');
  });

  testWidgets('finds SBI by its short name', (tester) async {
    await pumpAccounts(tester);
    await tapText(tester, '+ Add account or card');
    await tester.enterText(find.byKey(AddAccountSheet.bankFieldKey), 'sbi');
    await tester.pumpAndSettle();
    expect(find.text('State Bank of India (SBI)'), findsOneWidget);
  });

  testWidgets('the arrow and a tap outside a field put the keyboard away', (tester) async {
    await pumpAccounts(tester);
    await tapText(tester, '+ Add account or card');
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
    final ledger = await pumpAccounts(tester);
    await tapText(tester, '+ Add account or card');
    await tester.enterText(find.byKey(AddAccountSheet.bankFieldKey), 'hd');
    await tester.pumpAndSettle();
    await tester.tap(find.text('HDFC Bank'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(AddAccountSheet.last4FieldKey), '8124');
    await tester.tap(find.byType(LoopdSwitch));
    await tester.pumpAndSettle();
    await tapText(tester, 'Add account');
    final saved = (await tester.runAsync(() => ledger.watchAccounts(AccountKind.bank).first))!.single;
    expect(saved.isDefault, isTrue, reason: 'turned on by hand');
  });

  testWidgets('adds a credit card from a bank typed by hand; the nickname falls back to it', (tester) async {
    await pumpAccounts(tester);
    await tapText(tester, '+ Add account or card');
    await tester.tap(find.text('Credit card'));
    await tester.pumpAndSettle();
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
    await tapText(tester, '+ Add account or card');
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
    await tapText(tester, '+ Add account or card');
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

  Future<void> seedWallet(LedgerEngine ledger) async {
    final primary = await ledger.addAccount(
      kind: AccountKind.bank,
      name: 'Primary',
      bankName: 'Federal Bank',
      bankCode: 'FEDBNK',
      last4: '2210',
      makeDefault: true,
    );
    final kiwi = await ledger.addAccount(
      kind: AccountKind.creditCard,
      name: 'Kiwi',
      bankName: 'YES BANK',
      bankCode: 'YESBNK',
      last4: '4417',
      billDueDay: 5,
      makeDefault: true,
    );
    Future<void> spend(int rupees, String from, PaymentMethod method) => ledger.recordExpense(
      amountPaise: rupees * 100,
      method: method,
      fundingAccountId: from,
      categoryId: 'category-food',
      occurredAt: DateTime(2026, 11, 10, 13),
    );
    await spend(1500, primary, PaymentMethod.upi);
    await spend(6000, kiwi, PaymentMethod.creditCard);
    await spend(2000, kiwi, PaymentMethod.creditCard);
    await spend(500, SystemAccounts.cash, PaymentMethod.cash);
  }

  Finder card(String name) => find.bySemanticsLabel(RegExp('^$name, ₹'));

  Future<void> openCard(WidgetTester tester, String name) async {
    // Near the top: the rest of a stacked card is under the next one.
    await tester.tapAt(tester.getTopLeft(card(name)) + const Offset(120, 24));
    await tester.pumpAndSettle();
  }

  testWidgets('a toast shows at the top of the screen', (tester) async {
    await pumpAccounts(tester);
    await tapText(tester, '+ Add account or card');
    await tester.enterText(find.byKey(AddAccountSheet.bankFieldKey), 'hd');
    await tester.pumpAndSettle();
    await tester.tap(find.text('HDFC Bank'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(AddAccountSheet.last4FieldKey), '8124');
    await tester.pumpAndSettle();
    await tapText(tester, 'Add account');
    final toast = find.text('Added HDFC Bank');
    expect(tester.getTopLeft(toast).dy, lessThan(120), reason: 'under the status bar, not by the tab bar');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(toast, findsNothing, reason: 'it leaves by itself');
  });

  testWidgets('the wallet shows the month, and what each card, account and Cash spent', (tester) async {
    await pumpAccounts(tester, seed: seedWallet);
    expect(find.bySemanticsLabel('Accounts and cards, ₹10,000 spent in November'), findsOneWidget);
    expect(find.bySemanticsLabel('Kiwi, ₹8,000 spent this month, bill due 5 Dec'), findsOneWidget);
    expect(find.bySemanticsLabel('Primary, ₹1,500 spent this month'), findsOneWidget);
    expect(find.bySemanticsLabel('Cash, ₹500 spent this month'), findsOneWidget);
    expect(find.textContaining('balance'), findsNothing);
  });

  testWidgets('a card opens with its details and no other card; Back returns the stack', (tester) async {
    await pumpAccounts(tester, seed: seedWallet);
    await openCard(tester, 'Kiwi');
    expect(find.bySemanticsLabel('Spent in November, ₹8,000, 2 expenses, 80% of your spending'), findsOneWidget);
    expect(find.bySemanticsLabel('Bill due 5 Dec, 18 days left'), findsOneWidget);
    expect(find.text('View expenses'), findsOneWidget);
    expect(find.text('Card details'), findsOneWidget);
    expect(card('Primary'), findsNothing, reason: 'the others have gone');
    expect(card('Cash'), findsNothing);
    expect(find.text('+ Add account or card').hitTestable(), findsNothing);
    final top = tester.getTopLeft(card('Kiwi')).dy;
    expect(tester.getTopLeft(find.bySemanticsLabel(RegExp('^Spent in'))).dy, greaterThan(top + 176));

    await tester.tap(find.bySemanticsLabel('Back to all accounts and cards'));
    await tester.pumpAndSettle();
    expect(find.text('View expenses'), findsNothing);
    expect(card('Primary'), findsOneWidget);
    expect(card('Cash'), findsOneWidget);
  });

  testWidgets('the phone\'s back closes the open card first, then the sheet', (tester) async {
    await pumpAccounts(tester, seed: seedWallet);
    await openCard(tester, 'Primary');
    expect(find.text('Account details'), findsOneWidget);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    await navigator.maybePop();
    await tester.pumpAndSettle();
    expect(find.byType(AccountsSheet), findsOneWidget);
    expect(card('Kiwi'), findsOneWidget, reason: 'back at the stack');

    await navigator.maybePop();
    await tester.pumpAndSettle();
    expect(find.byType(AccountsSheet), findsNothing);
  });

  testWidgets('Cash has View expenses and no details, and View expenses names the account', (tester) async {
    final viewed = <String>[];
    await pumpAccounts(tester, seed: seedWallet, onViewExpenses: (_, id) async => viewed.add(id));
    await openCard(tester, 'Cash');
    expect(find.text('Account details'), findsNothing);
    expect(find.text('Card details'), findsNothing);
    await tester.tap(find.text('View expenses'));
    await tester.pumpAndSettle();
    expect(viewed, [SystemAccounts.cash]);
  });

  testWidgets('Details change the nickname, due date and default; the bank and digits stay', (tester) async {
    final ledger = await pumpAccounts(tester, seed: seedWallet);
    await openCard(tester, 'Kiwi');
    await tester.tap(find.text('Card details'));
    await tester.pumpAndSettle();
    expect(find.text('YES BANK'), findsWidgets);
    expect(button(tester, 'Save changes').onTap, isNull, reason: 'nothing changed yet');

    await tester.enterText(find.byKey(AccountDetailsSheet.nicknameKey), 'My Kiwi');
    await tester.pumpAndSettle();
    await tapText(tester, '5th of every month ›');
    await tester.tap(find.bySemanticsLabel('Day 20'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Next bill due 20 Nov'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('20th of every month ›'), findsOneWidget);
    await tester.tap(find.byType(LoopdSwitch));
    await tester.pumpAndSettle();
    await tapText(tester, 'Save changes');
    expect(find.text('Saved changes'), findsOneWidget);

    final saved = (await tester.runAsync(() => ledger.watchAccounts(AccountKind.creditCard).first))!.single;
    expect((saved.nickname, saved.billDueDay, saved.isDefault, saved.last4), ('My Kiwi', 20, false, '4417'));
    expect(find.bySemanticsLabel('Bill due 20 Nov, 3 days left'), findsOneWidget, reason: 'the open card follows');
  });

  testWidgets('removing the open account asks once, then returns to the stack', (tester) async {
    final ledger = await pumpAccounts(tester, seed: seedWallet);
    await openCard(tester, 'Primary');
    await tester.tap(find.text('Account details'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Remove account');
    expect(find.text('Remove Primary?'), findsOneWidget);
    await tapText(tester, 'Keep');
    await tapText(tester, 'Remove account');
    await tapText(tester, 'Remove');
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await tester.pumpAndSettle();
    expect(find.text('Removed Primary'), findsOneWidget);
    expect(find.text('View expenses'), findsNothing);
    expect(card('Primary'), findsNothing);
    expect(card('Kiwi'), findsOneWidget);
    expect((await tester.runAsync(() => ledger.watchAccounts(AccountKind.bank).first))!, isEmpty);
  });

  testWidgets('a new credit card can have a due date; a bank account does not offer one', (tester) async {
    final ledger = await pumpAccounts(tester);
    await tapText(tester, '+ Add account or card');
    expect(find.text('Bill due date'), findsNothing);
    await tester.tap(find.text('Credit card'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(AddAccountSheet.bankFieldKey), 'YES');
    await tester.pumpAndSettle();
    await tester.tap(find.text('YES BANK').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(AddAccountSheet.nicknameFieldKey), 'Kiwi');
    await tester.enterText(find.byKey(AddAccountSheet.last4FieldKey), '4417');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tapText(tester, 'Optional ›');
    await tester.tap(find.bySemanticsLabel('Day 5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Add card');
    final saved = (await tester.runAsync(() => ledger.watchAccounts(AccountKind.creditCard).first))!.single;
    expect(saved.billDueDay, 5);
  });
}
