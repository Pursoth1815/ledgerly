import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/app/config/app_config.dart';
import 'package:loopd/app/shell/loopd_tab_bar.dart';
import 'package:loopd/design_system/loopd_colors.dart';

import '../../support/pump_loopd_app.dart';

void main() {
  Finder tabButton(String label) => find.descendant(of: find.byType(LoopdTabBar), matching: find.text(label));

  testWidgets('opens on Today with the five tabs in order', (tester) async {
    await pumpLoopdApp(tester);

    final labels = tester
        .widgetList<Text>(find.descendant(of: find.byType(LoopdTabBar), matching: find.byType(Text)))
        .map((text) => text.data);
    expect(labels, ['Today', 'Money', 'Travel', 'Planner', 'More']);
    expect(find.text('All clear'), findsOneWidget);
  });

  testWidgets('the active tab is bright and bold, the others muted, as in the mockups', (tester) async {
    await pumpLoopdApp(tester);
    TextStyle labelStyle(String label) => tester.widget<Text>(tabButton(label)).style!;

    expect(labelStyle('Today').fontWeight, FontWeight.w700);
    expect(labelStyle('Today').color, LoopdColors.dark.textPrimary);
    expect(labelStyle('Money').color, LoopdColors.dark.textMuted);

    await tester.tap(tabButton('Money'));
    await tester.pumpAndSettle();
    expect(labelStyle('Money').fontWeight, FontWeight.w700);
    expect(labelStyle('Today').color, LoopdColors.dark.textMuted);
  });

  testWidgets('tabs not built yet say which phase builds them', (tester) async {
    await pumpLoopdApp(tester);
    for (final (tab, phase) in [('Money', 2), ('Travel', 5), ('Planner', 6)]) {
      await tester.tap(tabButton(tab));
      await tester.pumpAndSettle();
      expect(find.text('Built in Phase $phase'), findsOneWidget);
    }
  });

  testWidgets('the capture button is on every tab and opens the capture sheet', (tester) async {
    await pumpLoopdApp(tester);
    for (final tab in ['Today', 'Money', 'Travel', 'Planner', 'More']) {
      await tester.tap(tabButton(tab));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Add anything'));
      await tester.pumpAndSettle();
      expect(find.text('Or start from'), findsOneWidget, reason: tab);
      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Or start from'), findsNothing);
    }
  });

  testWidgets('More shows which build is running', (tester) async {
    await pumpLoopdApp(tester, distribution: Distribution.store);
    await tester.tap(tabButton('More'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Store build'), 200);
    expect(find.text('Store build'), findsOneWidget);
  });
}
