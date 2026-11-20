import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/core/backup/backup_engine.dart';
import 'package:loopd/core/database/app_database.dart';
import 'package:loopd/core/database/database_opener.dart';
import 'package:loopd/core/database/encrypted_executor.dart';
import 'package:loopd/core/errors/app_exception.dart';
import 'package:loopd/core/ledger/ledger_engine.dart';
import 'package:loopd/core/ledger/ledger_types.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import '../../support/fake_backup_platform.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory work;
  late AppDatabase db;
  late FakeBackupPlatform platform;
  late BackupEngine engine;
  var now = DateTime(2026, 11, 18, 9);

  setUp(() async {
    work = await Directory.systemTemp.createTemp('loopd_backup_test');
    db = AppDatabase(NativeDatabase.memory());
    platform = FakeBackupPlatform();
    now = DateTime(2026, 11, 18, 9);
    engine = BackupEngine(db, platform, workDir: () async => work, clock: () => now);
  });
  tearDown(() async {
    await db.close();
    await work.delete(recursive: true);
  });

  Matcher fails(BackupFailure failure) => throwsA(isA<BackupException>().having((e) => e.failure, 'failure', failure));
  const folder = (uri: 'content://tree/loopd', name: 'Phone › Loopd');

  test('nothing backs up before setup', () async {
    await expectLater(engine.backUpNow(), fails(BackupFailure.notSetUp));
    expect((await engine.watchStatus().first).isSetUp, isFalse);
  });

  test('setup refuses a passphrase under 12 characters, then remembers the folder', () async {
    await expectLater(engine.setUp(passphrase: 'short one', folder: folder), fails(BackupFailure.writeFailed));
    expect(platform.calls, isEmpty);
    await engine.setUp(passphrase: 'a long made up phrase', folder: folder);
    final status = await engine.watchStatus().first;
    expect((status.isSetUp, status.folderName, status.lastBackupAt), (true, 'Phone › Loopd', null));
  });

  test('Back up now copies the database encrypted, writes, reads it back, then cleans up', () async {
    final ledger = LedgerEngine(db, clock: () => now);
    await ledger.ensureDefaults();
    await ledger.addAccount(kind: AccountKind.bank, name: 'Primary', last4: '2210');
    await engine.setUp(passphrase: 'a long made up phrase', folder: folder);

    String? copyPath;
    platform.onWrite = (path, key) {
      copyPath = path;
      expect(
        File(path).readAsBytesSync().take(16),
        isNot(equals('SQLite format 3\u0000'.codeUnits)),
        reason: 'encrypted',
      );
      final copy = sqlite3.open(path);
      try {
        applyEncryption(copy, key);
        expect(copy.select("SELECT name FROM accounts WHERE kind = 'bank'").single['name'], 'Primary');
        expect(copy.select('PRAGMA user_version').single.values.single, db.schemaVersion);
      } finally {
        copy.close();
      }
    };
    final stages = <BackupStage>[];
    await engine.backUpNow(onStage: stages.add);

    expect(stages, BackupStage.values);
    expect(platform.calls, ['setUp', 'write', 'verify']);
    expect(File(copyPath!).existsSync(), isFalse, reason: 'the copy is removed');
    final status = await engine.watchStatus().first;
    expect((status.lastBackupAt, status.lastBackupBytes), (now, 4096));
  });

  test('one status stream follows setup and then each backup', () async {
    final seen = <BackupStatus>[];
    final sub = engine.watchStatus().listen(seen.add);
    await pumpEventQueue();
    await engine.setUp(passphrase: 'a long made up phrase', folder: folder);
    await pumpEventQueue();
    await engine.backUpNow();
    await pumpEventQueue();
    await sub.cancel();
    expect(seen.first.isSetUp, isFalse);
    expect(seen.any((s) => s.isSetUp && s.lastBackupAt == null), isTrue, reason: 'setup is seen');
    expect(seen.last.lastBackupAt, now, reason: 'and the backup');
  });

  test('a lost folder stops before anything is written', () async {
    await engine.setUp(passphrase: 'a long made up phrase', folder: folder);
    platform.writable = false;
    await expectLater(engine.backUpNow(), fails(BackupFailure.folderLost));
    expect(platform.calls, ['setUp']);
  });

  test('a failed read-back is retried once; twice and the files go and nothing counts', () async {
    await engine.setUp(passphrase: 'a long made up phrase', folder: folder);
    platform.verifyFailures = 1;
    await engine.backUpNow();
    expect(platform.calls.where((c) => c == 'verify'), hasLength(2));
    expect(platform.deleted, isEmpty);

    now = now.add(const Duration(days: 1));
    platform.verifyFailures = 2;
    await expectLater(engine.backUpNow(), fails(BackupFailure.verifyFailed));
    expect(platform.deleted.single, hasLength(2), reason: 'its part and index are removed');
    final status = await engine.watchStatus().first;
    expect(status.lastBackupAt, DateTime(2026, 11, 18, 9), reason: 'the last good one is still the last');
  });

  test('only the last three good backups are kept', () async {
    await engine.setUp(passphrase: 'a long made up phrase', folder: folder);
    for (var day = 0; day < 5; day++) {
      now = DateTime(2026, 11, 10 + day, 9);
      await engine.backUpNow();
    }
    expect(platform.deleted, hasLength(2), reason: 'the two oldest');
    expect(platform.deleted.expand((names) => names), everyElement(contains('-2026111')));
    expect(platform.deleted.first.first, contains('20261110'), reason: 'the oldest goes after the 4th');
    expect(platform.deleted.last.first, contains('20261111'), reason: 'the next oldest after the 5th');
  });

  test('a second Back up now while one runs is refused', () async {
    await engine.setUp(passphrase: 'a long made up phrase', folder: folder);
    platform.holdWrite = Completer<void>();
    final first = engine.backUpNow();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await expectLater(engine.backUpNow(), fails(BackupFailure.busy));
    platform.holdWrite!.complete();
    await first;
  });

  group('restore', () {
    late Directory dataDir;
    final phoneKey = Uint8List.fromList(List.generate(32, (i) => (i * 11 + 3) & 0xff));
    String hex(Uint8List k) => k.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    /// A second phone: its own empty database and folders, the same fake folder.
    BackupEngine otherPhone() {
      final other = AppDatabase(NativeDatabase.memory());
      addTearDown(other.close);
      return BackupEngine(
        other,
        platform,
        workDir: () async => work,
        dataDir: () async => dataDir,
        phoneKey: () async => phoneKey,
        clock: () => now,
      );
    }

    setUp(() async {
      dataDir = await Directory(p.join(work.path, 'data')).create();
      final ledger = LedgerEngine(db, clock: () => now);
      await ledger.ensureDefaults();
      final primary = await ledger.addAccount(kind: AccountKind.bank, name: 'Primary', last4: '2210');
      await ledger.recordExpense(
        amountPaise: 32000,
        method: PaymentMethod.upi,
        fundingAccountId: primary,
        categoryId: 'category-food',
        occurredAt: now,
      );
      await engine.setUp(passphrase: 'a long made up phrase', folder: folder);
      await engine.backUpNow();
    });

    test('restores into a file ready for the next start, under this phone\'s key', () async {
      platform.writable = false; // the other phone cannot reach the first one's folder
      final steps = <RestoreStep>[];
      await otherPhone().restore(
        folderUri: folder.uri,
        indexName: 'loopd-x.lpdb',
        passphrase: 'a long made up phrase',
        onStep: steps.add,
      );

      expect(steps, RestoreStep.values);
      expect(platform.calls, containsAllInOrder(['open', 'check', 'extract']));
      final ready = File(p.join(dataDir.path, restoreFileName));
      expect(ready.existsSync(), isTrue);
      expect(Directory(p.join(dataDir.path, 'restore')).existsSync(), isFalse, reason: 'staging is cleaned up');
      expect(dataDir.listSync().map((e) => p.basename(e.path)), [restoreFileName], reason: 'one file, no WAL');

      final restored = sqlite3.open(ready.path);
      try {
        applyEncryption(restored, hex(phoneKey));
        expect(restored.select("SELECT name FROM accounts WHERE kind = 'bank'").single['name'], 'Primary');
        expect(
          restored.select('SELECT COUNT(*) AS n FROM backup_configs').single['n'],
          0,
          reason: 'other phone folder',
        );
        expect(restored.select('SELECT COUNT(*) AS n FROM backup_runs').single['n'], 0);
      } finally {
        restored.close();
      }
    });

    test('a wrong passphrase leaves nothing behind', () async {
      await expectLater(
        otherPhone().restore(folderUri: folder.uri, indexName: 'loopd-x.lpdb', passphrase: 'not the one at all'),
        fails(BackupFailure.wrongPassphrase),
      );
      expect(dataDir.listSync(), isEmpty);
    });

    test('a backup from a newer Loopd is refused before anything is taken out', () async {
      platform.backupSchemaVersion = 99;
      await expectLater(
        otherPhone().restore(folderUri: folder.uri, indexName: 'loopd-x.lpdb', passphrase: 'a long made up phrase'),
        fails(BackupFailure.notABackup),
      );
      expect(platform.calls, isNot(contains('extract')));
      expect(dataDir.listSync(), isEmpty);
    });

    test('data that fails the ledger check is refused', () async {
      // Break one posting so the transaction no longer sums to zero.
      await db.customStatement('UPDATE postings SET amount_paise = amount_paise + 1 WHERE amount_paise > 0');
      await engine.backUpNow();
      await expectLater(
        otherPhone().restore(folderUri: folder.uri, indexName: 'loopd-x.lpdb', passphrase: 'a long made up phrase'),
        fails(BackupFailure.verifyFailed),
      );
      expect(dataDir.listSync(), isEmpty);
    });

    test('Restart Loopd asks the phone to start again', () async {
      await otherPhone().restartToFinish();
      expect(platform.calls.last, 'restart');
    });
  });
}
