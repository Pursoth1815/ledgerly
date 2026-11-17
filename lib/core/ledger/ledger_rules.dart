import '../errors/app_exception.dart';
import 'ledger_types.dart';

/// The fixed shape of every kind of transaction (ADR 0006, proposal
/// section 13). Pure functions, so every rule is tested on its own.
///
/// [kinds] gives the kind of each account in the entry's postings.
void checkEntry(LedgerEntry entry, Map<String, AccountKind> kinds) {
  final postings = entry.postings;
  if (postings.length < 2) throw const LedgerException(LedgerFailure.tooFewPostings);
  if (postings.values.any((paise) => paise == 0)) throw const LedgerException(LedgerFailure.invalidAmount);
  if (postings.values.fold<int>(0, (sum, paise) => sum + paise) != 0) {
    throw const LedgerException(LedgerFailure.unbalanced);
  }

  // The accounts by kind, with their amounts.
  AccountKind kindOf(String id) => kinds[id] ?? (throw const LedgerException(LedgerFailure.notFound));
  final entries = postings.entries.toList();
  Iterable<MapEntry<String, int>> where(bool Function(AccountKind) test) =>
      entries.where((posting) => test(kindOf(posting.key)));

  void shape(bool ok) {
    if (!ok) throw const LedgerException(LedgerFailure.wrongShape);
  }

  void noMethod() {
    if (entry.method != null) throw const LedgerException(LedgerFailure.methodMismatch);
  }

  /// The one non-category posting must be the method's kind of account.
  void methodFits(MapEntry<String, int> funding) {
    final method = entry.method;
    if (method == null || kindOf(funding.key) != method.fundingKind) {
      throw const LedgerException(LedgerFailure.methodMismatch);
    }
  }

  switch (entry.kind) {
    case TransactionKind.expense:
      // Category +amount, funding −amount.
      shape(entries.length == 2);
      final category = where((kind) => kind == AccountKind.category);
      final funding = where((kind) => kind.holdsMoney);
      shape(category.length == 1 && funding.length == 1);
      shape(category.single.value > 0 && funding.single.value < 0);
      methodFits(funding.single);

    case TransactionKind.refund:
      // Destination +amount, the original's category −amount.
      if (entry.refundOf == null) throw const LedgerException(LedgerFailure.refundWithoutOriginal);
      shape(entries.length == 2);
      final category = where((kind) => kind == AccountKind.category);
      final destination = where((kind) => kind.holdsMoney);
      shape(category.length == 1 && destination.length == 1);
      shape(category.single.value < 0 && destination.single.value > 0);
      methodFits(destination.single);

    case TransactionKind.income:
      // Bank or cash +amount, income −amount.
      noMethod();
      shape(entries.length == 2);
      final income = where((kind) => kind == AccountKind.income);
      final into = where((kind) => kind == AccountKind.bank || kind == AccountKind.cash);
      shape(income.length == 1 && into.length == 1 && income.single.value < 0);

    case TransactionKind.transfer:
      // Between your own bank accounts and Cash in hand, such as an ATM
      // withdrawal. Never spending.
      noMethod();
      shape(entries.length == 2);
      shape(
        entries.every((posting) => kindOf(posting.key) == AccountKind.bank || kindOf(posting.key) == AccountKind.cash),
      );

    case TransactionKind.cardPayment:
      // Card +amount (the bill is paid), bank −amount. A settlement, not
      // spending.
      noMethod();
      shape(entries.length == 2);
      final card = where((kind) => kind == AccountKind.creditCard);
      final bank = where((kind) => kind == AccountKind.bank);
      shape(card.length == 1 && bank.length == 1 && card.single.value > 0);

    case TransactionKind.adjustment:
      // A visible correction outside spending, such as Update count.
      noMethod();
      shape(entries.length == 2);
      shape(where((kind) => kind == AccountKind.adjustment).length == 1);
      shape(where((kind) => kind.holdsMoney).length == 1);

    case TransactionKind.openingBalance:
      noMethod();
      shape(entries.length == 2);
      shape(where((kind) => kind == AccountKind.opening).length == 1);
      shape(where((kind) => kind.holdsMoney).length == 1);

    case TransactionKind.loan || TransactionKind.repayment || TransactionKind.writeOff:
      throw const LedgerException(LedgerFailure.notBuiltYet);
  }
}

/// The amount of an expense: what went into its category.
int expenseAmount(Map<String, int> postings, Map<String, AccountKind> kinds) =>
    postings.entries.where((posting) => kinds[posting.key] == AccountKind.category).single.value;

/// The amount of a refund: what came back to its destination.
int refundAmount(Map<String, int> postings, Map<String, AccountKind> kinds) =>
    postings.entries.where((posting) => kinds[posting.key]?.holdsMoney ?? false).single.value;
