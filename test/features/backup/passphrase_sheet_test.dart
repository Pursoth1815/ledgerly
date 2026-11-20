import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/core/backup/backup_engine.dart';
import 'package:loopd/core/database/app_database.dart';
import 'package:loopd/design_system/components/loopd_button.dart';
import 'package:loopd/design_system/loopd_theme.dart';
import 'package:loopd/features/backup/presentation/passphrase_sheet.dart';

import '../../support/fake_backup_platform.dart';

/// Change passphrase and Forgot it?, with the native half faked.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Future<(FakeBackupPlatform, Completer<PassphraseOutcome?>)> pumpSheet(WidgetTester tester) async {
    final database = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    addTearDown(database.close);
    final work = Directory.systemTemp.createTempSync('loopd_passphrase_sheet');
    addTearDown(() => work.deleteSync(recursive: true));
    final platform = FakeBackupPlatform();
    final engine = BackupEngine(database, platform, workDir: () async => work);
    await tester.runAsync(
      () => engine.setUp(passphrase: 'a long made up phrase', folder: (uri: 'content://tree/l', name: 'Phone › Loopd')),
    );
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database), backupEngineProvider.overrideWithValue(engine)],
        child: MaterialApp(theme: loopdTheme(Brightness.dark), home: const Scaffold()),
      ),
    );
    final outcome = Completer<PassphraseOutcome?>();
    unawaited(showPassphraseSheet(tester.element(find.byType(Scaffold))).then(outcome.complete));
    await tester.pumpAndSettle();
    return (platform, outcome);
  }

  Future<void> type(WidgetTester tester, Key key, String text) async {
    await tester.enterText(find.descendant(of: find.byKey(key), matching: find.byType(TextField)), text);
    await tester.pump();
  }

  LoopdButton button(WidgetTester tester, String label) =>
      tester.widget<LoopdButton>(find.byWidgetPredicate((w) => w is LoopdButton && w.label == label));

  testWidgets('change: the current passphrase is checked, then the sheet says to back up', (tester) async {
    final (platform, outcome) = await pumpSheet(tester);
    expect(button(tester, 'Change and back up').onTap, isNull);
    await type(tester, PassphraseSheet.currentKey, 'not the current one');
    await type(tester, PassphraseSheet.newKey, 'a brand new phrase');
    await type(tester, PassphraseSheet.againKey, 'a brand new phrase');
    await tester.tap(find.text('Change and back up'));
    await tester.pumpAndSettle();
    expect(find.textContaining('That isn’t your current passphrase'), findsOneWidget);

    await type(tester, PassphraseSheet.currentKey, 'a long made up phrase');
    await tester.tap(find.text('Change and back up'));
    await tester.pumpAndSettle();
    expect(await outcome.future, PassphraseOutcome.changed);
    expect(platform.passphrase, 'a brand new phrase');
  });

  testWidgets('forgot: the new passphrase appears only after the phone confirms it is you', (tester) async {
    final (platform, outcome) = await pumpSheet(tester);
    await tester.tap(find.text('Forgot it?'));
    await tester.pumpAndSettle();
    expect(find.text('Forgot your passphrase'), findsOneWidget);
    expect(find.byKey(PassphraseSheet.newKey), findsNothing);

    await tester.tap(find.bySemanticsLabel('Check'));
    await tester.pumpAndSettle();
    expect(find.text('It’s you'), findsOneWidget);
    await type(tester, PassphraseSheet.newKey, 'a brand new phrase');
    await type(tester, PassphraseSheet.againKey, 'a brand new phrase');
    await tester.tap(find.text('Save new passphrase'));
    await tester.pump();
    expect(find.text('New backups use your new passphrase'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(await outcome.future, PassphraseOutcome.reset);
    expect(platform.calls, containsAllInOrder(['confirm', 'reset']));
  });

  testWidgets('forgot: a cancelled check keeps the new passphrase hidden; back returns to Change', (tester) async {
    final (platform, _) = await pumpSheet(tester);
    platform.ownerConfirms = false;
    await tester.tap(find.text('Forgot it?'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Check'));
    await tester.pumpAndSettle();
    expect(find.byKey(PassphraseSheet.newKey), findsNothing);
    await tester.state<NavigatorState>(find.byType(Navigator).first).maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Change passphrase'), findsOneWidget, reason: 'the phone’s back returns to Change');
  });

  testWidgets('the eye shows only its own box', (tester) async {
    await pumpSheet(tester);
    bool hidden(Key key) =>
        tester.widget<TextField>(find.descendant(of: find.byKey(key), matching: find.byType(TextField))).obscureText;
    await tester.tap(find.byTooltip('Show new passphrase'));
    await tester.pump();
    expect(hidden(PassphraseSheet.newKey), isFalse);
    expect(hidden(PassphraseSheet.currentKey), isTrue);
    expect(hidden(PassphraseSheet.againKey), isTrue);
    await tester.tap(find.byTooltip('Hide new passphrase'));
    await tester.pump();
    expect(hidden(PassphraseSheet.newKey), isTrue);
  });
}
