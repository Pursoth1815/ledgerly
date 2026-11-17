import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/tables/background.dart';

part 'job_checkpoints_dao.g.dart';

/// Reads and writes [JobCheckpoints]. Used only inside `core/background`.
@DriftAccessor(tables: [JobCheckpoints])
class JobCheckpointsDao extends DatabaseAccessor<AppDatabase> with _$JobCheckpointsDaoMixin {
  JobCheckpointsDao(super.attachedDatabase, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  Future<JobCheckpoint?> read(String kind) =>
      (select(jobCheckpoints)..where((row) => row.kind.equals(kind))).getSingleOrNull();

  Future<void> save(String kind, {required int step, required int resumes}) =>
      into(jobCheckpoints).insertOnConflictUpdate(
        JobCheckpointsCompanion.insert(
          kind: kind,
          step: step,
          resumes: Value(resumes),
          updatedAt: _clock().toUtc().millisecondsSinceEpoch,
        ),
      );

  Future<void> clear(String kind) => (delete(jobCheckpoints)..where((row) => row.kind.equals(kind))).go();
}
