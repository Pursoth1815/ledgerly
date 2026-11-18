# 0006 Double-entry ledger in paise

Status: Accepted (16 Nov 2026). Built in Phase 2, part 1 (17 Nov 2026)

## Context

Lending, ATM withdrawals, card bills, refunds and Cash in hand must never distort spending. Payment method, funding account and channel are different facts. Edits must be safe, and history kept.

## Decision

- Tables:
  - `accounts` (bank, credit_card, cash, category, income, loan, adjustment, write_off, opening) and `categories`
  - `ledger_transactions` (kind, payment_method, channel, occurred_at, local_date, merchant, note, refund_of, revision, deleted_at)
  - `postings` (signed `amount_paise`, never zero, `UNIQUE(transaction_id, account_id)`)
  - `transaction_revisions`, `balance_checkpoints`, and lending's `loans`
- **Signs:** + means value into an account, − means out of it, and every transaction sums to zero.
  - Bank, cash or a loan: positive = held or owed to you.
  - Card: negative = owed, positive = a credit on the card.
  - Category: positive = spent. Income: negative = earned.
- **Payment method** is stored separately and must fit the funding account: upi → bank, credit_card → card, cash → cash; debit_card, net_banking and auto_debit → bank, set by SMS only. A card paid by UPI QR is `credit_card` with channel `upi_qr`.
- **Refunds** require `refund_of`, and their total can never exceed the original. Their method and funding describe where the money actually came back. Spending reports attribute refunds to the original's category, method and card; balances use the actual destination. Reports have a purchase-month mode and a cash-flow mode.
- **Deleting** a purchase with live refunds is blocked unless you choose to delete it with its refunds. Deletes are soft.
- **Opening balances** are optional `opening_balance` transactions. Verified balances are `balance_checkpoints` in the ledger's sign. The difference shown is actual minus tracked.
- **Every write** adds a revision with a full snapshot. Undo restores the previous snapshot as a new revision, only while nothing has changed since.
- **Reconciliation** never creates entries by itself.
- **Each loan** is its own account, so oldest-first allocation is visible in the postings.
- **Health check** (sums, legs, refunds, method matching funding) runs in tests, on debug starts and after restores.

## As built (Phase 2, part 1)

- Tables in `core/database/tables/ledger.dart` (schema version 4), STRICT, with CHECK constraints on kinds, methods and non-zero postings, and `UNIQUE (transaction_id, account_id)`. Loans arrive in Phase 4 and transaction sources in Phase 3.
- `LedgerEngine` commands: expense, refund, income, transfer (including ATM withdrawals), card payment, Update cash (changed in part 2, below), opening balance, verified balance, edit, delete (with refunds only on request) and undo (only while the revision is unchanged).
- Every install gets Cash in hand, Adjustments, Opening balances, Income and the twelve default categories at start-up (`ensureDefaults`, safe to repeat).
- An edit can never take a purchase below what was already refunded.
- With an opening balance, the tracked balance counts what is dated after it, plus anything at the same moment created after it.

## As built (Phase 2, part 2: accounts and cards)

- Schema version 5 adds `accounts.bank_name`: the bank as picked from the list or typed. It is separate from the sender code because two list entries can share one code (a bank and its card division), and a bank typed by hand has no code.
- `addAccount` needs a nickname and, when given, exactly four digits. The same last four digits cannot be saved twice among bank accounts, or twice among cards, whatever the bank (owner, 18 Nov 2026); a bank account and a card may share them, and a removed account frees its digits. The Add sheet checks this as you type, and the engine checks again on save (`duplicateAccount`), so no other path can add a second one.
- Nothing becomes a default by itself: not the first account, and not another one when the default is removed. There is at most one default per kind, and only if the owner chose it (18 Nov 2026). The expense form preselects it when there is one.
- **Update cash** is a reset, not an adjustment (owner, 18 Nov 2026). Each count is a `balance_checkpoints` row with source `count`; Cash in hand is the latest count plus what is dated after it (the same rule as an opening balance, whichever is later). No money row is written, so a count is never spending, ₹0 is a valid count, and Cash in hand starts at ₹0 before the first one. Something dated before the latest count is already in it, so a late ATM SMS (read after a count, ADR 0007) does not add the money twice. Manual checkpoints on banks and cards are still only compared, never applied. The Adjustments account stays for the bank and card reconciliation in section 13.
- Live reads for the screens: `watchAccounts`, `watchMonthSpending` (per funding account, net of refunds, in the purchase month) and `watchCashInHand` (balance, last count, last money moved in).

## Alternatives considered

- Single-entry rows with a kind column: simpler tables, but the rules spread across queries.
- Deriving the method from the account type: rejected by the owner; the method is stored.

## Consequences

- Totals can only disagree if a rule in the engine is wrong, and the rules are tested.
- Decided 17 Nov 2026: the SMS-only bank methods (debit_card, net_banking, auto_debit) count as UPI in every total by method, because Loopd shows only UPI, Credit Card and Cash; purchase month is the default reporting mode, with a cash-flow switch.
- Pending (proposal section 19): the pairing window.
