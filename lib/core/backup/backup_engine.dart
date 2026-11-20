import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/app_database.dart';
import '../database/database_opener.dart';
import '../database/encrypted_executor.dart';
import '../errors/app_exception.dart';
import '../ledger/ledger_engine.dart';
import '../platform/platform_api.g.dart';
import '../security/database_key_store.dart';
import 'backup_dao.dart';
import 'backup_platform.dart';

part 'backup_engine.g.dart';

/// Where backup stands, for the Backup & restore page.
class BackupStatus {
  const BackupStatus({required this.isSetUp, this.folderUri, this.folderName, this.lastBackupAt, this.lastBackupBytes});

  /// A backup key and a folder exist.
  final bool isSetUp;
  final String? folderUri;

  /// Such as "Drive › Loopd backups".
  final String? folderName;

  /// The newest backup that was read back and found good.
  final DateTime? lastBackupAt;
  final int? lastBackupBytes;
}

/// The steps of Back up now, for its progress.
enum BackupStage { copying, encrypting, checking, tidying }

/// The steps of a restore, as the restore sheet ticks them off (mockup 10j).
enum RestoreStep { unlocking, checkingParts, restoring, checkingData, switching }

/// Backups (ADR 0011): setup, Back up now with a read-back check, and keeping
/// the last three good backups. Restore and the passphrase sheets come in the
/// next two parts.
///
/// The database goes into a backup as a `sqlcipher_export` copy under a fresh
/// random key, so no unencrypted copy is ever written; that key travels only
/// inside the backup's encrypted manifest.
class BackupEngine {
  BackupEngine(
    this._db,
    this._platform, {
    Future<Directory> Function()? workDir,
    Future<Directory> Function()? dataDir,
    Future<Uint8List> Function()? phoneKey,
    DateTime Function()? clock,
    Random? random,
  }) : _dao = BackupDao(_db),
       _workDir = workDir ?? getTemporaryDirectory,
       _dataDir = dataDir ?? getApplicationSupportDirectory,
       _phoneKey = phoneKey ?? (() => DatabaseKeyStore(KeyStoreApi()).databaseKey(createIfMissing: false)),
       _clock = clock ?? DateTime.now,
       _random = random ?? Random.secure();

  final AppDatabase _db;
  final BackupDao _dao;
  final BackupPlatform _platform;
  final Future<Directory> Function() _workDir;

  /// Where the database lives; a restore leaves its file here.
  final Future<Directory> Function() _dataDir;

  /// This phone's database key, which a restored database is re-encrypted with.
  final Future<Uint8List> Function() _phoneKey;
  final DateTime Function() _clock;
  final Random _random;
  bool _running = false;

  /// The good backups kept; older ones are removed once a new one is checked
  /// (owner, 17 Nov 2026).
  static const keep = 3;

  /// The shortest passphrase (owner, 17 Nov 2026).
  static const passphraseMin = 12;

  int get _now => _clock().toUtc().millisecondsSinceEpoch;

  /// Where backup stands, as it changes: one query over both tables, so a
  /// change to either is seen.
  Stream<BackupStatus> watchStatus() => _dao.watchSummary().asyncMap((row) async {
    final (folderUri, folderName, finishedAt, totalBytes) = row;
    return BackupStatus(
      isSetUp: folderUri != null && await _platform.isSetUp(),
      folderUri: folderUri,
      folderName: folderName,
      lastBackupAt: finishedAt == null ? null : DateTime.fromMillisecondsSinceEpoch(finishedAt, isUtc: true).toLocal(),
      lastBackupBytes: totalBytes,
    );
  });

  /// The system folder picker; null when nothing was picked.
  Future<BackupFolder?> pickFolder() => _platform.pickFolder();

  /// Makes the backup key with [passphrase] and remembers [folder].
  Future<void> setUp({required String passphrase, required BackupFolder folder}) async {
    if (passphrase.length < passphraseMin) throw const BackupException(BackupFailure.writeFailed);
    await _platform.setUp(passphrase);
    await _dao.saveConfig(folderUri: folder.uri, folderName: folder.name, setUpAt: _now);
  }

  /// Backups go to [folder] from now on; earlier ones stay where they are.
  Future<void> changeFolder(BackupFolder folder) async {
    final config = await _dao.config() ?? (throw const BackupException(BackupFailure.notSetUp));
    await _dao.saveConfig(folderUri: folder.uri, folderName: folder.name, setUpAt: config.setUpAt);
  }

