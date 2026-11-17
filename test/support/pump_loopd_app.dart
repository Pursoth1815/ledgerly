import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/app/app.dart';
import 'package:loopd/app/config/app_config.dart';
import 'package:loopd/core/database/app_database.dart';
import 'package:loopd/core/settings/theme_setting.dart';

/// Pumps the whole app on an in-memory database. Returns the database so a
/// test can check what was saved.
Future<AppDatabase> pumpLoopdApp(
  WidgetTester tester, {
  Distribution distribution = Distribution.personal,
  ThemeMode theme = ThemeMode.dark,
}) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig(distribution: distribution)),
        appDatabaseProvider.overrideWithValue(database),
        initialThemeModeProvider.overrideWithValue(theme),
      ],
      child: const LoopdApp(),
    ),
  );
  await tester.pumpAndSettle();
  return database;
}
