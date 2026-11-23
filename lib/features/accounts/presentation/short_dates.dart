const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "Nov", as in "₹650 in Nov". English only for now.
String shortMonth(DateTime date) => _months[date.month - 1];

/// "November".
String longMonth(DateTime date) => const [
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
][date.month - 1];

/// "12 Nov" in local time, as in "Due 12 Nov".
String shortDay(DateTime date) {
  final local = date.toLocal();
  return '${local.day} ${_months[local.month - 1]}';
}
