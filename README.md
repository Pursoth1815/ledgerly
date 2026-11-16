# Kanakku

A personal, Android-first app that turns bank and ticket SMS into cards you confirm, and keeps money, lending, travel, notes, tasks and documents in one place. It works fully offline: the app has no internet permission and no server.

Repository name: `ledgerly`. Working name of the app: **Kanakku**.

## Status

Planning and design are done; app code has not started.

| Item | Where |
| --- | --- |
| Product plan (revision 3.1) | [Personal App — Product Proposal & Phased Roadmap.md](Personal%20App%20—%20Product%20Proposal%20&%20Phased%20Roadmap.md) |
| Mockups and the design review record | [docs/mockups](docs/mockups/README.md) |
| Postponed and removed features | [TO-DO.md](TO-DO.md) |
| Decisions and open points | [proposal-status.md](proposal-status.md) |
| Rules for working on this repository | [CLAUDE.md](CLAUDE.md) |

Next step: Phase 0A, the architecture discussion and the folder structure.

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

Flutter, Riverpod, Drift on SQLite with SQLCipher, an encrypted file store, and a small in-repo Kotlin plugin for SMS, notifications, usage access and sharing.

## Workflow

Every change goes on its own branch. Nothing is committed or pushed until the owner has checked the changes and approved them; then it reaches `develop` through a pull request that the owner reviews and merges. `production` receives merges from `develop` at release points. See [CLAUDE.md](CLAUDE.md).
