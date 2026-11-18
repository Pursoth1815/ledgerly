import 'package:loopd/core/ledger/ledger_engine.dart';
import 'package:loopd/core/ledger/ledger_types.dart';

/// A made-up November 2026, up to Sunday 15 Nov, for the Money tab's tests
/// and pictures: ₹9,140 spent, UPI ₹2,140 and Credit Card ₹7,000, no cash,
/// six categories (Bills the largest), eleven purchases and one refund of an
/// October purchase. Names and digits are invented.
Future<void> seedNovember(LedgerEngine ledger) async {
  final primary = await ledger.addAccount(
    kind: AccountKind.bank,
    name: 'Primary',
    bankName: 'Federal Bank',
    last4: '2210',
    makeDefault: true,
  );
  final savings = await ledger.addAccount(
    kind: AccountKind.bank,
    name: 'Savings',
    bankName: 'HDFC Bank',
    last4: '8124',
  );
  final kiwi = await ledger.addAccount(kind: AccountKind.creditCard, name: 'Kiwi', bankName: 'YES BANK', last4: '4417');

  Future<String> spend(
    int day,
    int rupees,
    String category,
    String from,
    String? merchant, {
    String? channel,
    int month = 11,
  }) => ledger.recordExpense(
    amountPaise: rupees * 100,
    method: from == kiwi ? PaymentMethod.creditCard : PaymentMethod.upi,
    fundingAccountId: from,
    categoryId: 'category-$category',
    occurredAt: DateTime(2026, month, day, 12),
    merchant: merchant,
    channel: channel,
  );

  await spend(15, 320, 'food', primary, 'Saravana Bhavan');
  await spend(14, 210, 'food', primary, 'Chai Kings');
  await spend(13, 1180, 'food', kiwi, 'Zomato');
  await spend(12, 1500, 'shopping', kiwi, 'Decathlon');
  await spend(10, 200, 'travel', primary, 'Metro card top-up');
  await spend(9, 700, 'fuel', kiwi, 'Indian Oil', channel: 'upi_qr');
  await spend(8, 390, 'groceries', savings, 'Milk and bread');
  await spend(6, 420, 'travel', savings, 'Bus tickets');
  await spend(5, 3120, 'bills', kiwi, 'Electricity bill');
  await spend(4, 600, 'groceries', savings, 'More supermarket');
  await spend(2, 500, 'fuel', kiwi, null);

  // Bought in October, refunded in November: listed in November, counted in
  // October.
  final shoes = await spend(28, 2499, 'shopping', kiwi, 'Shoes', month: 10);
  await ledger.recordRefund(
    originalId: shoes,
    amountPaise: 249900,
    method: PaymentMethod.creditCard,
    destinationAccountId: kiwi,
    occurredAt: DateTime(2026, 11, 14, 18),
  );
}
