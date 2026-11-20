import '../../../core/errors/app_exception.dart';

/// What to tell the owner when a backup step fails.
String backupFailureText(BackupFailure failure) => switch (failure) {
  BackupFailure.folderLost => 'Loopd can’t reach the backup folder any more. Choose it again with Change.',
  BackupFailure.outOfSpace => 'The backup folder is full. Free some space there, then back up again.',
  BackupFailure.verifyFailed =>
    'The new backup didn’t read back correctly, so it was removed. Your older backups are untouched. Try again.',
  BackupFailure.keystoreUnavailable => 'The phone’s secure key storage didn’t respond. Try again.',
  BackupFailure.notSetUp => 'Set up backup first.',
  BackupFailure.busy => 'A backup is already running.',
  BackupFailure.cancelled => 'Cancelled.',
  BackupFailure.wrongPassphrase ||
  BackupFailure.notABackup ||
  BackupFailure.writeFailed => 'The backup couldn’t be written. Try again.',
};
