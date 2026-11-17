import 'package:drift/drift.dart';

/// App settings as key and value (Phase 1). Owned by `core/settings`; each
/// setting has one key and stores its value as text.
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  /// Milliseconds since the epoch, UTC.
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
