# 0007 Capture inbox and transaction sources

Status: Accepted (16 Nov 2026)

## Context

Nothing detected is saved silently. One transaction can come from several SMS (a card bill pair, an own transfer), or gain evidence from one. Confirming twice must not create two transactions.

## Decision

- The capture inbox owns drafts, the SMS identity hash (unique index), merchant memory and `transaction_sources`.
- `transaction_sources`: `draft_id` is the primary key; `role` is `primary`, `pair_debit`, `pair_credit` or `evidence`, with a CHECK on the values.
- A partial unique index allows at most one primary, one pair_debit and one pair_credit per transaction:
  ```sql
  CREATE UNIQUE INDEX transaction_sources_one_role
    ON transaction_sources (transaction_id, role)
    WHERE role IN ('primary', 'pair_debit', 'pair_credit');
  ```
- "A single primary, or a pair, not both" spans several rows, so the engine checks it and the health check confirms it.
- A draft gets its future transaction id when it is created. Confirming is one database transaction: ledger entry, source link, draft marked confirmed.
- Features register confirm handlers in `app/`, so the inbox never depends on features.

## Alternatives considered

- One `source_draft_id` column on transactions: cannot represent pairs.

## Consequences

- Confirming from the app and from a notification at the same moment is safe.
- Pending: the pairing window; whether the original SMS text is kept after confirming.
