# 0006 Double-entry ledger in paise

Status: Accepted (16 Nov 2026)

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

## Alternatives considered

- Single-entry rows with a kind column: simpler tables, but the rules spread across queries.
- Deriving the method from the account type: rejected by the owner; the method is stored.

## Consequences

- Totals can only disagree if a rule in the engine is wrong, and the rules are tested.
- Decided 17 Nov 2026: the SMS-only bank methods (debit_card, net_banking, auto_debit) count as UPI in every total by method, because Loopd shows only UPI, Credit Card and Cash; purchase month is the default reporting mode, with a cash-flow switch.
- Pending (proposal section 19): the pairing window.
