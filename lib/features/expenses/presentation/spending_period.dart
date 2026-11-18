/// The period the Money tab shows: a day, a week (Monday to Sunday) or a
/// calendar month, in local time.
enum PeriodKind { day, week, month }

class SpendingPeriod {
  const SpendingPeriod._(this.kind, this.start);

  /// The period of [kind] that holds [now].
  factory SpendingPeriod.current(PeriodKind kind, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (kind) {
      PeriodKind.day => SpendingPeriod._(kind, today),
      PeriodKind.week => SpendingPeriod._(kind, DateTime(today.year, today.month, today.day - (today.weekday - 1))),
      PeriodKind.month => SpendingPeriod._(kind, DateTime(today.year, today.month)),
    };
  }

  final PeriodKind kind;

  /// The first local day, at midnight.
  final DateTime start;

  /// The day after the last one, at midnight.
  DateTime get end => switch (kind) {
    PeriodKind.day => DateTime(start.year, start.month, start.day + 1),
    PeriodKind.week => DateTime(start.year, start.month, start.day + 7),
    PeriodKind.month => DateTime(start.year, start.month + 1),
  };

  SpendingPeriod get previous => switch (kind) {
    PeriodKind.day => SpendingPeriod._(kind, DateTime(start.year, start.month, start.day - 1)),
    PeriodKind.week => SpendingPeriod._(kind, DateTime(start.year, start.month, start.day - 7)),
    PeriodKind.month => SpendingPeriod._(kind, DateTime(start.year, start.month - 1)),
  };

  SpendingPeriod get next => SpendingPeriod._(kind, end);

  /// Whether [now] falls in it, so there is nothing later to show.
  bool holds(DateTime now) => !now.isBefore(start) && now.isBefore(end);

  /// "Sunday, 15 November", "9 – 15 November" or "November 2026".
  String title() {
    final last = DateTime(end.year, end.month, end.day - 1);
    return switch (kind) {
      PeriodKind.day => '${weekdayNames[start.weekday - 1]}, ${start.day} ${monthNames[start.month - 1]}',
      PeriodKind.week =>
        start.month == last.month
            ? '${start.day} – ${last.day} ${monthNames[last.month - 1]}'
            : '${start.day} ${monthNames[start.month - 1]} – ${last.day} ${monthNames[last.month - 1]}',
      PeriodKind.month => '${monthNames[start.month - 1]} ${start.year}',
    };
  }

  /// "Spent today", "Spent this week", "Spent in November" and so on.
  String spentLabel(DateTime now) {
    final current = SpendingPeriod.current(kind, now);
    final last = current.previous;
    return switch (kind) {
      PeriodKind.day when start == current.start => 'Spent today',
      PeriodKind.day when start == last.start => 'Spent yesterday',
      PeriodKind.day => 'Spent on ${start.day} ${monthNames[start.month - 1]}',
      PeriodKind.week when start == current.start => 'Spent this week',
      PeriodKind.week when start == last.start => 'Spent last week',
      PeriodKind.week => 'Spent that week',
      PeriodKind.month when start.year == now.year => 'Spent in ${monthNames[start.month - 1]}',
      PeriodKind.month => 'Spent in ${monthNames[start.month - 1]} ${start.year}',
    };
  }

  @override
  bool operator ==(Object other) => other is SpendingPeriod && other.kind == kind && other.start == start;

  @override
  int get hashCode => Object.hash(kind, start);
}

const monthNames = [
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

const weekdayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
