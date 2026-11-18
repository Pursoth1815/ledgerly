import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/features/expenses/presentation/spending_period.dart';

void main() {
  final now = DateTime(2026, 11, 15, 10); // a Sunday

  test('a day, a week from Monday and a calendar month', () {
    final day = SpendingPeriod.current(PeriodKind.day, now);
    expect((day.start, day.end), (DateTime(2026, 11, 15), DateTime(2026, 11, 16)));
    final week = SpendingPeriod.current(PeriodKind.week, now);
    expect((week.start, week.end), (DateTime(2026, 11, 9), DateTime(2026, 11, 16)));
    final month = SpendingPeriod.current(PeriodKind.month, now);
    expect((month.start, month.end), (DateTime(2026, 11), DateTime(2026, 12)));
  });

  test('titles, as in the mockup', () {
    expect(SpendingPeriod.current(PeriodKind.day, now).title(), 'Sunday, 15 November');
    expect(SpendingPeriod.current(PeriodKind.week, now).title(), '9 – 15 November');
    expect(SpendingPeriod.current(PeriodKind.month, now).title(), 'November 2026');
    final across = SpendingPeriod.current(PeriodKind.week, DateTime(2026, 12, 2));
    expect(across.title(), '30 November – 6 December');
  });

  test('stepping back and forward, across months and years', () {
    final jan = SpendingPeriod.current(PeriodKind.month, DateTime(2027, 1, 5));
    expect(jan.previous.start, DateTime(2026, 12));
    expect(jan.previous.next, jan);
    final day = SpendingPeriod.current(PeriodKind.day, DateTime(2026, 11, 1));
    expect(day.previous.start, DateTime(2026, 10, 31));
  });

  test('what the total is called', () {
    final day = SpendingPeriod.current(PeriodKind.day, now);
    expect(day.spentLabel(now), 'Spent today');
    expect(day.previous.spentLabel(now), 'Spent yesterday');
    expect(day.previous.previous.spentLabel(now), 'Spent on 13 November');
    final week = SpendingPeriod.current(PeriodKind.week, now);
    expect(week.spentLabel(now), 'Spent this week');
    expect(week.previous.spentLabel(now), 'Spent last week');
    expect(week.previous.previous.spentLabel(now), 'Spent that week');
    final month = SpendingPeriod.current(PeriodKind.month, now);
    expect(month.spentLabel(now), 'Spent in November');
    expect(SpendingPeriod.current(PeriodKind.month, DateTime(2025, 11)).spentLabel(now), 'Spent in November 2025');
  });

  test('only the current period holds now', () {
    final month = SpendingPeriod.current(PeriodKind.month, now);
    expect(month.holds(now), isTrue);
    expect(month.previous.holds(now), isFalse);
  });
}
