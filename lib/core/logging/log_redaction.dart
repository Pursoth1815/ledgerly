/// The safety net under structured logging (ADR 0014).
///
/// Log events should only carry safe fields in the first place. This pass
/// removes anything that still looks like money, an account or card number,
/// a reference, a phone number or a UPI id before a line is written.
library;

final _amount = RegExp(r'(?:₹|\bRs\.?|\bINR)\s?\d[\d,]*(?:\.\d+)?', caseSensitive: false);
final _handle = RegExp(r'[\w.+\-]+@[\w.\-]+');
final _digitRun = RegExp(r'\d(?:[\s\-]?\d){3,}');

/// Returns [text] with sensitive-looking parts replaced by placeholders.
String redactSensitive(String text) =>
    text.replaceAll(_amount, '[amount]').replaceAll(_handle, '[id]').replaceAll(_digitRun, '[digits]');
