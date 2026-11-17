import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/core/database/app_database.dart';
import 'package:loopd/core/settings/theme_setting.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test('follows the phone until the owner chooses', () async {
    expect(await ThemeSettingStore(database).load(), ThemeMode.system);
  });

  test('the switch remembers dark and light', () async {
    final container = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(database)]);
    addTearDown(container.dispose);
    final setting = container.read(themeSettingProvider.notifier);

    await setting.setDark(dark: true);
    expect(container.read(themeSettingProvider), ThemeMode.dark);
    expect(await ThemeSettingStore(database).load(), ThemeMode.dark);

    await setting.setDark(dark: false);
    expect(container.read(themeSettingProvider), ThemeMode.light);
    expect(await ThemeSettingStore(database).load(), ThemeMode.light);
  });

  test('starts from the choice read at start-up', () {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        initialThemeModeProvider.overrideWithValue(ThemeMode.light),
      ],
    );
    addTearDown(container.dispose);
    expect(container.read(themeSettingProvider), ThemeMode.light);
  });
}
