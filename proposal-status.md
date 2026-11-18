# Personal App: proposal status

As of 2026-11-17. Stage reached: revision 3.2 of the proposal (architecture agreed). **Phase 0A, the project foundations, is done** (approved and tested on the owner's phone on 17 Nov 2026). **Phase 0B, the native spikes, is done** (tested on the owner's phone and merged on 17 Nov 2026). **Phase 1, the design system and Today shell, is done** (three parts, merged 17 Nov 2026). **Phase 2, expenses with UPI, Credit Card and Cash, is in progress.**

- Full proposal: `Personal App — Product Proposal & Phased Roadmap.md` in this repository, mirrored in the Claude Doc at https://claude.ai/artifact/5E9r7cyk2nPgheaf7iyGmj (the repository file is at revision 3.2; the Claude Doc is still at revision 3.1 and is updated after the owner approves 3.2).
- Mockups and the review record: `docs/mockups/README.md`; canvas at https://claude.ai/artifact/LGbLMacN52Aq8mq8pi7bNa
- Postponed features: `TO-DO.md`.

## Confirmed decisions (from the user's final instructions, 2026-11-13)

- Concept: capture, confirm, remember. Home screen is Today. Android-first, fully offline. Name: Loopd (chosen 16 Nov 2026).
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

- Capture sheet: stays on every tab (option a). Confirmed on 17 Nov 2026 after trying the Phase 1 sheet on the phone.
- Phone: Tecno Pova Curve 5G on Android 16, HiOS 16.3 (confirmed 17 Nov 2026). The minimum stays Android 15.
- Cash: tracked. A third method, Cash, spends from one Cash in hand balance. ATM withdrawal SMS become Review Inbox cards that move money from the bank account to Cash in hand (a transfer, not spending). "Update count" sets Cash in hand to what you counted; a new count replaces the last one, and the difference is not spending or an adjustment (changed 18 Nov 2026). Debit-card, net-banking and auto-debit messages go to the Review Inbox under their bank account.
- On-device AI text features (ML Kit GenAI): not built. Listed as removed.
- Reminder times: travel stages follow the departure time, with no clock times and no travel setting. Only task reminders use times the owner picks: the lead, the snooze, the daily summary of overdue and today's tasks, and quiet hours. Payment cards, travel stages and other alerts follow their own rules; quiet hours apply to tasks only.
- Time: no limit. The day estimates size the work and are not a schedule.
- Ticket notification (17 Nov 2026): posted once. It cannot be swiped away on the lock screen and survives Clear all; if it is swiped away while the phone is unlocked, it stays gone. Re-posting it after a swipe was tried in Phase 0B and dropped: HiOS freezes Loopd about 10 s after it leaves the screen, and a frozen app is not told about the swipe.
- SMS capture (17 Nov 2026): the SMS receiver is the fast path. Each time Loopd runs, it also reads the inbox for any messages it missed, because HiOS hides new-SMS signals from a frozen Loopd (ADR 0007).
- Screen time (17 Nov 2026): counted from apps' foreground events, which matched Digital Wellbeing to within a few minutes for the top apps. Android's daily `totalTimeVisible` was off by up to 2.5 times, so it is not used. App names need a launcher `<queries>` entry in the manifest (Phase 8). The home screen is left out of the totals.
- Phase 2 decisions (17 Nov 2026): debit-card, net-banking and auto-debit payments count as UPI (only UPI, Credit Card and Cash exist); refunds are reported in the purchase month by default, with a cash-flow switch in the Money tab; the last three backups are kept; every restore asks for the passphrase; a forgotten passphrase can be reset on this phone after a fingerprint, face or PIN check; the passphrase is at least 12 characters.
- Reminder alarms (17 Nov 2026): task reminders, travel stages and the final ticket use alarm-clock alarms (`setAlarmClock`). In Phase 0B they were the only kind that HiOS let through on time while Loopd was frozen; exact and normal alarms were held back until Loopd woke. Android shows the ⏰ icon and lists Loopd's next reminder as the next alarm.
- Workflow: once coding starts, Claude does not commit, push or open a pull request until the owner has checked the changes and approved them (see CLAUDE.md).

