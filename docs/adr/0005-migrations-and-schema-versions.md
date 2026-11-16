# 0005 Migrations and schema versioning

Status: Accepted (16 Nov 2026)

## Context

Data must survive every app update, and a backup made by an older version must restore into a newer one.

## Decision

- `schemaVersion` in `AppDatabase`, version 1 in Phase 0A, with no tables yet.
- `dart run drift_dev make-migrations` writes a snapshot per version to `drift_schemas/` (v1 is committed). From version 2 it also generates step-by-step migrations and tests in `test/drift/`.
- Released steps are never edited. Additive changes are preferred; a destructive change is spread over two releases.
- Before migrating, the encrypted database file is copied. If the migration fails, the copy is put back and a recovery screen is shown (built with the first real migration).
- Backups record their schema version. A newer schema than the app knows is refused, and an older one is migrated after restore.

## Alternatives considered

- Hand-written migrations without snapshots: easy to get wrong silently.

## Consequences

- Every upgrade path is tested before release.
