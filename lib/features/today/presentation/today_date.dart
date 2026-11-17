/// "Sunday, 15 November", as in the Today mockup. English only for now.
String todayDateLabel(DateTime date) {
  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  const months = [
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
  return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
}
