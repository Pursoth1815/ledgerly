import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:loopd/core/logging/log_redaction.dart';
import 'package:loopd/core/logging/logging_setup.dart';

void main() {
  group('redactSensitive', () {
    test('removes amounts in every form banks write them', () {
      expect(redactSensitive('Debited Rs 62.00 today'), 'Debited [amount] today');
      expect(redactSensitive('spent Rs.1,299.00'), 'spent [amount]');
      expect(redactSensitive('INR 705 at shop'), '[amount] at shop');
      expect(redactSensitive('paid ₹2,000'), 'paid [amount]');
    });

    test('removes account, card, reference and phone digits', () {
      expect(redactSensitive('a/c X2210'), 'a/c X[digits]');
      expect(redactSensitive('Card XX4417'), 'Card XX[digits]');
      expect(redactSensitive('Ref 600000000001'), 'Ref [digits]');
      expect(redactSensitive('call 98400 12345'), 'call [digits]');
      expect(redactSensitive('PNR 410-000-0001'), 'PNR [digits]');
    });

    test('removes UPI ids and email addresses', () {
      expect(redactSensitive('to shop.name@okaxis now'), 'to [id] now');
    });

    test('keeps short counts and event names', () {
      expect(redactSensitive('core.database opened schema=1 new=true'), 'core.database opened schema=1 new=true');
      expect(redactSensitive('drafts=3 matched=12'), 'drafts=3 matched=12');
    });
  });

  test('a formatted log line writes the error type, never its message', () {
    final record = LogRecord(
      Level.SEVERE,
      'open_failed code=database.key_mismatch',
      'core.database',
      FormatException('row 4417 amount Rs 900'),
    );

    final line = formatLogRecord(record);

    expect(line, 'SEVERE core.database: open_failed code=database.key_mismatch | FormatException');
  });
}
