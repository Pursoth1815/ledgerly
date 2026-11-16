import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/app/app.dart';
import 'package:loopd/app/config/app_config.dart';
import 'package:loopd/app/shell/loopd_tab_bar.dart';
import 'package:loopd/design_system/loopd_colors.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, {Distribution distribution = Distribution.personal}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appConfigProvider.overrideWithValue(AppConfig(distribution: distribution))],
        child: const LoopdApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder tabButton(String label) => find.descendant(of: find.byType(LoopdTabBar), matching: find.text(label));

  testWidgets('opens on Today with the five tabs in order', (tester) async {
    await pumpApp(tester);

    final labels = tester
        .widgetList<Text>(find.descendant(of: find.byType(LoopdTabBar), matching: find.byType(Text)))
        .map((text) => text.data);
    expect(labels, ['Today', 'Money', 'Travel', 'Planner', 'More']);
    expect(find.text('Built in Phase 1'), findsOneWidget);
  });

  testWidgets('the active tab is bright and bold, the others muted, as in the mockups', (tester) async {
    await pumpApp(tester);
    TextStyle labelStyle(String label) => tester.widget<Text>(tabButton(label)).style!;

    expect(labelStyle('Today').fontWeight, FontWeight.w700);
    expect(labelStyle('Today').color, LoopdColors.light.textPrimary);
    expect(labelStyle('Money').fontWeight, FontWeight.w600);
    expect(labelStyle('Money').color, LoopdColors.light.textMuted);

    await tester.tap(tabButton('Money'));
    await tester.pumpAndSettle();
    expect(labelStyle('Money').fontWeight, FontWeight.w700);
    expect(labelStyle('Today').color, LoopdColors.light.textMuted);
  });

  testWidgets('each tab shows its own page', (tester) async {
    await pumpApp(tester);

    await tester.tap(tabButton('Money'));
    await tester.pumpAndSettle();
    expect(find.text('Built in Phase 2'), findsOneWidget);

    await tester.tap(tabButton('Travel'));
    await tester.pumpAndSettle();
    expect(find.text('Built in Phase 5'), findsOneWidget);

    await tester.tap(tabButton('Planner'));
    await tester.pumpAndSettle();
    expect(find.text('Built in Phase 6'), findsOneWidget);
  });

  testWidgets('More shows which build is running', (tester) async {
    await pumpApp(tester, distribution: Distribution.store);

    await tester.tap(tabButton('More'));
    await tester.pumpAndSettle();
    expect(find.text('Store build'), findsOneWidget);
  });
}
