/// The kinds and methods of the double-entry ledger (ADR 0006). Each value
/// keeps the exact text stored in the database.
library;

enum AccountKind {
  bank('bank'),
  creditCard('credit_card'),
  cash('cash'),
  category('category'),
  income('income'),
  loan('loan'),
  adjustment('adjustment'),
  writeOff('write_off'),
  opening('opening');

  const AccountKind(this.db);

  final String db;

  static AccountKind fromDb(String value) => values.firstWhere((kind) => kind.db == value);

  /// Where money can actually be held or owed: a bank account, a card or
  /// Cash in hand.
  bool get holdsMoney => this == bank || this == creditCard || this == cash;
}

enum TransactionKind {
  expense('expense'),
  refund('refund'),
  income('income'),
  transfer('transfer'),
  cardPayment('card_payment'),
  loan('loan'),
  repayment('repayment'),
  writeOff('write_off'),
  adjustment('adjustment'),
  openingBalance('opening_balance');

  const TransactionKind(this.db);

  final String db;

  static TransactionKind fromDb(String value) => values.firstWhere((kind) => kind.db == value);
}

enum PaymentMethod {
  upi('upi'),
  creditCard('credit_card'),
  cash('cash'),

  /// The next three come only from bank SMS (Phase 3); the form never offers
  /// them.
  debitCard('debit_card'),
  netBanking('net_banking'),
  autoDebit('auto_debit');

  const PaymentMethod(this.db);

  final String db;

  static PaymentMethod fromDb(String value) => values.firstWhere((method) => method.db == value);

  /// The kind of account the money comes from (or returns to, for a refund).
  AccountKind get fundingKind => switch (this) {
    creditCard => AccountKind.creditCard,
    cash => AccountKind.cash,
    _ => AccountKind.bank,
  };

  /// Loopd shows only UPI, Credit Card and Cash: the bank-only methods count
  /// as UPI in every total (owner's decision, 17 Nov 2026).
  PaymentMethod get shownAs => switch (this) {
    debitCard || netBanking || autoDebit => upi,
    _ => this,
  };
}

/// Fixed ids of the accounts every install has.
abstract final class SystemAccounts {
  static const cash = 'cash';
  static const adjustment = 'adjustment';
  static const opening = 'opening';
  static const income = 'income';

  static const all = {cash, adjustment, opening, income};
}

/// A transaction as the engine checks it before writing: its postings by
/// account (+ in, − out), which always sum to zero.
class LedgerEntry {
  const LedgerEntry({
    required this.kind,
    required this.occurredAt,
    required this.postings,
    this.method,
    this.channel,
    this.merchant,
    this.note,
    this.refundOf,
  });

  final TransactionKind kind;
  final PaymentMethod? method;
  final String? channel;
  final DateTime occurredAt;
  final String? merchant;
  final String? note;
  final String? refundOf;
  final Map<String, int> postings;
}
