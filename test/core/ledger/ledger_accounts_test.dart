import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/core/database/app_database.dart';
import 'package:loopd/core/errors/app_exception.dart';
import 'package:loopd/core/ledger/ledger_engine.dart';
import 'package:loopd/core/ledger/ledger_types.dart';

/// Accounts and cards, and the live reads behind their screen (proposal
/// section 4). Amounts are in paise: ₹62 is 6200. Names and digits are made up.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late LedgerEngine ledger;
  var now = DateTime.utc(2026, 11, 17, 12);
  const food = 'category-food';
  const cash = SystemAccounts.cash;

  Matcher fails(LedgerFailure failure) => throwsA(isA<LedgerException>().having((e) => e.failure, 'failure', failure));

  setUp(() async {
    now = DateTime.utc(2026, 11, 17, 12);
    db = AppDatabase(NativeDatabase.memory());
    ledger = LedgerEngine(db, clock: () => now);
    await ledger.ensureDefaults();
  });
  tearDown(() async {
    expect(await ledger.healthCheck(), isEmpty);
    await db.close();
  });

  Future<String> bank(String name, String last4, {String bankName = 'Federal Bank', bool makeDefault = false}) {
    // Each account a moment later, so "oldest" is well defined.
    now = now.add(const Duration(seconds: 1));
    return ledger.addAccount(
      kind: AccountKind.bank,
      name: name,
      bankName: bankName,
      bankCode: 'FEDBNK',
      last4: last4,
      makeDefault: makeDefault,
    );
  }

  Future<List<LedgerAccount>> banks() => ledger.watchAccounts(AccountKind.bank).first;

  group('adding', () {
    test('keeps the bank name and the trimmed nickname; nothing is the default by itself', () async {
      await bank('  Primary ', '1111');
      await bank('Savings', '2222', bankName: 'HDFC Bank');
      final list = await banks();
      expect(list.map((a) => a.nickname), ['Primary', 'Savings']);
      expect(list.map((a) => a.bankName), ['Federal Bank', 'HDFC Bank']);
      expect(list.map((a) => a.isDefault), [false, false], reason: 'not even the first one');
    });

    test('a new default replaces the old one', () async {
      await bank('Primary', '1111', makeDefault: true);
      await bank('Salary', '3333', makeDefault: true);
      expect((await banks()).map((a) => a.isDefault), [false, true]);
    });

    test('needs a nickname and exactly four digits', () async {
      await expectLater(bank(' ', '1111'), fails(LedgerFailure.invalidAccount));
      await expectLater(bank('Primary', '111'), fails(LedgerFailure.invalidAccount));
      await expectLater(bank('Primary', '11a1'), fails(LedgerFailure.invalidAccount));
      await expectLater(
        ledger.addAccount(kind: AccountKind.cash, name: 'Wallet'),
        fails(LedgerFailure.invalidAccount),
        reason: 'there is only one Cash in hand',
      );
    });

    test('the same four digits cannot be saved twice for one kind, whatever the bank', () async {
      await bank('Primary', '1111');
      await expectLater(bank('Again', '1111', bankName: 'federal bank'), fails(LedgerFailure.duplicateAccount));
      await expectLater(bank('Other', '1111', bankName: 'HDFC Bank'), fails(LedgerFailure.duplicateAccount));
      // Bank accounts and cards are checked apart: a card may share them.
      await ledger.addAccount(kind: AccountKind.creditCard, name: 'Card', bankName: 'Federal Bank', last4: '1111');
      await expectLater(
        ledger.addAccount(kind: AccountKind.creditCard, name: 'Card 2', bankName: 'HDFC Bank', last4: '1111'),
        fails(LedgerFailure.duplicateAccount),
      );
      expect(await banks(), hasLength(1));
    });

    test('a removed account frees its digits', () async {
      final primary = await bank('Primary', '1111');
      await ledger.removeAccount(primary);
      await bank('Primary', '1111');
      expect(await banks(), hasLength(1));
    });
  });

  group('default and remove', () {
    test('removing the default leaves none until you choose one', () async {
      final primary = await bank('Primary', '1111', makeDefault: true);
      await bank('Savings', '2222');
      await bank('Salary', '3333');
      await ledger.removeAccount(primary);
      final list = await banks();
      expect(list.map((a) => a.nickname), ['Savings', 'Salary']);
      expect(list.map((a) => a.isDefault), [false, false]);
    });

    test('removing another account leaves the default alone', () async {
      await bank('Primary', '1111', makeDefault: true);
      final savings = await bank('Savings', '2222');
      await ledger.removeAccount(savings);
      expect((await banks()).single.isDefault, isTrue);
    });

    test('a removed account cannot become the default', () async {
      await bank('Primary', '1111');
      final savings = await bank('Savings', '2222');
      await ledger.removeAccount(savings);
      await expectLater(ledger.setDefault(savings), fails(LedgerFailure.accountRemoved));
    });

    test('the list follows changes as they happen', () async {
      final updates = ledger.watchAccounts(AccountKind.bank).map((list) => list.length);
      final seen = <int>[];
      final subscription = updates.listen(seen.add);
      await pumpEventQueue();
      final primary = await bank('Primary', '1111');
      await pumpEventQueue();
      await ledger.removeAccount(primary);
      await pumpEventQueue();
      await subscription.cancel();
      expect(seen, [0, 1, 0]);
    });
  });

  group('spending this month', () {
    test('counts each funding account, net of refunds, in the purchase month only', () async {
      final primary = await bank('Primary', '1111');
      final kiwi = await ledger.addAccount(kind: AccountKind.creditCard, name: 'Kiwi', last4: '4444');
      Future<String> spend(int paise, String from, PaymentMethod method, DateTime at) => ledger.recordExpense(
        amountPaise: paise,
        method: method,
        fundingAccountId: from,
        categoryId: food,
        occurredAt: at,
      );
      final nov = DateTime(2026, 11, 10, 12);
      await spend(25000, primary, PaymentMethod.upi, nov);
      await spend(12000, primary, PaymentMethod.upi, DateTime(2026, 10, 31, 12)); // October
      final shoes = await spend(99900, kiwi, PaymentMethod.creditCard, nov);
      await spend(4000, cash, PaymentMethod.cash, nov);
      final deleted = await spend(5000, cash, PaymentMethod.cash, nov);
      await ledger.delete(deleted);
      // Refunded in December, it still lowers November (purchase month).
      await ledger.recordRefund(
        originalId: shoes,
        amountPaise: 30000,
        method: PaymentMethod.creditCard,
        destinationAccountId: kiwi,
        occurredAt: DateTime(2026, 12, 2, 12),
      );
      // A transfer into cash is not spending.
      await ledger.recordTransfer(amountPaise: 200000, fromAccountId: primary, toAccountId: cash, occurredAt: nov);

      expect(await ledger.watchMonthSpending(DateTime(2026, 11)).first, {primary: 25000, kiwi: 69900, cash: 4000});
      expect(await ledger.watchMonthSpending(DateTime(2026, 10)).first, {primary: 12000});
      expect(await ledger.watchMonthSpending(DateTime(2026, 12)).first, isEmpty);
    });

    test('December rolls over into January', () async {
      final primary = await bank('Primary', '1111');
      await ledger.recordExpense(
        amountPaise: 100,
        method: PaymentMethod.upi,
        fundingAccountId: primary,
        categoryId: food,
        occurredAt: DateTime(2026, 12, 31, 20),
      );
      expect(await ledger.watchMonthSpending(DateTime(2026, 12)).first, {primary: 100});
      expect(await ledger.watchMonthSpending(DateTime(2027)).first, isEmpty);
    });
  });

  group('Cash in hand', () {
    test('starts at ₹0, not counted', () async {
      final summary = await ledger.watchCashInHand().first;
      expect(summary.balance.paise, 0);
      expect(summary.lastCountAt, isNull);
      expect(summary.lastInAt, isNull);
    });

    test('follows each count as it is saved', () async {
      final seen = <int>[];
      final subscription = ledger.watchCashInHand().listen((summary) => seen.add(summary.balance.paise));
      await pumpEventQueue();
      await ledger.countCash(35000);
      await pumpEventQueue();
      now = now.add(const Duration(minutes: 1));
      await ledger.countCash(20000);
      await pumpEventQueue();
      await subscription.cancel();
      expect(seen, [0, 35000, 20000]);
    });

    test('shows the count, then the latest ATM withdrawal', () async {
      final primary = await bank('Primary', '1111');
      await ledger.countCash(35000);
      var summary = await ledger.watchCashInHand().first;
      expect(summary.balance.paise, 35000);
      expect(summary.lastCountAt, now);

      final atm = now.add(const Duration(hours: 2));
      await ledger.recordTransfer(amountPaise: 200000, fromAccountId: primary, toAccountId: cash, occurredAt: atm);
      summary = await ledger.watchCashInHand().first;
      expect(summary.balance.paise, 235000);
      expect(summary.lastInPaise, 200000);
      expect(summary.lastInAt, atm);
    });
  });

  group('card bill due date (part 8b)', () {
    LedgerAccount cardDue(int? day) =>
        LedgerAccount(id: 'c', kind: AccountKind.creditCard, nickname: 'Kiwi', isDefault: false, billDueDay: day);

    test('the next due date is this month, today included, or next month', () {
      final mid = DateTime(2026, 11, 15, 10);
      expect(cardDue(null).nextBillDue(mid), isNull);
      expect(cardDue(20).nextBillDue(mid), DateTime(2026, 11, 20));
      expect(cardDue(15).nextBillDue(mid), DateTime(2026, 11, 15), reason: 'due today is still due');
      expect(cardDue(5).nextBillDue(mid), DateTime(2026, 12, 5));
    });

    test('a shorter month uses its last day, and December rolls into January', () {
      expect(cardDue(31).nextBillDue(DateTime(2026, 11, 15)), DateTime(2026, 11, 30));
      expect(cardDue(31).nextBillDue(DateTime(2027, 2, 10)), DateTime(2027, 2, 28));
      expect(cardDue(30).nextBillDue(DateTime(2028, 2, 29)), DateTime(2028, 2, 29), reason: 'a leap year');
      expect(cardDue(5).nextBillDue(DateTime(2026, 12, 20)), DateTime(2027, 1, 5));
    });

    test('Account details save the nickname, default and due day; only a card has one, from 1 to 31', () async {
      final kiwi = await ledger.addAccount(kind: AccountKind.creditCard, name: 'Kiwi', last4: '4417', billDueDay: 5);
      final other = await ledger.addAccount(
        kind: AccountKind.creditCard,
        name: 'Other',
        last4: '7781',
        makeDefault: true,
      );
      expect((await ledger.getAccount(kiwi))!.billDueDay, 5);

      await ledger.saveAccountDetails(kiwi, nickname: '  My Kiwi ', isDefault: true, billDueDay: 31);
      final saved = (await ledger.getAccount(kiwi))!;
      expect((saved.nickname, saved.isDefault, saved.billDueDay, saved.last4), ('My Kiwi', true, 31, '4417'));
      expect((await ledger.getAccount(other))!.isDefault, isFalse, reason: 'one default of each kind');

      await ledger.saveAccountDetails(kiwi, nickname: 'My Kiwi', isDefault: false);
      final cleared = (await ledger.getAccount(kiwi))!;
      expect((cleared.isDefault, cleared.billDueDay), (false, null));

      await expectLater(
        ledger.saveAccountDetails(kiwi, nickname: 'Kiwi', isDefault: false, billDueDay: 0),
        fails(LedgerFailure.invalidAccount),
      );
      await expectLater(
        ledger.saveAccountDetails(kiwi, nickname: 'Kiwi', isDefault: false, billDueDay: 32),
        fails(LedgerFailure.invalidAccount),
      );
      await expectLater(
        ledger.saveAccountDetails(kiwi, nickname: '   ', isDefault: false),
        fails(LedgerFailure.invalidAccount),
      );
      final primary = await bank('Primary', '2210');
      await expectLater(
        ledger.saveAccountDetails(primary, nickname: 'Primary', isDefault: false, billDueDay: 5),
        fails(LedgerFailure.invalidAccount),
      );
      await expectLater(
        ledger.addAccount(kind: AccountKind.bank, name: 'Savings', last4: '8124', billDueDay: 5),
        fails(LedgerFailure.invalidAccount),
      );
    });
  });
}
