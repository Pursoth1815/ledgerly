import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/tables/backup.dart';

part 'backup_dao.g.dart';

/// Reads and writes the backup tables. Used only inside `core/backup`.
@DriftAccessor(tables: [BackupConfigs, BackupRuns])
class BackupDao extends DatabaseAccessor<AppDatabase> with _$BackupDaoMixin {
  BackupDao(super.attachedDatabase);

  Future<BackupConfig?> config() => select(backupConfigs).getSingleOrNull();

  Stream<BackupConfig?> watchConfig() => select(backupConfigs).watchSingleOrNull();

  Future<void> saveConfig({required String folderUri, required String folderName, required int setUpAt}) =>
      into(backupConfigs).insertOnConflictUpdate(
        BackupConfigsCompanion.insert(
          id: const Value(1),
          folderUri: folderUri,
          folderName: folderName,
          setUpAt: setUpAt,
        ),
      );

  Future<void> startRun(String id, String folderUri, int at) =>
      into(backupRuns)
          .insert(BackupRunsCompanion.insert(id: id, folderUri: folderUri, startedAt: at, status: 'written'));

  Future<void> markWritten(String id, List<String> files, int totalBytes) =>
      (update(backupRuns)..where((r) => r.id.equals(id))).write(
        BackupRunsCompanion(files: Value(jsonEncode(files)), totalBytes: Value(totalBytes)),
      );

  Future<void> finish(String id, {required bool verified, required int at}) =>
      (update(backupRuns)..where((r) => r.id.equals(id))).write(
        BackupRunsCompanion(status: Value(verified ? 'verified' : 'failed'), finishedAt: Value(at)),
      );

  /// Every run, newest first.
  Future<List<BackupRun>> runs() =>
      (select(backupRuns)..orderBy([(r) => OrderingTerm.desc(r.startedAt), (r) => OrderingTerm.desc(r.id)])).get();

  /// The newest verified run, as it changes.
  Stream<BackupRun?> watchLatestVerified() =>
      (select(backupRuns)
            ..where((r) => r.status.equals('verified'))
            ..orderBy([(r) => OrderingTerm.desc(r.startedAt)])
            ..limit(1))
          .watchSingleOrNull();

  /// The folder (if set up) and the newest verified run, emitted again when
  /// either table changes: (folder uri, folder name, finished at, bytes).
  Stream<(String?, String?, int?, int?)> watchSummary() =>
      customSelect(
        '''
    SELECT
      (SELECT folder_uri FROM backup_configs WHERE id = 1) AS folder_uri,
      (SELECT folder_name FROM backup_configs WHERE id = 1) AS folder_name,
      (SELECT finished_at FROM backup_runs WHERE status = 'verified' ORDER BY started_at DESC LIMIT 1) AS finished_at,
      (SELECT total_bytes FROM backup_runs WHERE status = 'verified' ORDER BY started_at DESC LIMIT 1) AS total_bytes
    ''',
        readsFrom: {backupConfigs, backupRuns},
      ).watchSingle().map(
        (row) => (
          row.readNullable<String>('folder_uri'),
          row.readNullable<String>('folder_name'),
          row.readNullable<int>('finished_at'),
          row.readNullable<int>('total_bytes'),
        ),
      );

  Future<void> deleteRun(String id) => (delete(backupRuns)..where((r) => r.id.equals(id))).go();
}

extension BackupRunFiles on BackupRun {
  List<String> get fileNames => (jsonDecode(files) as List<dynamic>).cast<String>();
}
