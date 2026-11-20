// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_dao.dart';

// ignore_for_file: type=lint
mixin _$BackupDaoMixin on DatabaseAccessor<AppDatabase> {
  $BackupConfigsTable get backupConfigs => attachedDatabase.backupConfigs;
  $BackupRunsTable get backupRuns => attachedDatabase.backupRuns;
  BackupDaoManager get managers => BackupDaoManager(this);
}

class BackupDaoManager {
  final _$BackupDaoMixin _db;
  BackupDaoManager(this._db);
  $$BackupConfigsTableTableManager get backupConfigs =>
      $$BackupConfigsTableTableManager(_db.attachedDatabase, _db.backupConfigs);
  $$BackupRunsTableTableManager get backupRuns => $$BackupRunsTableTableManager(_db.attachedDatabase, _db.backupRuns);
}
