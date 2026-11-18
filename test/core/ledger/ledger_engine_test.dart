import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/core/database/app_database.dart';
import 'package:loopd/core/errors/app_exception.dart';
import 'package:loopd/core/ledger/ledger_engine.dart';
import 'package:loopd/core/ledger/ledger_types.dart';

/// The money rules from proposal section 4 and ADR 0006, one test each.
/// Amounts are in paise: ₹62 is 6200.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late LedgerEngine ledger;
  late String primary; // a bank account used for UPI
  late String savings;
  late String kiwi; // a credit card
  const food = 'category-food';
  const shopping = 'category-shopping';
  const travel = 'category-travel';
  const cash = SystemAccounts.cash;
  final nov = DateTime.utc(2026, 11, 10, 6);

  Matcher fails(LedgerFailure failure) => throwsA(isA<LedgerException>().having((e) => e.failure, 'failure', failure));
  Future<int> balance(String id) async => (await ledger.balanceOf(id)).paise;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    ledger = LedgerEngine(db, clock: () => DateTime.utc(2026, 11, 17, 12));
    await ledger.ensureDefaults();
    primary = await ledger.addAccount(kind: AccountKind.bank, name: 'Primary', bankCode: 'FEDBNK', last4: '1111');
    savings = await ledger.addAccount(kind: AccountKind.bank, name: 'Savings', bankCode: 'HDFCBK', last4: '2222');
    kiwi = await ledger.addAccount(kind: AccountKind.creditCard, name: 'Kiwi', bankCode: 'YESBNK', last4: '3333');
  });
  tearDown(() async {
    expect(await ledger.healthCheck(), isEmpty, reason: 'every test must leave the ledger healthy');
    await db.close();
  });

  Future<String> spend(
    int paise, {
    String from = '',
    PaymentMethod method = PaymentMethod.upi,
    String category = food,
  }) => ledger.recordExpense(
    amountPaise: paise,
    method: method,
    fundingAccountId: from.isEmpty ? primary : from,
    categoryId: category,
    occurredAt: nov,
  );

  group('set-up', () {
    test('every install has Cash in hand and the twelve default categories, once', () async {
      await ledger.ensureDefaults();
      final categories = await db.select(db.categories).get();
      expect(categories, hasLength(12));
      final names = await (db.select(db.accounts)..where((a) => a.kind.equals('category'))).map((a) => a.name).get();
      expect(
        names,
        containsAll([
          'Food',
          'Snacks',
          'Groceries',
          'Travel',
          'Shopping',
          'Bills',
          'Health',
          'Fuel',
          'Fun',
          'Rent',
          'Subscriptions',
          'Gifts',
        ]),
      );
      expect((await (db.select(db.accounts)..where((a) => a.id.equals(cash))).getSingle()).name, 'Cash in hand');
    });

    test('nothing is a default until chosen; one default per kind', () async {
      final accounts = {for (final a in await db.select(db.accounts).get()) a.id: a};
      expect([primary, savings, kiwi].map((id) => accounts[id]!.isDefault), [false, false, false]);
      await ledger.setDefault(primary);
      await ledger.setDefault(kiwi);
      await ledger.setDefault(savings);
      final after = {for (final a in await db.select(db.accounts).get()) a.id: a};
      expect(after[primary]!.isDefault, isFalse);
      expect(after[savings]!.isDefault, isTrue);
      expect(after[kiwi]!.isDefault, isTrue, reason: 'the card default is separate');
    });

    test('a removed account keeps its past transactions but takes no new ones', () async {
      await spend(6200, from: savings);
      await ledger.removeAccount(savings);
      expect(await balance(savings), -6200);
      expect(() => spend(100, from: savings), fails(LedgerFailure.accountRemoved));
    });

    test('Cash in hand and the bookkeeping accounts cannot be removed', () async {
      expect(() => ledger.removeAccount(cash), fails(LedgerFailure.systemAccount));
    });
  });

  group('spending', () {
    test('₹62 by UPI: Snacks +6200, Primary −6200', () async {
      await spend(6200);
      expect(await balance(food), 6200);
      expect(await balance(primary), -6200);
    });

    test('a card paid by UPI QR is a Credit Card expense', () async {
      final id = await ledger.recordExpense(
        amountPaise: 70500,
        method: PaymentMethod.creditCard,
        channel: 'upi_qr',
        fundingAccountId: kiwi,
        categoryId: travel,
        occurredAt: nov,
      );
      expect(await balance(kiwi), -70500, reason: 'owed on the card');
      final row = await (db.select(db.ledgerTransactions)..where((t) => t.id.equals(id))).getSingle();
      expect((row.paymentMethod, row.channel), ('credit_card', 'upi_qr'));
    });

    test('a cash expense lowers Cash in hand', () async {
      await spend(4000, from: cash, method: PaymentMethod.cash);
      expect(await balance(cash), -4000);
    });

    test('the method must fit: UPI cannot be paid from a card', () async {
      expect(() => spend(100, from: kiwi), fails(LedgerFailure.methodMismatch));
    });

    test('amounts must be positive', () async {
      expect(() => spend(0), fails(LedgerFailure.invalidAmount));
      expect(() => spend(-5), fails(LedgerFailure.invalidAmount));
    });
  });

  group('not spending', () {
    test('paying the card bill is a settlement, not spending', () async {
      await spend(129900, from: kiwi, method: PaymentMethod.creditCard, category: shopping);
      await ledger.recordCardPayment(amountPaise: 129900, fromBankId: savings, cardId: kiwi, occurredAt: nov);
      expect(await balance(kiwi), 0);
      expect(await balance(savings), -129900);
      expect(await balance(shopping), 129900, reason: 'spending counted once, at purchase');
    });

    test('an ATM withdrawal moves money to Cash in hand and is not spending', () async {
      await ledger.recordTransfer(amountPaise: 200000, fromAccountId: savings, toAccountId: cash, occurredAt: nov);
      expect(await balance(cash), 200000);
      expect(await balance(savings), -200000);
      for (final category in [food, shopping, travel]) {
        expect(await balance(category), 0);
      }
    });

    test('salary is income against the bank account, never spending', () async {
      await ledger.recordIncome(amountPaise: 6000000, toAccountId: savings, occurredAt: nov, source: 'Salary');
      expect(await balance(savings), 6000000);
      expect(await balance(SystemAccounts.income), -6000000);
    });

    test('a transfer to the same account is refused', () async {
      expect(
        () => ledger.recordTransfer(amountPaise: 100, fromAccountId: savings, toAccountId: savings, occurredAt: nov),
        fails(LedgerFailure.wrongShape),
      );
    });
  });

  group('refunds', () {
    test('a refund reduces the original category', () async {
      final order = await spend(129900, from: kiwi, method: PaymentMethod.creditCard, category: shopping);
      await ledger.recordRefund(
        originalId: order,
        amountPaise: 30000,
        method: PaymentMethod.creditCard,
        destinationAccountId: kiwi,
        occurredAt: nov,
      );
      expect(await balance(shopping), 99900);
      expect(await balance(kiwi), -99900);
    });

    test('refunded to a bank: spending falls, but the card still owes', () async {
      final order = await spend(129900, from: kiwi, method: PaymentMethod.creditCard, category: shopping);
      await ledger.recordRefund(
        originalId: order,
        amountPaise: 129900,
        method: PaymentMethod.upi,
        destinationAccountId: savings,
        occurredAt: nov,
      );
      expect(await balance(shopping), 0);
      expect(await balance(savings), 129900);
      expect(await balance(kiwi), -129900, reason: 'the card bill is still owed');
    });

    test('refunds can never add up to more than the original', () async {
      final order = await spend(10000);
      await ledger.recordRefund(
        originalId: order,
        amountPaise: 6000,
        method: PaymentMethod.upi,
        destinationAccountId: primary,
        occurredAt: nov,
      );
      expect(
        () => ledger.recordRefund(
          originalId: order,
          amountPaise: 4001,
          method: PaymentMethod.upi,
          destinationAccountId: primary,
          occurredAt: nov,
        ),
        fails(LedgerFailure.refundExceedsOriginal),
      );
    });

    test('an edit cannot lower a purchase below what was refunded', () async {
      final order = await spend(10000);
      await ledger.recordRefund(
        originalId: order,
        amountPaise: 6000,
        method: PaymentMethod.upi,
        destinationAccountId: primary,
        occurredAt: nov,
      );
      expect(
        () => ledger.editExpense(
          order,
          amountPaise: 5000,
          method: PaymentMethod.upi,
          fundingAccountId: primary,
          categoryId: food,
          occurredAt: nov,
        ),
        fails(LedgerFailure.refundExceedsOriginal),
      );
    });

    test('a refund needs a live original purchase', () async {
      final order = await spend(10000);
      await ledger.delete(order);
      expect(
        () => ledger.recordRefund(
          originalId: order,
          amountPaise: 100,
          method: PaymentMethod.upi,
          destinationAccountId: primary,
          occurredAt: nov,
        ),
        fails(LedgerFailure.refundWithoutOriginal),
      );
    });
  });

  group('edits, deletes and undo', () {
    test('an edit keeps the id, replaces the postings and adds a revision', () async {
      final id = await spend(6200);
      await ledger.editExpense(
        id,
        amountPaise: 8000,
        method: PaymentMethod.creditCard,
        fundingAccountId: kiwi,
        categoryId: travel,
        occurredAt: nov,
      );
      expect(await balance(primary), 0);
      expect(await balance(kiwi), -8000);
      expect(await balance(food), 0);
      expect(await balance(travel), 8000);
      final revisions = await (db.select(db.transactionRevisions)..where((r) => r.transactionId.equals(id))).get();
      expect(revisions.map((r) => r.action), ['create', 'edit']);
    });

    test('undo restores the previous version, as a new revision', () async {
      final id = await spend(6200);
      await ledger.editExpense(
        id,
        amountPaise: 8000,
        method: PaymentMethod.upi,
        fundingAccountId: primary,
        categoryId: travel,
        occurredAt: nov,
      );
      await ledger.undo(id, expectedRevision: 2);
      expect(await balance(food), 6200);
      expect(await balance(travel), 0);
      final row = await (db.select(db.ledgerTransactions)..where((t) => t.id.equals(id))).getSingle();
      expect(row.revision, 3);
    });

    test('undo is refused when something changed since', () async {
      final id = await spend(6200);
      await ledger.editExpense(
        id,
        amountPaise: 8000,
        method: PaymentMethod.upi,
        fundingAccountId: primary,
        categoryId: food,
        occurredAt: nov,
      );
      expect(() => ledger.undo(id, expectedRevision: 1), fails(LedgerFailure.changedSince));
    });

    test('a delete is soft and can be undone', () async {
      final id = await spend(6200);
      await ledger.delete(id);
      expect(await balance(food), 0);
      expect(await (db.select(db.ledgerTransactions)..where((t) => t.id.equals(id))).getSingleOrNull(), isNotNull);
      await ledger.undo(id, expectedRevision: 2);
      expect(await balance(food), 6200);
    });

    test('undoing a new expense removes it again', () async {
      final id = await spend(6200);
      await ledger.undo(id, expectedRevision: 1);
      expect(await balance(food), 0);
    });

    test('a purchase with refunds is deleted only together with them', () async {
      final order = await spend(10000);
      await ledger.recordRefund(
        originalId: order,
        amountPaise: 4000,
        method: PaymentMethod.upi,
        destinationAccountId: primary,
        occurredAt: nov,
      );
      expect(() => ledger.delete(order), fails(LedgerFailure.hasLiveRefunds));
      await ledger.delete(order, withRefunds: true);
      expect(await balance(food), 0);
      expect(await balance(primary), 0);
    });
  });

  group('Cash in hand and balances', () {
    test('each Update count sets Cash in hand; a new count replaces the last', () async {
      expect(await balance(cash), 0, reason: 'Cash in hand starts at ₹0');
      await ledger.countCash(250000);
      expect(await balance(cash), 250000);
      // Spent after the count (the clock says 17 Nov, 12:00), so it lowers it.
      await ledger.recordExpense(
        amountPaise: 4000,
        method: PaymentMethod.cash,
        fundingAccountId: cash,
        categoryId: food,
        occurredAt: DateTime.utc(2026, 11, 17, 13),
      );
      expect(await balance(cash), 246000);
      await ledger.countCash(240000, at: DateTime.utc(2026, 11, 17, 14));
      expect(await balance(cash), 240000, reason: 'the new count replaces it');
      expect(await balance(food), 4000, reason: 'the ₹60 gap is not spending');
      expect(await balance(SystemAccounts.adjustment), 0, reason: 'a count writes no money row');
      await ledger.countCash(0, at: DateTime.utc(2026, 11, 17, 15));
      expect(await balance(cash), 0, reason: 'an empty wallet is a valid count');
    });

    test('what is dated before the count is already in it, even when recorded later', () async {
      await ledger.countCash(50000, at: DateTime.utc(2026, 11, 17, 12));
      // The ATM SMS is read after the count (the phone froze Loopd).
      await ledger.recordTransfer(
        amountPaise: 200000,
        fromAccountId: savings,
        toAccountId: cash,
        occurredAt: DateTime.utc(2026, 11, 17, 10),
      );
      expect(await balance(cash), 50000, reason: 'the counted cash already held it');
      expect(await balance(savings), -200000, reason: 'the bank side still moves');
      await ledger.recordTransfer(
        amountPaise: 100000,
        fromAccountId: savings,
        toAccountId: cash,
        occurredAt: DateTime.utc(2026, 11, 17, 18),
      );
      expect(await balance(cash), 150000, reason: 'a withdrawal after the count adds to it');
    });

    test('with an opening balance, older history does not count twice', () async {
      await spend(5000, from: savings);
      final asOf = DateTime.utc(2026, 11, 12);
      await ledger.setOpeningBalance(savings, 1000000, asOf: asOf);
      await ledger.recordExpense(
        amountPaise: 2000,
        method: PaymentMethod.upi,
        fundingAccountId: savings,
        categoryId: food,
        occurredAt: DateTime.utc(2026, 11, 13),
      );
      final b = await ledger.balanceOf(savings);
      expect(b.hasOpening, isTrue);
      expect(b.paise, 998000);
    });

    test('without an opening balance, the figure is only movement since tracking began', () async {
      await spend(5000, from: savings);
      final b = await ledger.balanceOf(savings);
      expect(b.hasOpening, isFalse);
      expect(b.paise, -5000);
    });

    test('anything dated before a checked balance marks the check for a recheck', () async {
      final check = await ledger.addCheckpoint(savings, 500000, asOf: DateTime.utc(2026, 11, 15));
      await ledger.recordExpense(
        amountPaise: 2000,
        method: PaymentMethod.upi,
        fundingAccountId: savings,
        categoryId: food,
        occurredAt: DateTime.utc(2026, 11, 14),
      );
      final row = await (db.select(db.balanceCheckpoints)..where((c) => c.id.equals(check))).getSingle();
      expect(row.needsRecheck, isTrue);
    });
  });

  test('the database itself refuses a zero posting, even without the engine', () async {
    await expectLater(
      db
          .into(db.postings)
          .insert(PostingsCompanion.insert(id: 'x', transactionId: 'missing', accountId: cash, amountPaise: 0)),
      throwsA(anything),
    );
  });
}
