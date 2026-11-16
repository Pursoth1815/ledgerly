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

/// Opens the encrypted database in [directory] (ADR 0004).
///
/// A new key is created only when no database file exists yet. If the file
/// exists but its key cannot be read, this fails instead of starting over,
/// so existing data is never replaced. Nothing is deleted on failure.
///
/// Throws [KeyAccessException] or [DatabaseOpenException].
Future<AppDatabase> openAppDatabase({required DatabaseKeyStore keys, required Directory directory}) async {
  final file = File(p.join(directory.path, databaseFileName));
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
