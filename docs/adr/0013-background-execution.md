# 0013 Background execution: headless engine and one writer

Status: Accepted; built in Phase 0B (16 Nov 2026)

## Context

The SMS parser is Dart. The review-card notification, notification actions, the daily usage snapshot and the weekly backup all happen while the app may be closed.

## Decision

- The SMS receiver saves the message to an encrypted queue and starts expedited WorkManager work.
- If the app is running, the work is handed to it. Otherwise a short-lived headless Flutter engine starts at `backgroundMain()`, uses the same engines, and shuts down when done.
- Notification actions, the usage snapshot and backups use the same path.
- Only one copy of the app writes the database at a time. The open app refreshes its live queries when it returns to the foreground.

## Alternatives considered

- Native parsing in Kotlin: would duplicate the parser.
- A permanent background service: costs battery and shows a notification.

## Consequences

- Behaviour on Tecno's HiOS is checked in Phase 0B (auto-start and battery settings).
