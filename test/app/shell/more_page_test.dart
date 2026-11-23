import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/app/config/app_config.dart';
import 'package:loopd/app/shell/loopd_tab_bar.dart';
import 'package:loopd/app/shell/more_page.dart';
import 'package:loopd/core/settings/theme_setting.dart';
import 'package:loopd/design_system/components/loopd_switch.dart';
import 'package:loopd/features/accounts/accounts.dart';
import 'package:loopd/features/backup/backup.dart';
import 'package:loopd/features/expenses/expenses.dart';

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
    await tester.tap(find.descendant(of: find.byType(MorePage), matching: find.text('Vault')));
    await tester.pump();
    expect(find.text('The Vault is built in Phase 7'), findsOneWidget);
  });

  testWidgets('Backup & restore opens as a sheet over the tab bar', (tester) async {
    await pumpLoopdApp(tester);
    await openMore(tester);
    // Scroll to the end, so the row is clear of the floating capture button.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Backup & restore'));
    await tester.pumpAndSettle();
    expect(find.byType(BackupSheet), findsOneWidget);
    expect(find.text('Backups are off'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(LoopdTabBar), matching: find.text('Money')).hitTestable(),
      findsNothing,
      reason: 'the tab bar sits behind the sheet',
    );
    expect(find.bySemanticsLabel('Back to More'), findsNothing, reason: 'a sheet, not a page');
    // The phone's back closes it.
    await tester.state<NavigatorState>(find.byType(Navigator).first).maybePop();
    await tester.pumpAndSettle();
    expect(find.byType(BackupSheet), findsNothing);
  });

  testWidgets('Expense categories opens its sheet', (tester) async {
    await pumpLoopdApp(tester);
    await openMore(tester);
    await tester.tap(find.text('Expense categories'));
    await tester.pumpAndSettle();
    expect(find.byType(CategorySheet), findsOneWidget);
    expect(find.byKey(CategorySheet.listKey), findsOneWidget, reason: 'loaded by the time it is up');
  });

  testWidgets('Accounts and cards opens as a sheet over the tab bar', (tester) async {
    await pumpLoopdApp(tester);
    await openMore(tester);
    expect(find.text('0 · 0'), findsNothing, reason: 'no count on the row (owner, 18 Nov 2026)');
    await tester.tap(find.text('Accounts and cards'));
    await tester.pumpAndSettle();
    expect(find.byType(AccountsSheet), findsOneWidget);
    expect(find.byKey(AccountsSheet.listKey), findsOneWidget, reason: 'loaded by the time it is up');
    expect(
      find.descendant(of: find.byType(LoopdTabBar), matching: find.text('Money')).hitTestable(),
      findsNothing,
      reason: 'the tab bar sits behind the sheet',
    );

    await tester.state<NavigatorState>(find.byType(Navigator).first).maybePop();
    await tester.pumpAndSettle();
    expect(find.byType(AccountsSheet), findsNothing);
    await tester.tap(find.descendant(of: find.byType(LoopdTabBar), matching: find.text('Money')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(LoopdTabBar), matching: find.text('More')));
    await tester.pumpAndSettle();
    expect(find.byType(MorePage), findsOneWidget, reason: 'More comes back as More');
    expect(find.byType(AccountsSheet), findsNothing);
  });
}
