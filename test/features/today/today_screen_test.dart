import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/core/settings/theme_setting.dart';
import 'package:loopd/features/today/presentation/today_date.dart';

import '../../support/pump_loopd_app.dart';

void main() {
  test('the date reads like the mockup', () {
    expect(todayDateLabel(DateTime(2026, 11, 15)), 'Sunday, 15 November');
    expect(todayDateLabel(DateTime(2026, 1, 5)), 'Monday, 5 January');
  });

  testWidgets('with nothing to show, Today is all clear', (tester) async {
    await pumpLoopdApp(tester);
    expect(find.text('Today'), findsWidgets);
    expect(find.text('All clear'), findsOneWidget);
  });

  testWidgets('the sun button switches to light, the moon back to dark, and it is remembered', (tester) async {
    final database = await pumpLoopdApp(tester);

    await tester.tap(find.bySemanticsLabel('Switch to light theme'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.text('All clear'))).brightness, Brightness.light);
    expect(await ThemeSettingStore(database).load(), ThemeMode.light);

    await tester.tap(find.bySemanticsLabel('Switch to dark theme'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.text('All clear'))).brightness, Brightness.dark);
    expect(await ThemeSettingStore(database).load(), ThemeMode.dark);
  });

  testWidgets('the hourglass says when Digital Wellbeing arrives', (tester) async {
    await pumpLoopdApp(tester);
    await tester.tap(find.bySemanticsLabel('Digital Wellbeing'));
    await tester.pump();
    expect(find.text('Digital Wellbeing is built in Phase 8'), findsOneWidget);
  });
}
