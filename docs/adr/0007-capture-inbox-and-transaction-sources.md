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

## Phase 0B results (17 Nov 2026, Tecno Pova Curve 5G, Android 16, HiOS 16.3)

From the spike lab. Only counts, sender codes and timings were reported; no message text or numbers.

- **Install:** Google Play Protect blocked installing the personal build from a file, because it requests SMS permissions. Installing over USB (`adb`) worked. How the owner installs it is an open point.
- **Restricted settings:** Android refused the SMS permission ("App was denied access to SMS") until the owner turned on Settings › Apps › Loopd › ⋮ › Allow restricted settings. That option appears only after the first refusal. Walked through on the phone.
- **Inbox read:** 4,299 messages in 456 ms. In the last 90 days, 1,162 messages, of which 596 contain money words. Bank senders reduce to their six-letter codes, as expected; phone-number senders are reported only as `phone_number`.
- **Receiver with Loopd not running:** a new SMS arrived while the phone was locked. Android started Loopd, the receiver ran at once, and the expedited job opened the database and finished in 3 s. PASS.
- **Receiver with Loopd frozen by HiOS** (left in recent apps): the SMS broadcast was never delivered, not even after Loopd was unfrozen. Other apps that were not running received it.
- **Decision that follows:** the receiver is the fast path, not the only path. Each time Loopd runs (the app opens, a job or an alarm clock fires), it reads the inbox for messages newer than the last one it processed, deduplicated by the SMS identity hash. Because of this, nothing is missed; a card may appear later than the SMS.

## Alternatives considered

- One `source_draft_id` column on transactions: cannot represent pairs.

## Consequences

- Confirming from the app and from a notification at the same moment is safe.
- Pending: the pairing window; whether the original SMS text is kept after confirming.
- To try in Phase 3 (owner agreed, 17 Nov 2026): Loopd ends its own process a short while after it leaves the screen, so HiOS finds it not running rather than frozen, and new SMS are caught at once. This is tested on the phone for its effect on opening speed before it is kept. Only an idea, not a promise.
- The inbox catch-up keeps data safe: a money SMS still in the inbox always reaches the Review Inbox once Loopd runs. Only the timing depends on HiOS.
