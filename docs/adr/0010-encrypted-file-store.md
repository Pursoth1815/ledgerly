# 0010 Encrypted file store and temporary files

Status: Accepted; built in Phase 5 (16 Nov 2026)

## Context

Vault documents and ticket files can be large and are sensitive.

## Decision

- Files are encrypted with Tink streaming (ADR 0009), one segment at a time, written to `.part` and then renamed.
- Images are decrypted in memory. PDFs are decrypted to `cache/vault_tmp/<random>`, because Android's PDF renderer needs a file. That file is deleted on close, on lock and at every start.
- Each file row records `crypto_format`. Fixture files from every format version must still decrypt.
- Files referenced by an unfinished backup are not removed until the backup ends.

## Alternatives considered

- Storing files inside the database: bloats backups and memory.

## Consequences

- Sharing a document out hands over a readable copy; the app warns once.