## Architecture decisions (2026-11-16)

Approved by the owner. Details in section 13 of the proposal, `docs/architecture.md` and `docs/adr/`.

- Feature-first folders with layers only where needed; one public file per feature; cross-module writes through core engines; imports checked in CI.
- Riverpod 3 with code generation; go_router with a five-tab shell; no interface-plus-implementation pairs.
- Drift on SQLCipher (the build bundled by the `sqlite3` package); one schema, a DAO per owner; one writer at a time.
- Double-entry ledger: signed postings in paise, stored payment method, refunds linked to originals (both reporting modes), many-SMS-to-one-transaction sources, opening and verified balances, edit history and undo.
- Keys: Android Keystore through Tink's `AndroidKeystore` helper; `AndroidKeysetManager` is not used; Tink streaming encryption for files, with 256 KiB segments; Argon2id (Bouncy Castle) for the backup passphrase, at m = 128 MiB, t = 4, p = 1 (both chosen 17 Nov 2026 from the Phase 0B results). Pinned: tink-android 1.24.0, bcprov-jdk18on 1.86.
- Kotlin in the app's own Android project, with one Pigeon interface; own Kotlin alarms and notifications; a headless background engine started by WorkManager.
- Backup: an index file plus encrypted parts, resumable, read back before it counts, never overwriting the last good backup.
- The encryption design counts as verified only after the Phase 0B tests and benchmarks on the owner's phone. Done on 17 Nov 2026: the Keystore stress test with a restart, the streaming benchmark and the Argon2id tuning all passed (ADR 0009). The Keystore test while the phone is locked also passed (ADR 0013).

## Plan in brief

- Architecture: as above. Event-driven background work only, no backend, no internet permission. Shared screens are one widget with a mode.
- Roadmap in focused days of about 6 hours: P0 architecture, foundations and spikes 9 (0A 4, 0B 5); P1 design system and shell 8; P2 expenses with cash 12; P3 SMS capture and Review Inbox 10 (day 39); P4 lending 6; P5 travel and reminders 11; P6 Planner 9; P7 vault and backup 7; P8 wellbeing 6; P9 offline assistant 5 (core complete, day 83); P10 optional enhancements 6; P11 hardening and release 7 (v1.0 Android, day 96); P12 widgets and floating bubble 7 (day 103). Sizes only, not deadlines.

## Open points awaiting the user

1. Text tools in section 10 have no screen: commands in the capture line (default), or drop them.
2. Architecture choices still pending (listed in section 19 of the proposal): the pairing window; weekly backup conditions; an in-app test restore (new scope); exact alarms in the personal build; keeping the original SMS text; iOS compile check frequency; a separate store application id; what to do if the Keystore proves unreliable.
3. How the personal build is installed (found in Phase 0B, 17 Nov 2026): Google Play Protect blocks installing it from a file (Files app, browser, messaging app) because it asks for SMS permissions. In India this is Google's anti-fraud rule for sideloaded apps. Installing from the Mac over USB (`adb`) works. Options: install and update over USB, or turn Play Protect scanning off while installing.

## Next steps

Phase 0B was tested on the owner's phone (Android 16, HiOS 16.3) on 17 Nov 2026. The results are in ADRs 0007, 0008, 0009, 0011 and 0013. It goes on one branch, `spike/phase0b`, and one pull request (owner's choice, 17 Nov 2026). Not working yet: the ticket coming back after a restart, which is revisited in Phase 5. Open point 3 (how the personal build is installed) waits on the owner. Phase 0B was approved and merged on 17 Nov 2026.

Phase 1 is built in three parts, each on its own branch and pull request, merged one at a time (owner's choice, 17 Nov 2026): design tokens and themes; shared components with a gallery; then the five-tab shell, Today, More and the capture sheet shell.

Phase 1 was finished on 17 Nov 2026 (PRs #26, #27, #28). Phase 2 is built in seven parts, each on its own branch and pull request, merged one at a time: the ledger engine; accounts and cards with Cash in hand; the expense form with editing and undo; categories; the Money tab with totals and refunds (its screen is designed on the canvas first); encrypted backup and restore; app lock and app-switcher privacy.

