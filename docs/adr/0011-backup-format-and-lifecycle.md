# 0011 Backup format, lifecycle and retention

Status: Accepted; built in Phases 2 and 7 (16 Nov 2026)

## Context

Backups go to a folder chosen in the system picker, possibly a cloud provider. Android may stop long background work. A failed backup must never harm the last good one.

## Decision

- **Format version 1:**
  - an index file `loopd-<run>.lpdb`: a header ("LPDB", version, Argon2id settings, salt, backup key id, backup key wrapped by the passphrase), then a Tink stream with the header as associated data, holding the manifest (versions, parts and their SHA-256, entries)
  - part files `loopd-<run>-pNNNN.lpdp`: Tink streams with associated data of run id and part number, each holding a tar of whole entries; large files are split across numbered members
- The database entry is a `sqlcipher_export` copy under a fresh random key. Vault files are decrypted and sealed straight into the stream, so no unencrypted copy is ever written.
- **Lifecycle:**
  1. Setup creates a random backup key, wrapped by the Keystore and by the passphrase (Argon2id).
  2. Weekly runs use normal WorkManager jobs, with no foreground service and so no Android 15 foreground-service limit.
  3. The snapshot and the part plan are taken once per run. Each execution writes whole parts and records them.
  4. When Android stops a job, the part being written is discarded and the next execution resumes after the last finished part. If a foreground service is ever used, `onTimeout` saves progress and stops within seconds.
  5. A run that has not finished in 7 days is abandoned and its files removed.
  6. Verification: the index is written last, then everything is read back (hashes and authentication).
  7. Retention: nothing is overwritten. Old backups are removed only after a new one is verified, and only files the app created. At least the last three successful backups are kept.
  8. Restore: staging folder, integrity and ledger health checks, migrations, new device keys, then a swap.
- **Failures:**
  - folder access lost: stop and ask
  - out of space: stop and notify
  - provider errors: three retries in a day
  - read-back failure: retry once, then notify
- Android's own backup and phone-to-phone transfer are off (`allowBackup=false`, data-extraction rules exclude everything; done in Phase 0A).

## Alternatives considered

- One archive file: cannot resume after interruption.
- Appending to one file: many providers do not support it.
- A foreground service per backup: a visible notification and Android 15's 6-hour daily limit.

## Consequences

- Restore round trips are tested before every release. Committed fixture backups must always open.
- Cloud providers only accept the files; Phase 0B tests the providers on the phone.
- Pending: a fourth, older backup kept or not; the weekly conditions; restore without the passphrase; resetting a forgotten passphrase; minimum length; an in-app test restore (new scope).
