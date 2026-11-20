import 'dart:async';
import 'dart:io';

import 'package:loopd/core/backup/backup_platform.dart';
import 'package:loopd/core/errors/app_exception.dart';

/// The native half, faked: it records what it was asked and can fail on cue.
class FakeBackupPlatform implements BackupPlatform {
  bool keyMade = false;
  bool writable = true;
  int verifyFailures = 0;
  final calls = <String>[];
  final deleted = <List<String>>[];

  /// Inspects the database copy while it exists (the engine deletes it after).
  void Function(String path, String keyHex)? onWrite;
  Completer<void>? holdWrite;

  /// The last database copy written, kept so a restore can hand it back:
  /// (bytes, key). As a real backup holds it.
  (List<int>, String)? lastCopy;

  /// The passphrase the backup was "made" with; any other fails to open it.
  String passphrase = '';

  /// The schema version the "backup" reports.
  int? backupSchemaVersion;

  @override
  Future<BackupFolder?> pickFolder() async => (uri: 'content://tree/loopd', name: 'Phone › Loopd');

  @override
  Future<bool> canWrite(String folderUri) async => writable;

  @override
  Future<void> setUp(String passphrase) async {
    calls.add('setUp');
    keyMade = true;
    this.passphrase = passphrase;
  }

  @override
  Future<bool> isSetUp() async => keyMade;

  @override
  Future<WrittenRun> write({
    required String runId,
    required String folderUri,
    required String databasePath,
    required String databaseKeyHex,
    required DateTime createdAt,
    required int schemaVersion,
  }) async {
    calls.add('write');
    onWrite?.call(databasePath, databaseKeyHex);
    lastCopy = (File(databasePath).readAsBytesSync(), databaseKeyHex);
    await holdWrite?.future;
    final files = ['loopd-$runId-p0001.lpdp', 'loopd-$runId.lpdb'];
    return (indexName: files.last, files: files, totalBytes: 4096);
  }

  @override
  Future<void> verify({required String folderUri, required String indexName}) async {
    calls.add('verify');
    if (verifyFailures > 0) {
      verifyFailures--;
      throw const BackupException(BackupFailure.verifyFailed);
    }
  }

  @override
  Future<void> delete({required String folderUri, required List<String> names}) async => deleted.add(names);

  @override
  Future<List<FoundBackup>> listBackups(String folderUri) async => [
    (indexName: 'loopd-20261115-020000-aaaa.lpdb', runId: '20261115-020000-aaaa', parts: 1, totalBytes: 44_600),
    (indexName: 'loopd-20261108-020000-bbbb.lpdb', runId: '20261108-020000-bbbb', parts: 1, totalBytes: 41_000),
  ];

  @override
  Future<OpenedBackup> openBackup({
    required String folderUri,
    required String indexName,
    required String passphrase,
  }) async {
    calls.add('open');
    if (passphrase != this.passphrase) throw const BackupException(BackupFailure.wrongPassphrase);
    return (
      runId: '20261115-020000-aaaa',
      createdAt: DateTime(2026, 11, 15, 2),
      appVersion: '0.1.0+1',
      schemaVersion: backupSchemaVersion ?? 8,
      parts: 1,
    );
  }

  @override
  Future<void> verifyOpenedBackup() async => calls.add('check');

  @override
  Future<String> extractOpenedDatabase(String targetPath) async {
    calls.add('extract');
    final (bytes, key) = lastCopy ?? (throw const BackupException(BackupFailure.notABackup));
    File(targetPath).writeAsBytesSync(bytes);
    return key;
  }

  @override
  Future<void> restartApp() async => calls.add('restart');
}
