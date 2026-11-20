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
import 'package:loopd/design_system/components/loopd_switch.dart';
import 'package:loopd/design_system/loopd_theme.dart';
import 'package:loopd/features/backup/backup.dart';
import 'package:loopd/features/backup/presentation/backup_setup_sheet.dart';

import '../../support/fake_backup_platform.dart';

/// The Backup & restore sheet on a phone-sized screen, with the native half faked.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final now = DateTime(2026, 11, 18, 9);

  Future<(BackupEngine, FakeBackupPlatform)> pumpPage(WidgetTester tester) async {
    final database = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    addTearDown(database.close);
    final work = Directory.systemTemp.createTempSync('loopd_backup_page');
    addTearDown(() => work.deleteSync(recursive: true));
    final platform = FakeBackupPlatform();
    final engine = BackupEngine(database, platform, workDir: () async => work, clock: () => now);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database), backupEngineProvider.overrideWithValue(engine)],
        child: MaterialApp(theme: loopdTheme(Brightness.dark), home: const Scaffold()),
      ),
    );
    unawaited(showBackupSheet(tester.element(find.byType(Scaffold)), clock: () => now));
    await tester.pumpAndSettle();
    return (engine, platform);
  }

  LoopdButton button(WidgetTester tester, String label) =>
      tester.widget<LoopdButton>(find.byWidgetPredicate((w) => w is LoopdButton && w.label == label));

  testWidgets('before setup the card offers Set up backup, and nothing else of backup shows', (tester) async {
    await pumpPage(tester);
    expect(find.text('Backups are off'), findsOneWidget);
    expect(find.text('Set up backup'), findsOneWidget);
    expect(find.text('Save to'), findsNothing);
    expect(find.text('Restore from a backup file'), findsOneWidget);
  });

  testWidgets('setup: both checks and a folder turn the button on; then the first backup runs', (tester) async {
    final (_, platform) = await pumpPage(tester);
    await tester.tap(find.bySemanticsLabel('Set up backup'));
    await tester.pumpAndSettle();
    expect(find.byType(BackupSetupSheet), findsOneWidget);
    expect(button(tester, 'Turn on and back up now').onTap, isNull);

    await tester.enterText(
      find.descendant(of: find.byKey(BackupSetupSheet.passphraseKey), matching: find.byType(TextField)),
      'short',
    );
    await tester.pump();
    expect(find.bySemanticsLabel('At least 12 characters, not yet'), findsOneWidget);
    await tester.enterText(
      find.descendant(of: find.byKey(BackupSetupSheet.passphraseKey), matching: find.byType(TextField)),
      'a long made up phrase',
    );
    await tester.enterText(
      find.descendant(of: find.byKey(BackupSetupSheet.againKey), matching: find.byType(TextField)),
      'a long made up phrase',
    );
    await tester.pump();
    expect(find.bySemanticsLabel('At least 12 characters, done'), findsOneWidget);
    expect(find.bySemanticsLabel('Both match, done'), findsOneWidget);
    expect(button(tester, 'Turn on and back up now').onTap, isNull, reason: 'no folder yet');

    await tester.tap(find.bySemanticsLabel('Choose a folder'));
    await tester.pumpAndSettle();
    expect(find.text('Phone › Loopd'), findsOneWidget);
    await tester.tap(find.text('Turn on and back up now'));
    await tester.pumpAndSettle();

    expect(find.byType(BackupSetupSheet), findsNothing);
    expect(platform.calls, ['setUp', 'write', 'verify']);
    expect(find.text('Backed up just now'), findsOneWidget);
    expect(find.text('Phone › Loopd · picked with the phone’s file picker'), findsOneWidget);
    expect(find.text('In every backup · 4 KB'), findsOneWidget);
  });

  testWidgets('Back up now shows when it fails, in the red box', (tester) async {
    final (engine, platform) = await pumpPage(tester);
    await tester.runAsync(
      () => engine.setUp(
        passphrase: 'a long made up phrase',
        folder: (uri: 'content://tree/loopd', name: 'Phone › Loopd'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No backup yet'), findsOneWidget);
    platform.writable = false;
    await tester.tap(find.bySemanticsLabel('Back up now'));
    await tester.pumpAndSettle();
    expect(find.textContaining('can’t reach the backup folder'), findsOneWidget);
  });

  testWidgets('weekly is off until Phase 7; passphrase changes say when they come; Restore opens its sheet', (
    tester,
  ) async {
    final (engine, _) = await pumpPage(tester);
    await tester.runAsync(
      () => engine.setUp(
        passphrase: 'a long made up phrase',
        folder: (uri: 'content://tree/loopd', name: 'Phone › Loopd'),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<LoopdSwitch>(find.byType(LoopdSwitch)).onChanged, isNull);
    await tester.tap(find.bySemanticsLabel('Change').last);
    await tester.pump();
    expect(find.text('Changing the passphrase comes in the next update'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    await tester.ensureVisible(find.text('Restore from a backup file'));
    await tester.tap(find.text('Restore from a backup file'));
    await tester.pumpAndSettle();
    expect(find.text('Restore from a backup'), findsOneWidget, reason: 'the restore sheet opens');
  });
}
