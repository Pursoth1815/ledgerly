# Personal App: proposal status

As of 2026-11-16. Stage reached: revision 3 of the proposal, after six rounds of design review on the mockups. No app code written yet.

- Full proposal (current): `Personal App — Product Proposal & Phased Roadmap.md` in this repository.
- The earlier Claude Doc (https://claude.ai/artifact/5E9r7cyk2nPgheaf7iyGmj) holds revision 2 and is now out of date.
- Mockups and the review record: `docs/mockups/README.md`; canvas at https://claude.ai/artifact/LGbLMacN52Aq8mq8pi7bNa
- Postponed features: `TO-DO.md`.

## Confirmed decisions (from the user's final instructions, 2026-11-13)

- Concept: capture, confirm, remember. Home screen is Today. Android-first, fully offline. Working name Kanakku.
- Core modules: Today, Expenses, Lending, Travel tickets, Notes, Tasks, Document Vault, Digital Wellbeing, offline assistant. Notes, Tasks and Vault are core, not deferred.
- Expenses: record only, never initiate payments. Exactly two payment methods in the UI: UPI (then which bank account) and Credit Card (then which bank's card). Multiple accounts and cards, nicknames, last four digits, a default each, per-account and per-card tracking, manual correction.
- Lending: money lent is a transfer out, not an expense; a repayment is a transfer in, not income. No interest calculations.
- SMS detection (Android): every detected transaction becomes a card to confirm. Nothing is saved without confirmation. Review Inbox holds unconfirmed items. Play approval is not assumed; personal/sideloaded build is primary; paste or share of message text is the alternative. No iOS SMS detection. No paid parsing services.
- Travel: manual entry plus SMS detection; no paid booking APIs, no PNR scraping. Four reminder stages; the final ticket notification shows on the lock screen 15 minutes before departure, stays until Done, and is never cleared by the clock.
- Digital Wellbeing replaces the Parser Health and Reminder Health screens. Android priority; no promise on iOS.
- Assistant: strictly offline and rule-based. No AI service of any kind. Never present rules as AI.
- Final phase only: home-screen widgets and floating bubble. Multi-device sync is postponed in TO-DO.md.
- iOS: keep the build compiling; mark unverified features Coming Soon or Not Yet Verified; never claim iOS verification.

## Decisions from the design review (2026-11-14 to 16)

- Minimum Android 15 (API 35).
- Tabs: Today, Money, Travel, Planner (Notes and Tasks), More (Vault, Screen time, settings). Today header has Wellbeing and a theme switch.
- Review cards: stacked on Today, opening the Review Inbox; red delete with Undo; unclear items get one orange Review button.
- A credit card paid by UPI QR is a Credit Card expense. SMS senders are matched on the six-letter bank code.
- Add expense and transaction details are one shared form with a single green Save button.
- Accounts: no archived state; added from a sheet with a searchable bank list. A family-shared card counts as the owner's spending.
- Lending: no due dates or overdue state.
- Travel: a trip list with All, Train and Bus tabs; train and bus ticket details match the IRCTC and TNSTC SMS.
- Notes: colour cards, no folders, tap for Pin, Edit and Delete. Tasks: Today shows only overdue and today. Add sheets for both.
- Settings screens: Backup & restore, Task reminders (snooze, morning summary, quiet hours), Export logs. About screen postponed.

## Plan in brief

- Architecture: Flutter, feature-first, Riverpod, Drift on SQLite with SQLCipher, encrypted file store, in-repo native plugin (Kotlin; Swift later), event-driven background work only, no backend, no internet permission. Shared screens are one widget with a mode.
- Roadmap in focused days of about 6 hours: P0 foundation and spikes 6; P1 design system and shell 8; P2 expenses 10; P3 SMS capture and Review Inbox 10 (day 34); P4 lending 6; P5 travel and reminders 11; P6 Planner 9; P7 vault and backup 6; P8 wellbeing 6; P9 offline assistant 5 (core complete, day 77); P10 optional enhancements 6; P11 hardening and release 7 (v1.0 Android, day 90); P12 widgets and floating bubble 7 (day 97).

## Open points awaiting the user

1. The capture sheet: keep on every tab (default), keep only on Today, or remove it with the assistant.
2. Phone model and Android version. Phase 0 needs this.
3. Cash and non-UPI bank debits: default is cash untracked, other debits appear in the Review Inbox.
4. On-device proofreading and summarising through ML Kit GenAI (default: not built).
5. Stage 1 and 2 clock times (defaults 19:00 the evening before and 07:00).
6. Hours per week for review and device testing.

## Next steps

Merge the mockup and plan pull requests, then Phase 0.
