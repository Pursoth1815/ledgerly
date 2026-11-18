const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// When an expense happened, as the form shows it: "Today, 10:29 am",
/// "Yesterday, 9:15 pm", "13 Nov, 10:29 am", or "13 Nov 2025, 10:29 am" in
/// another year. English only for now.
String whenText(DateTime at, {required DateTime now}) {
  final day = DateTime(at.year, at.month, at.day);
  final today = DateTime(now.year, now.month, now.day);
  final daysAgo = (today.difference(day).inHours / 24).round();
  final date = switch (daysAgo) {
    0 => 'Today',
    1 => 'Yesterday',
    _ => '${at.day} ${_months[at.month - 1]}${at.year == now.year ? '' : ' ${at.year}'}',
  };
  return '$date, ${clockText(at)}';
}

/// "10:29 am" or "9:05 pm".
String clockText(DateTime at) {
  final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
  final minute = at.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${at.hour < 12 ? 'am' : 'pm'}';
}
