import 'dart:io';

import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/common.dart';

import '../errors/app_exception.dart';
import '../security/database_key_store.dart';
import 'app_database.dart';
import 'encrypted_executor.dart';

/// The database file name inside the app's private support folder.
const databaseFileName = 'loopd.db';

final _log = Logger('core.database');

/// A restored database waiting to be switched in at the next start (ADR 0011).
/// Restore leaves it here already checked and encrypted with this phone's key.
const restoreFileName = 'loopd.db.restore';

/// Where the old data waits while a restored database is opened for the
/// first time; deleted once that works, moved back if it does not.
const _beforeRestore = '.before-restore';

/// Opens the encrypted database in [directory] (ADR 0004).
///
/// A new key is created only when no database file exists yet. If the file
/// exists but its key cannot be read, this fails instead of starting over,
/// so existing data is never replaced. Nothing is deleted on failure.
///
/// A restored database ([restoreFileName]) is switched in first: the old files
/// are moved aside, and removed only after the restored one opens. If it does
/// not open, the old data is moved back and opened instead.
///
/// Throws [KeyAccessException] or [DatabaseOpenException].
Future<AppDatabase> openAppDatabase({required DatabaseKeyStore keys, required Directory directory}) async {
  final switched = _switchInRestore(directory);
  try {
    final database = await _open(keys, directory);
    if (switched) {
      _removeBeforeRestore(directory);
      _log.info('restore_switched_in');
    }
    return database;
  } on AppException {
    if (!switched) rethrow;
    _log.severe('restore_open_failed rolled_back=true');
    _rollBack(directory);
    return _open(keys, directory);
  }
}

String _main(Directory directory) => p.join(directory.path, databaseFileName);

const _sidecars = ['', '-wal', '-shm'];

/// Moves the current files aside and the restored file into place. True when
/// old data now waits aside (also after a start that stopped half-way).
bool _switchInRestore(Directory directory) {
  final main = _main(directory);
  final restored = File(p.join(directory.path, restoreFileName));
  if (restored.existsSync()) {
    for (final side in _sidecars) {
      final aside = File('$main$_beforeRestore$side');
      if (aside.existsSync()) aside.deleteSync();
      final current = File('$main$side');
      if (current.existsSync()) current.renameSync(aside.path);
    }
    restored.renameSync(main);
  }
  return File('$main$_beforeRestore').existsSync();
}

void _removeBeforeRestore(Directory directory) {
  for (final side in _sidecars) {
    final aside = File('${_main(directory)}$_beforeRestore$side');
    if (aside.existsSync()) aside.deleteSync();
  }
}

void _rollBack(Directory directory) {
  final main = _main(directory);
  for (final side in _sidecars) {
    final failed = File('$main$side');
    if (failed.existsSync()) failed.deleteSync();
    final aside = File('$main$_beforeRestore$side');
    if (aside.existsSync()) aside.renameSync('$main$side');
  }
}

Future<AppDatabase> _open(DatabaseKeyStore keys, Directory directory) async {
  final file = File(_main(directory));
  final isNew = !file.existsSync();
  final key = await keys.databaseKey(createIfMissing: isNew);

  final database = AppDatabase(openEncryptedExecutor(file, key));
  try {
    // Forces the connection open, so setup, key check and migrations run now.
    final version = await database.customSelect('PRAGMA cipher_version').getSingleOrNull();
    if (version == null || version.data.values.first == null) {
      throw const DatabaseOpenException(DatabaseOpenFailure.encryptionUnavailable);
    }
  } on Object catch (error) {
    await _closeQuietly(database);
    final failure = classifyOpenFailure(error);
    _log.severe('open_failed code=${failure.code}');
    throw failure;
  }
  _log.info('opened schema=${database.schemaVersion} new=$isNew');
  return database;
}

/// Maps whatever went wrong while opening into a [DatabaseOpenException].
DatabaseOpenException classifyOpenFailure(Object error) {
  if (error is DatabaseOpenException) return error;
  if (error is SqliteException && error.resultCode == 26) {
    return const DatabaseOpenException(DatabaseOpenFailure.keyMismatch);
  }
  // Errors from the background isolate arrive wrapped, so their text is the
  // reliable part: SQLite's message for SQLITE_NOTADB and our marker.
  final text = '$error';
  if (text.contains(cipherUnavailableMarker)) {
    return const DatabaseOpenException(DatabaseOpenFailure.encryptionUnavailable);
  }
  if (text.contains('file is not a database')) {
    return const DatabaseOpenException(DatabaseOpenFailure.keyMismatch);
  }
  return const DatabaseOpenException(DatabaseOpenFailure.openFailed);
}

Future<void> _closeQuietly(GeneratedDatabase database) async {
  try {
    await database.close();
  } on Object {
    // The connection never opened; there is nothing else to release.
  }
}
