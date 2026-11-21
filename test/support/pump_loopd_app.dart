import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/app/app.dart';
import 'package:loopd/app/config/app_config.dart';
import 'package:loopd/core/database/app_database.dart';
import 'package:loopd/core/security/device_auth.dart';
import 'package:loopd/core/settings/app_lock_setting.dart';
import 'package:loopd/core/settings/theme_setting.dart';
import 'package:loopd/features/app_lock/app_lock.dart';

import 'fake_device_auth.dart';

/// Pumps the whole app on an in-memory database. Returns the database so a
/// test can check what was saved.
Future<AppDatabase> pumpLoopdApp(
  WidgetTester tester, {
  Distribution distribution = Distribution.personal,
  ThemeMode theme = ThemeMode.dark,
  AppLockSettings appLock = const AppLockSettings(),
  DeviceAuth? device,
  DateTime Function()? lockClock,
}) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  // Drift otherwise closes streams on a timer, which a widget test reports
  // as still pending.
  final database = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
  addTearDown(database.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig(distribution: distribution)),
        appDatabaseProvider.overrideWithValue(database),
        initialThemeModeProvider.overrideWithValue(theme),
        initialAppLockProvider.overrideWithValue(appLock),
        deviceAuthProvider.overrideWithValue(device ?? FakeDeviceAuth()),
        if (lockClock != null) appLockClockProvider.overrideWithValue(lockClock),
      ],
      child: const LoopdApp(),
    ),
  );
  await tester.pumpAndSettle();
  return database;
}
