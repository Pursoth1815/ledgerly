# CLAUDE.md

Rules for working on this repository. Read this before doing anything.

The app's working name is **Kanakku** (the repository is `ledgerly`). It is an Android-first, fully offline personal app built on capture, confirm, remember.

## Source of truth

| File | What it holds |
| --- | --- |
| `Personal App — Product Proposal & Phased Roadmap.md` | The approved plan: modules, architecture, the 13 phases |
| `proposal-status.md` | Confirmed decisions and the open points still waiting on the owner |
| `TO-DO.md` | Postponed features, and removed features that must not come back |

If a request conflicts with these files, say so and ask before acting.

## Git workflow

The owner reviews and merges everything. Claude never merges its own work.

1. **One branch per feature or component.** Never commit to `main` or `develop` directly.
2. **Branch from the latest `develop`**, unless the owner says otherwise.
3. **Branch names:** `feat/<name>`, `fix/<name>`, `chore/<name>`, `docs/<name>`, `test/<name>`, `refactor/<name>`, `spike/<name>`. Use short kebab-case names, for example `feat/expense-entry` or `spike/sms-receiver`.
4. **Keep each branch small.** If a phase is large, split it into several branches. Each branch should be reviewable on its own.
5. **Commits** follow Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`, `test:`, `refactor:`).
6. **Before saying a branch is done:** `flutter analyze` is clean, `flutter test` passes, and the Android build succeeds. Report failures as failures.
7. **When a branch is done:** push it and open a pull request into `develop`. Then tell the owner:
   - what changed and why,
   - how to test it on the phone, step by step,
   - what was not tested or is Not Yet Verified.
8. **The owner** verifies the PR, approves it, merges it into `develop`, tests on the device and reports the results.
9. **Feedback on an open PR** is fixed on the same branch. A problem found after merge gets a new `fix/` branch.
10. **Never** force-push to `main` or `develop`, rewrite their history, delete remote branches, or change branch protection.
11. `main` only receives merges from `develop`, and only the owner does that.

## Platform targets

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
- **Money rules** go only through the ledger engine. Lending is a transfer, not an expense or income. Card bill payments are settlements.
- **Removed features** (listed in `TO-DO.md`) must not come back under another name. **Postponed features** stay in `TO-DO.md` until the owner schedules them.
- **Do not add scope.** Suggest ideas instead, and add them to `TO-DO.md` only if the owner agrees.

## Privacy of test data

The repository is private, but treat it as if it might become public later.

- **Never commit raw SMS**, real account numbers, card numbers, phone numbers, names or reference numbers.
- Fixtures are scrambled before they are committed: digits replaced, names and merchants kept only where they are needed for parsing.
- Raw exports stay outside git, in a gitignored folder.

## Current stage

- The plan is approved. The next step is mockups of the key screens, then Phase 0.
- Do not start feature code until the owner approves the mockups.
- Every phase ends with the owner's approval before the next one starts.
