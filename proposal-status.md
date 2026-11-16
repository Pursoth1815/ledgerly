# Personal App: proposal status

As of 2026-11-16. Stage reached: revision 3.1 of the proposal, after six rounds of design review on the mockups and the owner's answers of 16 November. No app code written yet.

- Full proposal: `Personal App — Product Proposal & Phased Roadmap.md` in this repository, mirrored in the Claude Doc at https://claude.ai/artifact/5E9r7cyk2nPgheaf7iyGmj (both at revision 3.1, including the roadmap diagram).
- Mockups and the review record: `docs/mockups/README.md`; canvas at https://claude.ai/artifact/LGbLMacN52Aq8mq8pi7bNa
- Postponed features: `TO-DO.md`.

## Confirmed decisions (from the user's final instructions, 2026-11-13)

- Concept: capture, confirm, remember. Home screen is Today. Android-first, fully offline. Working name Kanakku.
- Core modules: Today, Expenses, Lending, Travel tickets, Notes, Tasks, Document Vault, Digital Wellbeing, offline assistant. Notes, Tasks and Vault are core, not deferred.
- Expenses: record only, never initiate payments. Three payment methods in the UI: UPI (then which bank account), Credit Card (then which bank's card) and Cash (from one Cash in hand balance). Cash was added on 16 Nov 2026; before that there were exactly two. Multiple accounts and cards, nicknames, last four digits, a default each, per-account and per-card tracking, manual correction.
- Lending: money lent is a transfer out, not an expense; a repayment is a transfer in, not income. No interest calculations.
- SMS detection (Android): every detected transaction becomes a card to confirm. Nothing is saved without confirmation. Review Inbox holds unconfirmed items. Play approval is not assumed; personal/sideloaded build is primary; paste or share of message text is the alternative. No iOS SMS detection. No paid parsing services.
- Travel: manual entry plus SMS detection; no paid booking APIs, no PNR scraping. Four reminder stages, all counted from departure (24 hours, 12 hours, 3 hours, 15 minutes); the final ticket notification shows on the lock screen 15 minutes before departure, stays until Done, and is never cleared by the clock.
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

## Answers from the owner (2026-11-16)

- Capture sheet: stays on every tab (option a). Final once the sheet is designed and tested.
- Phone: Tecno Pova Curve 5G. Android version still to confirm.
- Cash: tracked. A third method, Cash, spends from one Cash in hand balance. ATM withdrawal SMS become Review Inbox cards that move money from the bank account to Cash in hand (a transfer, not spending). "Update count" records the difference as an adjustment outside spending. Debit-card, net-banking and auto-debit messages go to the Review Inbox under their bank account.
- On-device AI text features (ML Kit GenAI): not built. Listed as removed.
- Reminder times: travel stages follow the departure time, with no clock times and no travel setting. Only task reminders use times the owner picks: the lead, the snooze, the daily summary of overdue and today's tasks, and quiet hours. Payment cards, travel stages and other alerts follow their own rules; quiet hours apply to tasks only.
- Time: no limit. The day estimates size the work and are not a schedule.
- Workflow: once coding starts, Claude does not commit, push or open a pull request until the owner has checked the changes and approved them (see CLAUDE.md).

## Plan in brief

- Architecture: Flutter, feature-first, Riverpod, Drift on SQLite with SQLCipher, encrypted file store, in-repo native plugin (Kotlin; Swift later), event-driven background work only, no backend, no internet permission. Shared screens are one widget with a mode.
- Roadmap in focused days of about 6 hours: P0 architecture, structure and spikes 8 (0A architecture discussion and folder structure 4, 0B native spikes on the phone 4); P1 design system and shell 8; P2 expenses with cash 11; P3 SMS capture and Review Inbox 10 (day 37); P4 lending 6; P5 travel and reminders 11; P6 Planner 9; P7 vault and backup 6; P8 wellbeing 6; P9 offline assistant 5 (core complete, day 80); P10 optional enhancements 6; P11 hardening and release 7 (v1.0 Android, day 93); P12 widgets and floating bubble 7 (day 100). Sizes only, not deadlines.

## Open points awaiting the user

1. The phone's Android version (Settings › About phone). Phase 0B needs this; Phase 0A does not.
2. Text tools in section 10 have no screen: commands in the capture line (default), or drop them.

## Next steps

Phase 0A: discuss the architecture one topic at a time, record each decision in `docs/adr/`, then create the agreed folder structure.
