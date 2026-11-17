import 'package:drift/drift.dart';

/// Where each long background job got to (ADR 0013), so a job that Android
/// stops continues from its last finished step. Owned by `core/background`.
class JobCheckpoints extends Table {
  /// The job kind, for example `self_test.long`.
  TextColumn get kind => text()();

  /// The last finished step.
  IntColumn get step => integer()();

  /// How many times the job has continued from a checkpoint.
  IntColumn get resumes => integer().withDefault(const Constant(0))();

  /// Milliseconds since the epoch, UTC.
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {kind};
}