  /// Copies the database, encrypts it into the folder, reads it all back,
  /// then keeps only the last [keep] good backups. Throws a
  /// [BackupException]; a failed run leaves no files behind.
  Future<void> backUpNow({void Function(BackupStage stage)? onStage}) async {
    if (_running) throw const BackupException(BackupFailure.busy);
    _running = true;
    File? copy;
    try {
      final config = await _dao.config();
      if (config == null || !await _platform.isSetUp()) throw const BackupException(BackupFailure.notSetUp);
      if (!await _platform.canWrite(config.folderUri)) throw const BackupException(BackupFailure.folderLost);

      final started = _clock();
      final runId = _runId(started);
      await _dao.startRun(runId, config.folderUri, started.toUtc().millisecondsSinceEpoch);
      try {
        onStage?.call(BackupStage.copying);
        final key = _hexKey();
        copy = File(p.join((await _workDir()).path, 'backup-$runId.db'));
        await _exportDatabase(copy, key);

        onStage?.call(BackupStage.encrypting);
        final written = await _platform.write(
          runId: runId,
          folderUri: config.folderUri,
          databasePath: copy.path,
          databaseKeyHex: key,
          createdAt: started,
          schemaVersion: _db.schemaVersion,
        );
        await _dao.markWritten(runId, written.files, written.totalBytes);

        onStage?.call(BackupStage.checking);
        await _verify(config.folderUri, written.indexName, written.files);
        await _dao.finish(runId, verified: true, at: _now);
      } catch (_) {
        await _dao.finish(runId, verified: false, at: _now);
        rethrow;
      }

      onStage?.call(BackupStage.tidying);
      await _keepLastGood();
    } on BackupException {
      rethrow;
    } on Exception {
      throw const BackupException(BackupFailure.writeFailed);
    } finally {
      _running = false;
      // The copy is small and encrypted; removed at once, whatever happened.
      if (copy != null) {
        for (final path in [copy.path, '${copy.path}-journal']) {
          final file = File(path);
          if (file.existsSync()) file.deleteSync();
        }
      }
    }
  }

  /// The backups in [folderUri], newest first.
  Future<List<FoundBackup>> listBackups(String folderUri) => _platform.listBackups(folderUri);

  /// Restores [indexName] from [folderUri] (ADR 0011): unlock it with
  /// [passphrase], read every part back, take the database out into a staging
  /// area, check it (integrity, migrations, the ledger's health check), and
  /// re-encrypt it with this phone's key. It is then left ready as
  /// [restoreFileName]; Loopd switches it in when it starts again
  /// ([restartToFinish]). Nothing on the phone changes until then, and a
  /// failure leaves nothing behind.
  Future<void> restore({
    required String folderUri,
    required String indexName,
    required String passphrase,
    void Function(RestoreStep step)? onStep,
  }) async {
    if (_running) throw const BackupException(BackupFailure.busy);
    _running = true;
    final dir = await _dataDir();
    final staging = Directory(p.join(dir.path, 'restore'));
    try {
      if (staging.existsSync()) staging.deleteSync(recursive: true);
      staging.createSync(recursive: true);
      final incoming = File(p.join(staging.path, 'incoming.db'));

      onStep?.call(RestoreStep.unlocking);
      final opened = await _platform.openBackup(folderUri: folderUri, indexName: indexName, passphrase: passphrase);
      if (opened.schemaVersion > _db.schemaVersion) throw const BackupException(BackupFailure.notABackup);

      onStep?.call(RestoreStep.checkingParts);
      await _platform.verifyOpenedBackup();

      onStep?.call(RestoreStep.restoring);
      final key = await _platform.extractOpenedDatabase(incoming.path);

      onStep?.call(RestoreStep.checkingData);
      await _prepareRestored(incoming, key);

      onStep?.call(RestoreStep.switching);
      final ready = File(p.join(dir.path, restoreFileName));
      if (ready.existsSync()) ready.deleteSync();
      incoming.renameSync(ready.path);
    } on BackupException {
      rethrow;
    } on Exception {
      throw const BackupException(BackupFailure.writeFailed);
    } finally {
      _running = false;
      if (staging.existsSync()) staging.deleteSync(recursive: true);
    }
  }

