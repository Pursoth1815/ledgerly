# 0004 Drift on SQLCipher, one database, one DAO per owner, one writer

Status: Accepted (16 Nov 2026)

## Context

A ledger is sums, joins and date ranges, and the data is private. Drift does not encrypt anything itself; the SQLite library underneath must be SQLCipher, and it must be proven to be.

## Decision

- Drift 2.35 on the `sqlite3` package 3.x. Its build hook bundles the **SQLCipher** build (`hooks: user_defines: sqlite3: source: sqlcipher`). The library is downloaded at build time, never at run time. The APK ships `libsqlcipher.so`.
- One file, `loopd.db`, in app-private storage, with one schema version for the whole app.
- Every connection is opened in a background isolate:
  1. `PRAGMA key` first, using the raw 256-bit key form.
  2. Refuse to continue if `PRAGMA cipher_version` is empty, so the file is never written unencrypted.
  3. WAL mode and a 5-second busy timeout.
  - `foreign_keys` is switched on before use.
- A new key is created only when no database file exists. A missing or wrong key never leads to a new database; it shows a recovery screen. Nothing is deleted.
- Tables are grouped by owner in `core/database/tables/`. Each owner has its own DAO, which is imported only inside that owner's folder (checked in CI).
- One writer at a time: the background engine hands work to the running app when it is open (ADR 0013).
- Tests open a real SQLCipher file on the host and check the file header, the cipher version, the settings, a wrong key and a missing key.

## Alternatives considered

- SQLite3MultipleCiphers (`source: sqlite3mc`), which Drift's documentation now recommends. It can read and write the SQLCipher 4 format (`cipher=sqlcipher`, `legacy=4`). It is kept as the documented fallback if the SQLCipher build lags or breaks.
- `encrypted_drift` with `sqflite_sqlcipher`: extra set-up, and it runs on the platform thread.
- Hive or Isar: no relational queries.

## Consequences

- The SQLCipher build may lag the newest SQLite release.
- Tables live in core rather than in each feature, in exchange for one migration history.
- 64-bit integer paise and STRICT tables apply from the first ledger table (ADR 0006).
