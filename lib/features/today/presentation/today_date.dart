const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// "Sunday, 15 November", as in the Today mockup. English only for now.
String todayDateLabel(DateTime date) {
  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  return '${days[date.weekday - 1]}, ${date.day} ${monthName(date)}';
}

/// "November".
String monthName(DateTime date) => _months[date.month - 1];

/// The local day as YYYY-MM-DD, as the ledger stores it.
String localDay(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
