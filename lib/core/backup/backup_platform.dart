import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../errors/app_exception.dart';
import '../platform/platform_api.g.dart';

part 'backup_platform.g.dart';

/// A folder picked for backups.
typedef BackupFolder = ({String uri, String name});

/// What a backup run wrote.
typedef WrittenRun = ({String indexName, List<String> files, int totalBytes});

/// A backup found in a folder, from its file names.
typedef FoundBackup = ({String indexName, String runId, int parts, int totalBytes});

/// What an unlocked backup says about itself.
typedef OpenedBackup = ({String runId, DateTime createdAt, String appVersion, int schemaVersion, int parts});

/// The native half of backup (ADR 0011): the folder picker, the backup key and
/// the encrypted files. An interface so the engine can be tested without a
/// phone. Every failure arrives as a [BackupException].
abstract interface class BackupPlatform {
  Future<BackupFolder?> pickFolder();
  Future<bool> canWrite(String folderUri);
  Future<void> setUp(String passphrase);
  Future<bool> isSetUp();
  Future<WrittenRun> write({
    required String runId,
    required String folderUri,
    required String databasePath,
    required String databaseKeyHex,
    required DateTime createdAt,
    required int schemaVersion,
  });
  Future<void> verify({required String folderUri, required String indexName});
  Future<void> delete({required String folderUri, required List<String> names});

  /// The backups in [folderUri], newest first.
  Future<List<FoundBackup>> listBackups(String folderUri);

  /// Unlocks a backup with its passphrase and reads what it holds.
  Future<OpenedBackup> openBackup({required String folderUri, required String indexName, required String passphrase});

  /// Reads every part of the opened backup back.
  Future<void> verifyOpenedBackup();

  /// Writes the opened backup's database copy to [targetPath]; returns its key (hex).
  Future<String> extractOpenedDatabase(String targetPath);

  /// Starts Loopd again.
  Future<void> restartApp();
}

/// [BackupPlatform] over the Pigeon [BackupApi].
class PigeonBackupPlatform implements BackupPlatform {
  PigeonBackupPlatform([BackupApi? api]) : _api = api ?? BackupApi();

  final BackupApi _api;

  Future<T> _call<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PlatformException catch (e) {
      throw BackupException(BackupFailure.fromCode(e.code));
    }
  }

  @override
  Future<BackupFolder?> pickFolder() => _call(() async {
    final info = await _api.pickFolder();
    return info == null ? null : (uri: info.uri, name: info.name);
  });

  @override
  Future<bool> canWrite(String folderUri) => _call(() => _api.canWrite(folderUri));

  @override
  Future<void> setUp(String passphrase) => _call(() => _api.setUp(passphrase));

  @override
  Future<bool> isSetUp() => _call(_api.isSetUp);

  @override
  Future<WrittenRun> write({
    required String runId,
    required String folderUri,
    required String databasePath,
    required String databaseKeyHex,
    required DateTime createdAt,
    required int schemaVersion,
  }) => _call(() async {
    final written = await _api.writeBackup(
      BackupRequest(
        runId: runId,
        folderUri: folderUri,
        databasePath: databasePath,
        databaseKeyHex: databaseKeyHex,
        createdAt: createdAt.toUtc().millisecondsSinceEpoch,
        // Filled in by Android from the installed package.
        appVersion: '',
        schemaVersion: schemaVersion,
      ),
    );
    return (indexName: written.indexName, files: written.files, totalBytes: written.totalBytes);
  });

  @override
  Future<void> verify({required String folderUri, required String indexName}) =>
      _call(() => _api.verifyBackup(folderUri, indexName));

  @override
  Future<void> delete({required String folderUri, required List<String> names}) =>
      _call(() => _api.deleteFiles(folderUri, names));

  @override
  Future<List<FoundBackup>> listBackups(String folderUri) => _call(() async {
    final found = await _api.listBackups(folderUri);
    return [for (final f in found) (indexName: f.indexName, runId: f.runId, parts: f.parts, totalBytes: f.totalBytes)];
  });

  @override
  Future<OpenedBackup> openBackup({required String folderUri, required String indexName, required String passphrase}) =>
      _call(() async {
        final o = await _api.openBackup(folderUri, indexName, passphrase);
        return (
          runId: o.runId,
          createdAt: DateTime.fromMillisecondsSinceEpoch(o.createdAt, isUtc: true).toLocal(),
          appVersion: o.appVersion,
          schemaVersion: o.schemaVersion,
          parts: o.parts,
        );
      });

  @override
  Future<void> verifyOpenedBackup() => _call(_api.verifyOpenedBackup);

  @override
  Future<String> extractOpenedDatabase(String targetPath) => _call(() => _api.extractOpenedDatabase(targetPath));

  @override
  Future<void> restartApp() => _call(_api.restartApp);
}

/// The native backup bridge; replaced in tests.
@Riverpod(keepAlive: true)
BackupPlatform backupPlatform(Ref ref) => PigeonBackupPlatform();
