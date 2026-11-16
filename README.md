# Loopd

A personal, Android-first app that turns bank and ticket SMS into cards you confirm, and keeps money, lending, travel, notes, tasks and documents in one place. It works fully offline: the app has no internet permission and no server.

## Status

Planning, design and the architecture are done. Phase 0A, the project foundations, is done: the app opens an encrypted database and shows the five tabs. No feature is built yet.

| Item | Where |
| --- | --- |
| Product plan (revision 3.2) | [Personal App — Product Proposal & Phased Roadmap.md](Personal%20App%20—%20Product%20Proposal%20&%20Phased%20Roadmap.md) |
| Mockups and the design review record | [docs/mockups](docs/mockups/README.md) |
| Postponed and removed features | [TO-DO.md](TO-DO.md) |
| Decisions and open points | [proposal-status.md](proposal-status.md) |
| Rules for working on this repository | [CLAUDE.md](CLAUDE.md) |
| Architecture and decision records | [docs/architecture.md](docs/architecture.md), [docs/adr](docs/adr/README.md) |

Next step: Phase 0B, the native spikes and benchmarks on the owner's phone. See [docs/architecture.md](docs/architecture.md) for how the code is organised.

## What it does

| Tab | What is in it |
| --- | --- |
| Today | Detected items waiting for confirmation, trips this week, tasks, money lent to friends, spending, screen time, backup nudge |
| Money | Expenses (UPI, Credit Card or Cash), accounts and cards, Cash in hand, lending |
| Travel | Train and bus trips, ticket details, four reminders counted from departure, ending with the ticket on the lock screen 15 minutes before departure |
| Planner | Notes and tasks |
| More | Document Vault, screen time, and settings |

## Platform

- Android 15 (API 35) and later. Built and tested on Android.
- iOS keeps compiling, but nothing on it is verified, because there is no iPhone to test on.

## Tech

Flutter with Riverpod 3 and go_router; Drift on SQLCipher; Tink for keys and file encryption, with keys protected by the Android Keystore; Kotlin in the app's Android project, reached through Pigeon. Decisions are in [docs/adr](docs/adr/README.md).

## Workflow

Every change goes on its own branch. Nothing is committed or pushed until the owner has checked the changes and approved them; then it reaches `develop` through a pull request that the owner reviews and merges. `production` receives merges from `develop` at release points. See [CLAUDE.md](CLAUDE.md).
