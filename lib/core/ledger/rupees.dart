/// Rupee amounts as Loopd shows them: Indian digit grouping (₹1,23,456),
/// whole rupees without decimals, and a true minus sign after the ₹ (₹−200;
/// owner, 18 Nov 2026).
library;

/// [paise] as text, such as ₹2,350, ₹62.50 or ₹−200.
String formatRupees(int paise) {
  final sign = paise < 0 ? '−' : '';
  final abs = paise.abs();
  final rupees = groupIndianDigits((abs ~/ 100).toString());
  final rest = abs % 100;
  return rest == 0 ? '₹$sign$rupees' : '₹$sign$rupees.${rest.toString().padLeft(2, '0')}';
}

/// "1234567" as "12,34,567": the last three digits, then pairs. Used while
/// an amount is typed, too.
String groupIndianDigits(String digits) {
  if (digits.length <= 3) return digits;
  final head = digits.substring(0, digits.length - 3);
  final tail = digits.substring(digits.length - 3);
  final pairs = <String>[];
  for (var end = head.length; end > 0; end -= 2) {
    pairs.insert(0, head.substring(end - 2 < 0 ? 0 : end - 2, end));
  }
  return '${pairs.join(',')},$tail';
}

/// Typed rupees, such as "2,350" or "62.5", as paise. Null when the text is
/// not an amount or has more than two decimals.
int? parseRupees(String text) {
  final clean = text.replaceAll(',', '').replaceAll('₹', '').trim();
  final match = RegExp(r'^(\d{1,9})(?:\.(\d{0,2}))?$').firstMatch(clean);
  if (match == null) return null;
  final fraction = (match.group(2) ?? '').padRight(2, '0');
  return int.parse(match.group(1)!) * 100 + int.parse(fraction);
}
