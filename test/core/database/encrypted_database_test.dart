import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/core/database/database_opener.dart';
import 'package:loopd/core/database/encrypted_executor.dart';
import 'package:loopd/core/errors/app_exception.dart';
import 'package:loopd/core/platform/platform_api.g.dart';
import 'package:loopd/core/security/database_key_store.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Uses the real SQLCipher library from the `sqlite3` build hook, on a real
/// file, so these tests prove encryption rather than assume it (ADR 0004).
void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('loopd_db_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  File databaseFile() => File(p.join(dir.path, databaseFileName));

  test('a new database is created with a new key and is not plain SQLite', () async {
    final api = FakeKeyStoreApi(key: _key(1));
    final database = await openAppDatabase(keys: DatabaseKeyStore(api), directory: dir);
    await database.close();

    expect(api.calls, [true], reason: 'no file yet, so a key may be created');
    final header = databaseFile().openSync().readSync(16);
    expect(String.fromCharCodes(header), isNot(startsWith('SQLite format 3')));
  });

  test('SQLCipher is the linked library and the connection settings apply', () async {
    final database = await openAppDatabase(
      keys: DatabaseKeyStore(FakeKeyStoreApi(key: _key(2))),
      directory: dir,
    );
    addTearDown(database.close);

    Future<Object?> pragma(String name) async =>
        (await database.customSelect('PRAGMA $name').getSingle()).data.values.first;

    expect('${await pragma('cipher_version')}', isNotEmpty);
    expect(await pragma('foreign_keys'), 1);
    expect('${await pragma('journal_mode')}'.toLowerCase(), 'wal');
    expect(await pragma('user_version'), database.schemaVersion);
  });

  test('an existing database never asks for a new key and reopens with its own', () async {
    final first = await openAppDatabase(
      keys: DatabaseKeyStore(FakeKeyStoreApi(key: _key(3))),
      directory: dir,
    );
    await first.customStatement('CREATE TABLE probe (value INTEGER)');
    await first.customStatement('INSERT INTO probe VALUES (42)');
    await first.close();

    final api = FakeKeyStoreApi(key: _key(3));
    final again = await openAppDatabase(keys: DatabaseKeyStore(api), directory: dir);
    addTearDown(again.close);

    expect(api.calls, [false], reason: 'a file exists, so no new key');
    final row = await again.customSelect('SELECT value FROM probe').getSingle();
    expect(row.data['value'], 42);
  });

  test('the wrong key is reported as a key mismatch and the file is kept', () async {
    final first = await openAppDatabase(
      keys: DatabaseKeyStore(FakeKeyStoreApi(key: _key(4))),
      directory: dir,
    );
    await first.close();
    final before = databaseFile().readAsBytesSync();

    await expectLater(
      openAppDatabase(
        keys: DatabaseKeyStore(FakeKeyStoreApi(key: _key(5))),
        directory: dir,
      ),
      throwsA(isA<DatabaseOpenException>().having((e) => e.failure, 'failure', DatabaseOpenFailure.keyMismatch)),
    );
    expect(databaseFile().readAsBytesSync(), before);
  });

  test('a missing key for an existing database stops the open', () async {
    final first = await openAppDatabase(
      keys: DatabaseKeyStore(FakeKeyStoreApi(key: _key(6))),
      directory: dir,
    );
    await first.close();

    await expectLater(
      openAppDatabase(
        keys: DatabaseKeyStore(FakeKeyStoreApi(errorCode: 'key_missing')),
        directory: dir,
      ),
      throwsA(isA<KeyAccessException>().having((e) => e.failure, 'failure', KeyAccessFailure.keyMissing)),
    );
    expect(databaseFile().existsSync(), isTrue);
  });

  group('a restored database waiting to be switched in (ADR 0011)', () {
    Future<void> writeProbe(String path, Uint8List key, int value) async {
      final db = sqlite3.open(path);
      try {
        applyEncryption(db, _hexOf(key));
        db.execute('CREATE TABLE IF NOT EXISTS probe (value INTEGER)');
        db.execute('DELETE FROM probe');
        db.execute('INSERT INTO probe VALUES ($value)');
      } finally {
        db.close();
      }
    }

    Future<int> probeOf(Directory dir, Uint8List key) async {
      final database = await openAppDatabase(
        keys: DatabaseKeyStore(FakeKeyStoreApi(key: key)),
        directory: dir,
      );
      try {
        return (await database.customSelect('SELECT value FROM probe').getSingle()).read<int>('value');
      } finally {
        await database.close();
      }
    }

    List<String> leftovers() =>
        dir.listSync().map((e) => p.basename(e.path)).where((n) => n.contains('restore')).toList();

    test('switches in, then removes the old data', () async {
      final key = _key(5);
      await writeProbe(databaseFile().path, key, 1);
      await writeProbe(p.join(dir.path, restoreFileName), key, 2);

      expect(await probeOf(dir, key), 2, reason: 'the restored data');
      expect(leftovers(), isEmpty, reason: 'nothing waits aside any more');
    });

    test('a restored file that does not open is dropped and the old data opens', () async {
      final key = _key(6);
      await writeProbe(databaseFile().path, key, 1);
      File(p.join(dir.path, restoreFileName)).writeAsStringSync('not a database');

      expect(await probeOf(dir, key), 1, reason: 'the old data is back');
      expect(leftovers(), isEmpty);
    });
  });
}

String _hexOf(Uint8List key) => key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

Uint8List _key(int seed) => Uint8List.fromList(List.generate(32, (i) => (i * 7 + seed) & 0xff));

/// Stands in for the Kotlin side of the Pigeon bridge.
class FakeKeyStoreApi extends KeyStoreApi {
  FakeKeyStoreApi({this.key, this.errorCode});

  final Uint8List? key;
  final String? errorCode;
  final calls = <bool>[];

  @override
  Future<Uint8List> databaseKey(bool createIfMissing) async {
    calls.add(createIfMissing);
    final code = errorCode;
    if (code != null) throw PlatformException(code: code);
    return key!;
  }
}
