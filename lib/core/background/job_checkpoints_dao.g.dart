// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_checkpoints_dao.dart';

// ignore_for_file: type=lint
mixin _$JobCheckpointsDaoMixin on DatabaseAccessor<AppDatabase> {
  $JobCheckpointsTable get jobCheckpoints => attachedDatabase.jobCheckpoints;
  JobCheckpointsDaoManager get managers => JobCheckpointsDaoManager(this);
}

class JobCheckpointsDaoManager {
  final _$JobCheckpointsDaoMixin _db;
  JobCheckpointsDaoManager(this._db);
  $$JobCheckpointsTableTableManager get jobCheckpoints =>
      $$JobCheckpointsTableTableManager(_db.attachedDatabase, _db.jobCheckpoints);
}