  /// Starts Loopd again, so the restored database is switched in.
  Future<void> restartToFinish() => _platform.restartApp();

  /// Opens the restored copy with its own key, checks it, brings it up to
  /// this version, and re-encrypts it with this phone's key as one file.
  Future<void> _prepareRestored(File file, String backupKeyHex) async {
    final restored = AppDatabase(NativeDatabase(file, setup: (database) => applyEncryption(database, backupKeyHex)));
    try {
      final integrity = await restored.customSelect('PRAGMA integrity_check').get();
      if (integrity.length != 1 || integrity.single.data.values.single != 'ok') {
        throw const BackupException(BackupFailure.verifyFailed);
      }
      // Opening ran the migrations; the money must still add up.
      if ((await LedgerEngine(restored).healthCheck()).isNotEmpty) {
        throw const BackupException(BackupFailure.verifyFailed);
      }
      await _forgetUnreachableFolders(restored);
      final phoneKey = await _phoneKey();
      final hex = phoneKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      await restored.customStatement("PRAGMA rekey = \"x'$hex'\"");
    } finally {
      // Closing the last connection folds the WAL back in, leaving one file.
      await restored.close();
    }
  }

  /// A backup from another phone carries that phone's folder, which this one
  /// cannot reach: drop it, so backup here starts with its own setup.
  Future<void> _forgetUnreachableFolders(AppDatabase restored) async {
    final dao = BackupDao(restored);
    final config = await dao.config();
    if (config != null && !await _platform.canWrite(config.folderUri)) {
      await restored.customStatement('DELETE FROM backup_configs');
    }
    for (final run in await dao.runs()) {
      if (!await _platform.canWrite(run.folderUri)) await dao.deleteRun(run.id);
    }
  }

  /// Reads the run back; on a mismatch, once more, then removes its files.
  Future<void> _verify(String folderUri, String indexName, List<String> files) async {
    try {
      await _platform.verify(folderUri: folderUri, indexName: indexName);
    } on BackupException catch (first) {
      if (first.failure != BackupFailure.verifyFailed) rethrow;
      try {
        await _platform.verify(folderUri: folderUri, indexName: indexName);
      } on BackupException {
        await _platform.delete(folderUri: folderUri, names: files).catchError((_) {});
        rethrow;
      }
    }
  }

  /// Removes good backups beyond the newest [keep], and the files of failed
  /// runs; only runs Loopd recorded, so nothing else in the folder is touched.
  /// A folder that cannot be reached is skipped and tried again next time.
  Future<void> _keepLastGood() async {
    final runs = await _dao.runs();
    var good = 0;
    for (final run in runs) {
      final stays = run.status == 'verified' && good++ < keep;
      if (stays) continue;
      try {
        if (run.fileNames.isNotEmpty) {
          if (!await _platform.canWrite(run.folderUri)) continue;
          await _platform.delete(folderUri: run.folderUri, names: run.fileNames);
        }
        await _dao.deleteRun(run.id);
      } on BackupException {
        // Left for the next run.
      }
    }
  }

  /// A copy of the open database under [hexKey], made by SQLCipher itself.
  Future<void> _exportDatabase(File target, String hexKey) async {
    if (target.existsSync()) target.deleteSync();
    await _db.customStatement('ATTACH DATABASE ? AS backup_copy KEY ?', [target.path, "x'$hexKey'"]);
    try {
      await _db.customSelect("SELECT sqlcipher_export('backup_copy')").get();
      // sqlcipher_export does not carry the schema version; restore needs it.
      await _db.customStatement('PRAGMA backup_copy.user_version = ${_db.schemaVersion}');
    } finally {
      await _db.customStatement('DETACH DATABASE backup_copy');
    }
  }

  /// "20261118-153012-4f2a": when, plus a little randomness.
  String _runId(DateTime at) {
    final l = at.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    final tail = _random.nextInt(0x10000).toRadixString(16).padLeft(4, '0');
    return '${l.year}${two(l.month)}${two(l.day)}-${two(l.hour)}${two(l.minute)}${two(l.second)}-$tail';
  }

  String _hexKey() => List.generate(32, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}

/// The backup engine. Restore and passphrase changes join it in parts 6b and 6c.
@Riverpod(keepAlive: true)
BackupEngine backupEngine(Ref ref) => BackupEngine(ref.watch(appDatabaseProvider), ref.watch(backupPlatformProvider));
