import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/common.dart';

/// Text placed in the error thrown when the linked library is not SQLCipher,
/// so the opener can recognise it after it crosses the isolate boundary.
const cipherUnavailableMarker = 'loopd:sqlcipher_unavailable';

/// Opens [file] with SQLCipher in a background isolate (ADR 0004).
QueryExecutor openEncryptedExecutor(File file, Uint8List key) {
  final hexKey = _hex(key);
  return NativeDatabase.createInBackground(file, setup: (database) => applyEncryption(database, hexKey));
}

/// Runs first on every new connection.
///
/// The key must be the very first statement. The raw-key form (`x'…'`) skips
/// SQLCipher's passphrase stretching, which a random 256-bit key does not need.
/// If the library is not SQLCipher, `PRAGMA key` would silently do nothing and
/// the file would be written unencrypted, so this refuses to continue.
void applyEncryption(CommonDatabase database, String hexKey) {
  database.execute("PRAGMA key = \"x'$hexKey'\";");
  final version = database.select('PRAGMA cipher_version;');
  if (version.isEmpty || '${version.first.values.first ?? ''}'.isEmpty) {
    throw StateError(cipherUnavailableMarker);
  }
  // The first statement that reads the file: a wrong key fails here with
  // SQLITE_NOTADB (26).
  database.execute('PRAGMA journal_mode = WAL;');
  database.execute('PRAGMA busy_timeout = 5000;');
}

String _hex(Uint8List bytes) => bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
