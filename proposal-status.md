# Personal App: proposal status

As of 2026-11-14. Stage reached: revision 2 of the proposal, awaiting approval. No code written yet.

Full proposal (Claude Doc, revised in place): https://claude.ai/artifact/5E9r7cyk2nPgheaf7iyGmj
Postponed features: `claude/TO-DO.md` in this project.

## Confirmed decisions (from the user's final instructions, 2026-11-13)

- Concept: capture, confirm, remember. Home screen is Today. Android-first, fully offline. Working name Kanakku.
- Core modules: Today, Expenses, Lending, Travel tickets, Notes, Tasks, Document Vault, Digital Wellbeing, offline assistant. Notes, Tasks and Vault are core, not deferred.
- Expenses: record only, never initiate payments. Exactly two payment methods in the UI: UPI (then which bank account) and Credit Card (then which bank's card). Multiple accounts and cards, nicknames, last four digits, a default each, per-account and per-card tracking, manual correction.
- Lending: money lent is a transfer out, not an expense; a repayment is a transfer in, not income. Monthly and ad hoc repayments. No interest calculations.
- SMS detection (Android): every detected transaction shows a card (amount, merchant, date, category, method, account or card) with two actions, Review and Looks Good. Nothing is saved without confirmation. Review Inbox holds unconfirmed items. Play approval is not assumed; personal/sideloaded build is primary; paste or share of message text is the alternative. No iOS SMS detection. No paid parsing services.
- Travel: manual entry plus SMS detection; no paid booking APIs, no PNR scraping. Four reminder stages: one day before, travel-day morning, three hours before, 15 minutes before. The final ticket notification shows on the lock screen where supported, stays until dismissed, is never auto-dismissed at departure time, has Show Ticket and Done. Stages update one notification where possible.
- Digital Wellbeing replaces the Parser Health and Reminder Health screens. Android priority; no promise on iOS.
- Assistant: strictly offline and rule-based. No Claude API, no Claude Pro integration, no OpenAI, no cloud or free-tier AI service, no paid inference. Never present rules as generative AI. Unsupported AI features are removed, not kept as future items.
- Kept: Review Inbox, encrypted backup and restore, app lock with biometrics, app-switcher privacy, contextual permission requests, shared logic for ledger, capture inbox and reminders.
- Removed: Global Search, Parser Health and Reminder Health screens, payment hand-off, Google Sheets backend, PNR scraping, custom keyboard, paid booking APIs, interest calculations, unsupported SMS techniques, paid or cloud AI.
- Final phase only: home-screen widgets and floating bubble. Upcoming debits is an optional enhancement. Multi-device sync is postponed in TO-DO.md.
- iOS: keep the build compiling; mark unverified features Coming Soon or Not Yet Verified; the user has no iPhone; never claim iOS verification.
- Do not start coding yet; no detailed folder structures or Dart files at this stage.

## Revised plan in brief

- Architecture: Flutter, feature-first, Riverpod (BLoC still possible), Drift on SQLite with SQLCipher, encrypted file store for vault and ticket files, in-repo native plugin (Kotlin; Swift later), event-driven background work only, no backend, no internet permission.
- Roadmap in focused days of about 6 hours: P0 foundation and spikes 6; P1 design system and Today 7; P2 expenses 9; P3 SMS capture and Review Inbox 10 (day 32); P4 lending 6; P5 travel and reminders 10; P6 notes and tasks 8; P7 vault and backup 6; P8 wellbeing 6; P9 offline assistant 5 (core complete, day 73); P10 optional enhancements 6; P11 hardening and release 7 (v1.0 Android, day 86); P12 widgets and floating bubble 7 (day 93).

## Open points awaiting the user

1. Cash and non-UPI bank debits (ATM, debit card, net banking, auto-debit): default is cash untracked, other debits appear in the Review Inbox to save under the bank account or dismiss.
2. Whether the Notes list may have its own text filter now that Global Search is removed (default: no).
3. Phone model and Android version; banks, cards, bus operators and booking apps that send SMS.
4. About 200 real bank and ticket SMS to scramble into test fixtures.
5. On-device proofreading and summarising through ML Kit GenAI, only if the phone supports it (default: not built).
6. Stage 1 and 2 clock times (defaults 19:00 the evening before and 07:00).
7. Riverpod or BLoC (default Riverpod).
8. Name (default Kanakku).
9. Hours per week for review and device testing.

## Next steps after approval

Mockups of the key screens in dark and light, then Phase 0.
