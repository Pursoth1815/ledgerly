import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/app_database.dart';
import 'settings_dao.dart';

part 'theme_setting.g.dart';

/// Stores the owner's theme choice.
///
/// Until the owner flips the Dark theme switch, Loopd follows the phone's
/// own light or dark setting ([ThemeMode.system]). After that, the choice is
/// remembered in the database.
class ThemeSettingStore {
  ThemeSettingStore(AppDatabase database) : _dao = SettingsDao(database);

  static const key = 'appearance.theme';

  final SettingsDao _dao;

  Future<ThemeMode> load() async => switch (await _dao.read(key)) {
    'dark' => ThemeMode.dark,
    'light' => ThemeMode.light,
    _ => ThemeMode.system,
  };

  Future<void> save(ThemeMode mode) => switch (mode) {
    ThemeMode.dark => _dao.write(key, 'dark'),
    ThemeMode.light => _dao.write(key, 'light'),
    ThemeMode.system => _dao.remove(key),
  };
}

/// The theme choice read in `bootstrap()` before the first frame, so the app
/// never flashes the wrong theme. Overridden there.
@Riverpod(keepAlive: true)
ThemeMode initialThemeMode(Ref ref) => ThemeMode.system;

/// The current theme choice. Widgets watch it; the theme switches change it.
@Riverpod(keepAlive: true)
class ThemeSetting extends _$ThemeSetting {
  @override
  ThemeMode build() => ref.watch(initialThemeModeProvider);

  /// Turns the Dark theme on or off, and remembers it.
  Future<void> setDark({required bool dark}) async {
    final mode = dark ? ThemeMode.dark : ThemeMode.light;
    state = mode;
    await ThemeSettingStore(ref.read(appDatabaseProvider)).save(mode);
  }
}
