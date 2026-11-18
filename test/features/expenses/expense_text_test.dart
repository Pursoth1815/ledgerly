import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/features/expenses/presentation/amount_input.dart';
import 'package:loopd/features/expenses/presentation/when_text.dart';

void main() {
  group('RupeeInputFormatter', () {
    String type(String before, String after) => const RupeeInputFormatter()
        .formatEditUpdate(TextEditingValue(text: before), TextEditingValue(text: after))
        .text;

    test('groups digits the Indian way as you type', () {
      expect(type('', '1'), '1');
      expect(type('1,234', '12345'), '12,345');
      expect(type('', '1234567'), '12,34,567');
      expect(type('', '2350.5'), '2,350.5');
    });

    test('drops leading zeros and starts a lone point with 0', () {
      expect(type('', '0005'), '5');
      expect(type('', '.5'), '0.5');
      expect(type('', '0'), '0');
    });

    test('refuses letters, a second point, a third decimal and a tenth digit', () {
      expect(type('62', '62a'), '62');
      expect(type('6.2', '6.2.'), '6.2');
      expect(type('62.50', '62.505'), '62.50');
      expect(type('12,34,56,789', '1234567890'), '12,34,56,789');
    });

    test('the amount field shows saved paise without the ₹', () {
      expect(amountFieldText(235000), '2,350');
      expect(amountFieldText(6250), '62.50');
    });
  });

  group('whenText', () {
    final now = DateTime(2026, 11, 17, 21);

    test('names today and yesterday, then the date', () {
      expect(whenText(DateTime(2026, 11, 17, 10, 29), now: now), 'Today, 10:29 am');
      expect(whenText(DateTime(2026, 11, 16, 21, 5), now: now), 'Yesterday, 9:05 pm');
      expect(whenText(DateTime(2026, 11, 13, 12), now: now), '13 Nov, 12:00 pm');
      expect(whenText(DateTime(2025, 12, 31, 0, 15), now: now), '31 Dec 2025, 12:15 am');
    });
  });
}
