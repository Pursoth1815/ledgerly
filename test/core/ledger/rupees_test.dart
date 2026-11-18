import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/core/ledger/rupees.dart';

void main() {
  test('amounts use Indian grouping and drop zero paise', () {
    expect(formatRupees(0), '₹0');
    expect(formatRupees(65000), '₹650');
    expect(formatRupees(235000), '₹2,350');
    expect(formatRupees(1424000), '₹14,240');
    expect(formatRupees(12345678900), '₹12,34,56,789');
    expect(formatRupees(6250), '₹62.50');
    expect(formatRupees(-20000), '−₹200');
  });

  test('typed rupees become paise', () {
    expect(parseRupees('2350'), 235000);
    expect(parseRupees('2,350'), 235000);
    expect(parseRupees(' ₹62.5 '), 6250);
    expect(parseRupees('62.'), 6200);
    expect(parseRupees('0'), 0);
    for (final bad in ['', 'abc', '1.234', '-5', '1.2.3']) {
      expect(parseRupees(bad), isNull, reason: bad);
    }
  });
}
