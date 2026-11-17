import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/app/config/app_config.dart';
import 'package:loopd/app/shell/loopd_tab_bar.dart';
import 'package:loopd/app/shell/more_page.dart';
import 'package:loopd/core/settings/theme_setting.dart';
import 'package:loopd/design_system/components/loopd_switch.dart';

import '../../support/pump_loopd_app.dart';

void main() {
  Future<void> openMore(WidgetTester tester) async {
    await tester.tap(find.descendant(of: find.byType(LoopdTabBar), matching: find.text('More')));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the tiles and the four settings groups', (tester) async {
    await pumpLoopdApp(tester);
    await openMore(tester);
    for (final text in ['Vault', 'Screen time', 'Money', 'Accounts and cards', 'Expense categories', 'SMS detection']) {
      expect(
        find.descendant(of: find.byType(MorePage), matching: find.text(text)),
        findsOneWidget,
        reason: text,
      );
    }
    await tester.scrollUntilVisible(find.text('Dark theme'), 200);
    for (final text in ['Reminders', 'Task reminders', 'Privacy and backup', 'Backup & restore', 'Appearance']) {
      expect(
        find.descendant(of: find.byType(MorePage), matching: find.text(text)),
        findsOneWidget,
        reason: text,
      );
    }
  });

  testWidgets('the store build has no SMS detection row', (tester) async {
    await pumpLoopdApp(tester, distribution: Distribution.store);
    await openMore(tester);
    expect(find.text('SMS detection'), findsNothing);
  });

  testWidgets('switches for features not built yet cannot be turned on', (tester) async {
    await pumpLoopdApp(tester);
    await openMore(tester);
    LoopdSwitch switchFor(String label) =>
        tester.widget<LoopdSwitch>(find.byWidgetPredicate((widget) => widget is LoopdSwitch && widget.label == label));
    expect(switchFor('SMS detection').onChanged, isNull);
    await tester.scrollUntilVisible(find.text('Dark theme'), 200);
    expect(switchFor('Task reminders').onChanged, isNull);
    expect(switchFor('Dark theme').onChanged, isNotNull);
  });

  testWidgets('the Dark theme switch changes the theme and remembers it', (tester) async {
    final database = await pumpLoopdApp(tester);
    await openMore(tester);
    // Scroll to the end, as a person would, so the switch is clear of the
    // floating capture button.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
    await tester.pumpAndSettle();

    await tester.tap(find.byWidgetPredicate((widget) => widget is LoopdSwitch && widget.label == 'Dark theme'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.text('Dark theme'))).brightness, Brightness.light);
    expect(await ThemeSettingStore(database).load(), ThemeMode.light);
  });

  testWidgets('a row not built yet says which phase builds it', (tester) async {
    await pumpLoopdApp(tester);
    await openMore(tester);
    await tester.tap(find.text('Accounts and cards'));
    await tester.pump();
    expect(find.text('Accounts and cards is built in Phase 2'), findsOneWidget);
  });
}
