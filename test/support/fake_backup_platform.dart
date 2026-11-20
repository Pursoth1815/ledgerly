import 'dart:async';

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

  @override
  Future<BackupFolder?> pickFolder() async => (uri: 'content://tree/loopd', name: 'Phone › Loopd');

  @override
  Future<bool> canWrite(String folderUri) async => writable;

  @override
  Future<void> setUp(String passphrase) async {
    calls.add('setUp');
    keyMade = true;
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
}
