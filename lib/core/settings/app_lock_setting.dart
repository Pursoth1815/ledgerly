import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/app_database.dart';
import 'settings_dao.dart';

part 'app_lock_setting.g.dart';

/// App lock's settings (proposal section 11): on or off, and how long Loopd
/// may be away before it asks again.
class AppLockSettings {
  const AppLockSettings({this.enabled = false, this.afterMinutes = defaultAfterMinutes});

  /// The choices offered (owner, 21 Nov 2026): 0 is "Now".
  static const choices = [0, 1, 5, 15];
  static const defaultAfterMinutes = 1;

  final bool enabled;
  final int afterMinutes;

  AppLockSettings copyWith({bool? enabled, int? afterMinutes}) =>
      AppLockSettings(enabled: enabled ?? this.enabled, afterMinutes: afterMinutes ?? this.afterMinutes);
}

class AppLockSettingStore {
  AppLockSettingStore(AppDatabase database) : _dao = SettingsDao(database);

  static const enabledKey = 'privacy.app_lock';
  static const afterKey = 'privacy.app_lock_after_minutes';

  final SettingsDao _dao;

  Future<AppLockSettings> load() async {
    final after = int.tryParse(await _dao.read(afterKey) ?? '');
    return AppLockSettings(
      enabled: await _dao.read(enabledKey) == 'on',
      afterMinutes: AppLockSettings.choices.contains(after) ? after! : AppLockSettings.defaultAfterMinutes,
    );
  }

  Future<void> save(AppLockSettings settings) async {
    if (settings.enabled) {
      await _dao.write(enabledKey, 'on');
    } else {
      await _dao.remove(enabledKey);
    }
    await _dao.write(afterKey, '${settings.afterMinutes}');
  }
}

/// The settings read in `bootstrap()` before the first frame, so a locked
/// app never shows its content first. Overridden there.
@Riverpod(keepAlive: true)
AppLockSettings initialAppLock(Ref ref) => const AppLockSettings();
