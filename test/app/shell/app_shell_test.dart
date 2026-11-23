import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/app/config/app_config.dart';
import 'package:loopd/app/shell/app_shell.dart';
import 'package:loopd/app/shell/loopd_tab_bar.dart';
import 'package:loopd/design_system/loopd_colors.dart';
import 'package:loopd/features/expenses/expenses.dart';

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
    for (final (tab, phase) in [('Travel', 5), ('Planner', 6)]) {
      await tester.tap(tabButton(tab));
      await tester.pumpAndSettle();
      expect(find.text('Built in Phase $phase'), findsOneWidget);
    }
  });

  testWidgets('the Money tab shows spending (Phase 2)', (tester) async {
    await pumpLoopdApp(tester);
    await tester.tap(tabButton('Money'));
    await tester.pumpAndSettle();
    expect(find.byType(MoneyScreen), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Nothing spent in this period.'),
      200,
      scrollable: find.descendant(of: find.byType(MoneyScreen), matching: find.byType(Scrollable)).first,
    );
    expect(find.text('Nothing spent in this period.'), findsOneWidget);
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

  testWidgets("the capture sheet's Expense shortcut opens the expense form in its place", (tester) async {
    await pumpLoopdApp(tester);
    await tester.tap(find.bySemanticsLabel('Add anything'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('New Expense'));
    await tester.pumpAndSettle();
    expect(find.text('Or start from'), findsNothing, reason: 'the capture sheet closes');
    expect(find.text('Add expense'), findsOneWidget);
    expect(find.byKey(ExpenseSheet.formKey), findsOneWidget, reason: 'loaded by the time it is up');
    expect(find.text('No bank accounts yet. UPI is paid from one.'), findsOneWidget);

    await tester.ensureVisible(find.text('+ Add bank account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+ Add bank account'));
    await tester.pumpAndSettle();
    expect(find.text('Add bank account'), findsWidgets, reason: 'the Add sheet opens on top');
  });

  group('the capture button steps aside while a sheet is open', () {
    Finder tappableButton() => find.byType(CaptureButton).hitTestable();

    testWidgets('the capture sheet itself, opened from the root', (tester) async {
      await pumpLoopdApp(tester);
      expect(tappableButton(), findsOneWidget);
      await tester.tap(tappableButton());
      await tester.pumpAndSettle();
      expect(tappableButton(), findsNothing);
      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pumpAndSettle();
      expect(tappableButton(), findsOneWidget);
    });

    testWidgets('sheets opened inside a tab, and sheets on top of them', (tester) async {
      await pumpLoopdApp(tester);
      await tester.tap(tabButton('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Accounts and cards'));
      await tester.pumpAndSettle();
      expect(tappableButton(), findsNothing, reason: 'Accounts and cards is a sheet');

      for (final opener in ['+ Add account or card']) {
        await tester.ensureVisible(find.text(opener));
        await tester.pumpAndSettle();
        await tester.tap(find.text(opener));
        await tester.pumpAndSettle();
        expect(tappableButton(), findsNothing, reason: opener);
        await tester.tap(find.bySemanticsLabel('Close').last);
        await tester.pumpAndSettle();
        expect(tappableButton(), findsNothing, reason: '$opener closed, Accounts and cards still open');
      }
      await tester.state<NavigatorState>(find.byType(Navigator).first).maybePop();
      await tester.pumpAndSettle();
      expect(tappableButton(), findsOneWidget, reason: 'every sheet closed');
    });
  });

  testWidgets('More shows which build is running', (tester) async {
    await pumpLoopdApp(tester, distribution: Distribution.store);
    await tester.tap(tabButton('More'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Store build'), 200);
    expect(find.text('Store build'), findsOneWidget);
  });
}
