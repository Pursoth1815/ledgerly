import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/tables/settings.dart';

part 'settings_dao.g.dart';

/// Reads and writes [AppSettings]. Used only inside `core/settings`.
@DriftAccessor(tables: [AppSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.attachedDatabase, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  Future<String?> read(String key) async =>
      (await (select(appSettings)..where((row) => row.key.equals(key))).getSingleOrNull())?.value;

  Future<void> write(String key, String value) => into(appSettings).insertOnConflictUpdate(
    AppSettingsCompanion.insert(key: key, value: value, updatedAt: _clock().toUtc().millisecondsSinceEpoch),
  );

  Future<void> remove(String key) => (delete(appSettings)..where((row) => row.key.equals(key))).go();
}
