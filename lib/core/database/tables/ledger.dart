// Drift's column CHECK constraints name the column inside its own getter
// (`amountPaise.equals(0).not()`), which this lint misreads as recursion.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

// The double-entry ledger (ADR 0006, proposal section 13), owned by
// `core/ledger`. Amounts are whole paise. Times are UTC milliseconds.
// Loans (Phase 4) and transaction sources (Phase 3) arrive with their phases.

/// Every place money can be: bank accounts, cards, Cash in hand, and the
/// bookkeeping accounts behind categories, income, adjustments and openings.
class Accounts extends Table {
  TextColumn get id => text()();

  /// bank, credit_card, cash, category, income, loan, adjustment, write_off,
  /// opening.
  TextColumn get kind => text().check(
    kind.isIn(const [
      'bank',
      'credit_card',
      'cash',
      'category',
      'income',
      'loan',
      'adjustment',
      'write_off',
      'opening',
    ]),
  )();

  /// The nickname, such as Primary or Kiwi; the plain name for built-in
  /// accounts and categories.
  TextColumn get name => text()();

  /// The bank as chosen from the list or typed, such as Federal Bank (banks
  /// and cards). Kept as text because two list entries can share one sender
  /// code, and a bank typed by hand has none.
  TextColumn get bankName => text().nullable()();

  /// The six-letter SMS sender code, such as FEDBNK (banks and cards).
  TextColumn get bankCode => text().nullable()();

  /// Last four digits of the account or card number.
  TextColumn get last4 => text().nullable()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();

  /// Removed accounts keep their past transactions (no archived state).
  IntColumn get removedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  bool get isStrict => true;
}

/// The look of a category account: a colour and an icon. No two categories
/// share either (owner, 18 Nov 2026), so there are at most twenty-five.
class Categories extends Table {
  TextColumn get accountId => text().references(Accounts, #id)();

  /// Index into the category palette (0 to 24).
  IntColumn get colour => integer().check(colour.isBetweenValues(0, 24))();

  /// Icon key, such as food or bus.
  TextColumn get icon => text()();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column<Object>> get primaryKey => {accountId};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {colour},
    {icon},
  ];

  @override
  bool get isStrict => true;
}

/// One money event. Its postings (at least two) always sum to zero.
@DataClassName('LedgerTransaction')
class LedgerTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text().check(
    kind.isIn(const [
      'expense',
      'refund',
      'income',
      'transfer',
      'card_payment',
      'loan',
      'repayment',
      'write_off',
      'adjustment',
      'opening_balance',
    ]),
  )();

  /// Required for expenses, refunds, loans and repayments; empty otherwise.
  TextColumn get paymentMethod => text().nullable().check(
    paymentMethod.isIn(const ['upi', 'credit_card', 'cash', 'debit_card', 'net_banking', 'auto_debit']),
  )();

  /// How the SMS says it happened, such as upi_qr for a card paid by UPI QR.
  TextColumn get channel => text().nullable()();
  IntColumn get occurredAt => integer()();

  /// The local calendar day, YYYY-MM-DD, for totals by day.
  TextColumn get localDate => text()();
  TextColumn get merchant => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get refundOf => text().nullable().references(LedgerTransactions, #id)();
  IntColumn get revision => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  bool get isStrict => true;
}

/// How much moved into (+) or out of (−) one account in one transaction.
class Postings extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId => text().references(LedgerTransactions, #id)();
  TextColumn get accountId => text().references(Accounts, #id)();
  IntColumn get amountPaise => integer().check(amountPaise.equals(0).not())();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {transactionId, accountId},
  ];

  @override
  bool get isStrict => true;
}

/// A full snapshot after every create, edit, delete, restore and undo.
class TransactionRevisions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get transactionId => text().references(LedgerTransactions, #id)();
  IntColumn get revision => integer()();

  /// create, edit, delete or undo.
  TextColumn get action => text()();
  TextColumn get snapshotJson => text()();
  TextColumn get reason => text().nullable()();

  /// Groups the revisions written by one user action.
  TextColumn get operationId => text().nullable()();
  IntColumn get changedAt => integer()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {transactionId, revision},
  ];

  @override
  bool get isStrict => true;
}

/// A balance you checked in your bank or card app, in the ledger's sign.
class BalanceCheckpoints extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text().references(Accounts, #id)();
  IntColumn get asOf => integer()();
  IntColumn get actualPaise => integer()();

  /// manual for now; later sources arrive with their phases.
  TextColumn get source => text()();
  TextColumn get note => text().nullable()();

  /// Set when something dated before this check is edited.
  BoolColumn get needsRecheck => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  bool get isStrict => true;
}
