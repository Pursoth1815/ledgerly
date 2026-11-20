// Drift's column CHECK constraints name the column inside its own getter
// (`status.isIn(...)`), which this lint misreads as recursion.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

// Backup records (ADR 0011), owned by `core/backup`. Times are UTC
// milliseconds.

/// Where backups go, once backup is set up. One row at most.
class BackupConfigs extends Table {
  IntColumn get id => integer().check(id.equals(1))();

  /// The folder picked in the system picker (a tree URI), and what to show.
  TextColumn get folderUri => text()();
  TextColumn get folderName => text()();
  IntColumn get setUpAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  bool get isStrict => true;
}

/// Every backup run Loopd wrote, so it removes only its own files and keeps
/// the last three good ones.
class BackupRuns extends Table {
  /// Also in the file names: `loopd-<id>.lpdb`.
  TextColumn get id => text()();
  TextColumn get folderUri => text()();
  IntColumn get startedAt => integer()();

  /// written (not yet read back), verified, or failed.
  TextColumn get status => text().check(status.isIn(const ['written', 'verified', 'failed']))();

  /// The files of the run, as a JSON list; empty until written.
  TextColumn get files => text().withDefault(const Constant('[]'))();
  IntColumn get totalBytes => integer().withDefault(const Constant(0))();
  IntColumn get finishedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  bool get isStrict => true;
}
