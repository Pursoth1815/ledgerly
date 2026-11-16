# CLAUDE.md

Rules for working on this repository. Read this before doing anything.

The app is called **Loopd**. It is an Android-first, fully offline personal app built on capture, confirm, remember.

## Source of truth

| File | What it holds |
| --- | --- |
| `Personal App — Product Proposal & Phased Roadmap.md` | The approved plan: modules, architecture, the 13 phases |
| `proposal-status.md` | Confirmed decisions and the open points still waiting on the owner |
| `TO-DO.md` | Postponed features, and removed features that must not come back |

If a request conflicts with these files, say so and ask before acting.

## Git workflow

The owner reviews and merges everything. Claude never merges its own work.

**Approval comes before git.** From 16 Nov 2026 onward (after the `docs/cash-and-owner-answers` branch), Claude makes changes in the working tree on a new branch and then stops. It does not commit, push or open a pull request until the owner has checked the changes and said they are approved. This covers all work, code and documents alike.

1. **One branch per feature or component.** Never commit to `production` or `develop` directly.
2. **Branch from the latest `develop`**, unless the owner says otherwise.
3. **Branch names:** `feat/<name>`, `fix/<name>`, `chore/<name>`, `docs/<name>`, `test/<name>`, `refactor/<name>`, `spike/<name>`. Use short kebab-case names, for example `feat/expense-entry` or `spike/sms-receiver`.
4. **Keep each branch small.** If a phase is large, split it into several branches. Each branch should be reviewable on its own.
5. **Commits** follow Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`, `test:`, `refactor:`).
6. **Before asking for approval:** `flutter analyze` is clean, `flutter test` passes, and the Android build succeeds. Report failures as failures.
7. **When the work is ready:** leave it uncommitted on the branch and tell the owner:
   - what changed and why,
   - how to test it on the phone, step by step,
   - what was not tested or is Not Yet Verified.
   Then wait. No commit, push or pull request yet.
8. **After the owner approves:** commit, push the branch and open a pull request into `develop`. `gh` is not installed, so give the compare link: `https://github.com/Pursoth1815/ledgerly/compare/develop...<branch>`.
9. **The owner** verifies the PR, merges it into `develop`, tests on the device and reports the results.
10. **Feedback on an open PR** is fixed on the same branch, and the fix also waits for the owner's approval before it is committed and pushed. A problem found after merge gets a new `fix/` branch.
11. **Never** force-push to `production` or `develop`, rewrite their history, delete remote branches, or change branch protection.
12. `production` only receives merges from `develop`, at release points such as the end of a phase, and only the owner does that.

## Platform targets

- **Android is the only implementation target for now.** iOS only has to compile.
- **Android 15 (API 35) is the minimum.** Set `minSdk = 35`. `targetSdk` and `compileSdk` follow the latest stable Android SDK.
- Because the minimum is Android 15, these always apply and need no fallback for older versions:
  - The sideloaded build needs "Allow restricted settings" once for SMS, usage access and the overlay bubble.
  - Exact alarms are denied by default and must be requested.
  - Ongoing notifications can be swiped away while the phone is unlocked.
- **iOS** must keep compiling, but it is never tested. Mark every iOS behaviour **Not Yet Verified** or **Coming Soon**. Never claim anything on iOS is verified.

## Product guardrails

- **No network.** The app ships without the internet permission. Do not add packages that need it at runtime.
- **No AI services** of any kind: no cloud APIs, no proxy, no keys. The assistant is rule-based and never called AI in the UI.
- **Nothing detected is saved silently.** Every detected item goes to the Review Inbox for the owner to confirm.
- **Money rules** go only through the ledger engine. Lending is a transfer, not an expense or income. Card bill payments are settlements. An ATM withdrawal is a transfer from a bank account to Cash in hand.
- **Removed features** (listed in `TO-DO.md`) must not come back under another name. **Postponed features** stay in `TO-DO.md` until the owner schedules them.
- **Do not add scope.** Suggest ideas instead, and add them to `TO-DO.md` only if the owner agrees.

## Privacy of test data

The repository is private, but treat it as if it might become public later.

- **Never commit raw SMS**, real account numbers, card numbers, phone numbers, names or reference numbers.
- Fixtures are scrambled before they are committed: digits replaced, names and merchants kept only where they are needed for parsing.
- Raw exports stay outside git, in a gitignored folder.

## Current stage

- The plan is at revision 3.2. The architecture was agreed on 16 Nov 2026 (proposal section 13, `docs/adr/`), and Phase 0A, the project foundations, was finished on 17 Nov 2026. Phase 0B is next.
- **Follow `docs/architecture.md`.** Run `dart run tool/check_architecture.dart` before handing anything over; it enforces the import rules and bans unsafe key APIs.
- Do not build anything that depends on a pending decision (proposal section 19); mark it pending instead.
- Phase 0B (native spikes) runs on the owner's Tecno Pova Curve 5G and needs its Android version confirmed. The encryption design is not production-ready until the Phase 0B tests and benchmarks pass on that phone.
- The mockups in `docs/mockups/` are the design reference. Build screens to match them, and record any change the owner asks for in `docs/mockups/README.md` and the proposal.
- Screens that share a pattern are one widget with a mode, as in the mockups: the expense form (add or review), the category sheet (expense or Vault), the settings page (backup, task reminders or logs), and the ticket details (train or bus).
- Every phase ends with the owner's approval before the next one starts.

## Design rules from the review

- Tabs: Today, Money, Travel, Planner (Notes and Tasks), More (Vault, Screen time, settings).
- Colours: one accent per module. UPI is green, Credit Card is violet and Cash is sky blue everywhere. Red for overdue and delete; orange for "needs review"; green for Save and Looks Good.
- Type: Plus Jakarta Sans, tabular figures for amounts; JetBrains Mono for PNRs and the command line.
- Detected items are never saved silently. Unclear ones get one orange Review button, not half-filled pickers.
- A credit card paid by UPI QR is a Credit Card expense. SMS senders are matched on the six-letter bank code.
- Lending has no due dates. Notes have no folders. Accounts have no archived state.
- Payment methods are UPI, Credit Card and Cash. Cash spends from one Cash in hand balance.
- Travel reminders are counted from departure and have no time setting. Only task reminders use times the owner picks, and quiet hours apply to tasks only.
- Mockups and the repo use made-up names and digits only.
