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

/// Where a balance checkpoint came from.
abstract final class CheckpointSource {
  /// A balance checked in a bank or card app and typed in. It is compared
  /// with the tracked balance, never applied.
  static const manual = 'manual';

  /// An Update count of Cash in hand. Cash has no bank to ask, so the latest
  /// count is its balance from then on.
  static const count = 'count';
}

/// A bank account or credit card as screens show it (proposal section 4).
class LedgerAccount {
  const LedgerAccount({
    required this.id,
    required this.kind,
    required this.nickname,
    required this.isDefault,
    this.bankName,
    this.bankCode,
    this.last4,
    this.billDueDay,
  });

  final String id;
  final AccountKind kind;
  final String nickname;
  final String? bankName;

  /// The six-letter SMS sender code; empty for a bank typed by hand.
  final String? bankCode;
  final String? last4;
  final bool isDefault;

  /// A credit card's bill due day, 1 to 31; null when not set.
  final int? billDueDay;

  /// The next day this card's bill is due, today included; null when no due
  /// day is set. A month too short for the day uses its last day.
  DateTime? nextBillDue(DateTime now) {
    final day = billDueDay;
    if (day == null) return null;
    DateTime inMonth(int month) {
      final last = DateTime(now.year, month + 1, 0).day;
      return DateTime(now.year, month, day > last ? last : day);
    }

    final today = DateTime(now.year, now.month, now.day);
    final thisMonth = inMonth(now.month);
    return thisMonth.isBefore(today) ? inMonth(now.month + 1) : thisMonth;
  }
}

/// An expense category as screens show it: its name, a colour index into
/// the category palette (0 to 7) and an icon key, such as food or bus.
class LedgerCategory {
  const LedgerCategory({
    required this.id,
    required this.name,
    required this.colour,
    required this.icon,
    this.builtIn = false,
  });

  final String id;
  final String name;
  final int colour;
  final String icon;

  /// One of the default set, which cannot be deleted; only categories the
  /// owner added can.
  final bool builtIn;
}

/// A saved refund, as the refund form loads it for editing.
class RefundRecord {
  const RefundRecord({
    required this.id,
    required this.revision,
    required this.originalId,
    required this.amountPaise,
    required this.method,
    required this.destinationAccountId,
    required this.occurredAt,
    this.note,
  });

  final String id;
  final int revision;

  /// The purchase it belongs to.
  final String originalId;
  final int amountPaise;
  final PaymentMethod method;
  final String destinationAccountId;
  final DateTime occurredAt;
  final String? note;
}

/// A saved expense, as the expense form loads it for editing.
class ExpenseRecord {
  const ExpenseRecord({
    required this.id,
    required this.revision,
    required this.amountPaise,
    required this.method,
    required this.fundingAccountId,
    required this.categoryId,
    required this.occurredAt,
    this.channel,
    this.merchant,
    this.note,
  });

  final String id;

  /// The revision on screen; undo needs it to know nothing changed since.
  final int revision;
  final int amountPaise;

  /// As stored, which may be a bank-only method such as debit card; screens
  /// show [PaymentMethod.shownAs].
  final PaymentMethod method;
  final String fundingAccountId;
  final String categoryId;
  final DateTime occurredAt;
  final String? channel;
  final String? merchant;
  final String? note;
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

  /// The same entry with other postings, such as when a deleted category's
  /// expenses move to another.
  LedgerEntry withPostings(Map<String, int> postings) => LedgerEntry(
    kind: kind,
    occurredAt: occurredAt,
    postings: postings,
    method: method,
    channel: channel,
    merchant: merchant,
    note: note,
    refundOf: refundOf,
  );
}

/// One expense, or one refund, in a spending report (the Money tab).
class SpendingEntry {
  const SpendingEntry({
    required this.id,
    required this.isRefund,
    required this.occurredAt,
    required this.localDate,
    required this.amountPaise,
    required this.method,
    required this.accountId,
    required this.accountName,
    required this.categoryId,
    this.channel,
    this.merchant,
    this.note,
    this.refundedPaise = 0,
    this.originalId,
    this.originalDate,
  });

  final String id;

  /// A refund is listed on the day it came back, but its amount counts in
  /// its purchase's period ([SpendingReport] totals leave it out).
  final bool isRefund;
  final DateTime occurredAt;

  /// The local day, YYYY-MM-DD.
  final String localDate;

  /// The purchase, or the money that came back; always positive.
  final int amountPaise;

  /// As shown: the bank-only methods count as UPI.
  final PaymentMethod method;

  /// The bank account, card or Cash in hand it was paid from, or that a
  /// refund came back to, and its name (kept for removed accounts).
  final String accountId;
  final String accountName;
  final String categoryId;
  final String? channel;
  final String? merchant;
  final String? note;

  /// For a purchase: its live refunds so far, whenever they came.
  final int refundedPaise;

  /// For a refund: the purchase it belongs to, and that purchase's local day.
  final String? originalId;
  final String? originalDate;

  /// What a purchase counts for in totals after its refunds; 0 for a refund.
  int get countedPaise => isRefund ? 0 : amountPaise - refundedPaise;
}

/// Spending over a period: purchases dated in it, net of their refunds
/// (refunds always count in the purchase's period, owner, 18 Nov 2026),
/// plus the refunds that came back in it, for the list.
class SpendingReport {
  const SpendingReport(this.entries);

  /// Newest first.
  final List<SpendingEntry> entries;

  /// The same report for one bank account, card or Cash in hand.
  SpendingReport only(String accountId) => SpendingReport([
    for (final e in entries)
      if (e.accountId == accountId) e,
  ]);

  int get totalPaise => entries.fold(0, (sum, e) => sum + e.countedPaise);

  /// UPI, Credit Card and Cash, in that order, each with its total; a method
  /// with nothing is left out.
  List<(PaymentMethod, int)> get byMethod {
    final totals = <PaymentMethod, int>{};
    for (final e in entries) {
      totals[e.method] = (totals[e.method] ?? 0) + e.countedPaise;
    }
    return [
      for (final method in const [PaymentMethod.upi, PaymentMethod.creditCard, PaymentMethod.cash])
        if ((totals[method] ?? 0) > 0) (method, totals[method]!),
    ];
  }

  /// Account id → paise, for accounts with something counted.
  Map<String, int> get byAccount => _sum((e) => e.accountId);

  /// Category id → paise, largest first; categories with nothing are left
  /// out.
  List<(String, int)> get byCategory {
    final totals = _sum((e) => e.categoryId).entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [for (final e in totals) (e.key, e.value)];
  }

  Map<String, int> _sum(String Function(SpendingEntry e) key) {
    final totals = <String, int>{};
    for (final e in entries) {
      if (e.isRefund) continue;
      totals[key(e)] = (totals[key(e)] ?? 0) + e.countedPaise;
    }
    return totals;
  }
}
