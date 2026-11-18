import 'package:flutter/services.dart';

import '../../../core/ledger/rupees.dart';

/// Keeps a typed amount readable as rupees: Indian digit grouping (1,23,456)
/// as you type, at most nine digits before the point and two after, and no
/// leading zeros. Anything else, such as a second point, is refused.
class RupeeInputFormatter extends TextInputFormatter {
  const RupeeInputFormatter();

  static final _allowed = RegExp(r'^\d{0,9}(\.\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text.replaceAll(',', '');
    if (raw.isEmpty) return const TextEditingValue();
    if (!_allowed.hasMatch(raw)) return oldValue;
    final point = raw.indexOf('.');
    var whole = point < 0 ? raw : raw.substring(0, point);
    whole = whole.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (whole.isEmpty) whole = '0';
    final text = groupIndianDigits(whole) + (point < 0 ? '' : raw.substring(point));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// [paise] as the amount field shows it: "2,350" or "62.50", without ₹.
String amountFieldText(int paise) => formatRupees(paise).replaceFirst('₹', '');
