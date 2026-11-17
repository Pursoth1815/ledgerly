import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/core/errors/app_exception.dart';
import 'package:loopd/core/ledger/ledger_rules.dart';
import 'package:loopd/core/ledger/ledger_types.dart';

/// The posting-shape rules on their own (ADR 0006).
void main() {
  const kinds = {
    'food': AccountKind.category,
    'bank': AccountKind.bank,
    'card': AccountKind.creditCard,
    'cash': AccountKind.cash,
    'income': AccountKind.income,
    'adjustment': AccountKind.adjustment,
  };
  final at = DateTime.utc(2026, 11, 17);

  Matcher fails(LedgerFailure failure) => throwsA(isA<LedgerException>().having((e) => e.failure, 'failure', failure));

  LedgerEntry expense(Map<String, int> postings, PaymentMethod? method) =>
      LedgerEntry(kind: TransactionKind.expense, method: method, occurredAt: at, postings: postings);

  test('a UPI expense from a bank account is valid', () {
    checkEntry(expense({'food': 6200, 'bank': -6200}, PaymentMethod.upi), kinds);
  });

  test('the method must fit the funding account', () {
    expect(
      () => checkEntry(expense({'food': 6200, 'card': -6200}, PaymentMethod.upi), kinds),
      fails(LedgerFailure.methodMismatch),
    );
    expect(
      () => checkEntry(expense({'food': 6200, 'bank': -6200}, PaymentMethod.cash), kinds),
      fails(LedgerFailure.methodMismatch),
    );
    expect(() => checkEntry(expense({'food': 6200, 'bank': -6200}, null), kinds), fails(LedgerFailure.methodMismatch));
  });

  test('postings must sum to zero, never be zero, and number at least two', () {
    expect(
      () => checkEntry(expense({'food': 6200, 'bank': -6000}, PaymentMethod.upi), kinds),
      fails(LedgerFailure.unbalanced),
    );
    expect(
      () => checkEntry(expense({'food': 0, 'bank': 0}, PaymentMethod.upi), kinds),
      fails(LedgerFailure.invalidAmount),
    );
    expect(() => checkEntry(expense({'food': 6200}, PaymentMethod.upi), kinds), fails(LedgerFailure.tooFewPostings));
  });

  test('an expense must go into a category, not between your own accounts', () {
    expect(
      () => checkEntry(expense({'cash': 6200, 'bank': -6200}, PaymentMethod.upi), kinds),
      fails(LedgerFailure.wrongShape),
    );
  });

  test('income, transfers and card payments carry no payment method', () {
    final income = LedgerEntry(
      kind: TransactionKind.income,
      method: PaymentMethod.upi,
      occurredAt: at,
      postings: const {'bank': 100, 'income': -100},
    );
    expect(() => checkEntry(income, kinds), fails(LedgerFailure.methodMismatch));
  });

  test('a card payment must pay a card from a bank account', () {
    final ok = LedgerEntry(
      kind: TransactionKind.cardPayment,
      occurredAt: at,
      postings: const {'card': 100, 'bank': -100},
    );
    checkEntry(ok, kinds);
    final wrong = LedgerEntry(
      kind: TransactionKind.cardPayment,
      occurredAt: at,
      postings: const {'cash': 100, 'bank': -100},
    );
    expect(() => checkEntry(wrong, kinds), fails(LedgerFailure.wrongShape));
  });

  test('a refund must name its original', () {
    final refund = LedgerEntry(
      kind: TransactionKind.refund,
      method: PaymentMethod.upi,
      occurredAt: at,
      postings: const {'bank': 100, 'food': -100},
    );
    expect(() => checkEntry(refund, kinds), fails(LedgerFailure.refundWithoutOriginal));
  });

  test('loans, repayments and write-offs wait for lending (Phase 4)', () {
    final loan = LedgerEntry(kind: TransactionKind.loan, occurredAt: at, postings: const {'bank': -100, 'cash': 100});
    expect(() => checkEntry(loan, kinds), fails(LedgerFailure.notBuiltYet));
  });

  test('bank-only methods count as UPI; the others show as themselves', () {
    expect(PaymentMethod.debitCard.shownAs, PaymentMethod.upi);
    expect(PaymentMethod.netBanking.shownAs, PaymentMethod.upi);
    expect(PaymentMethod.autoDebit.shownAs, PaymentMethod.upi);
    expect(PaymentMethod.creditCard.shownAs, PaymentMethod.creditCard);
    expect(PaymentMethod.cash.shownAs, PaymentMethod.cash);
  });
}
