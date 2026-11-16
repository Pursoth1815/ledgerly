# 0008 Reminder engine and native scheduler

Status: Accepted (16 Nov 2026)

## Context

Trip stages, task reminders, the daily task summary, expiry and backup nudges must survive restarts and fire when the app is closed. The final ticket notification stays until Done.

## Decision

- The Dart reminder engine works out the desired schedule from records and compares it with what is scheduled.
- Kotlin owns alarms and notifications:
  - it stores the schedule it was given, each item with its notification content
  - it sets exact alarms, falling back to 10 minutes earlier if they are refused
  - it re-registers alarms and re-posts the ticket notification after a restart, a time change or an app update, without needing Dart
  - it draws and updates notifications
- Quiet hours apply to task reminders only. Fake-clock tests cover stage timing.

## Alternatives considered

- A scheduling package plus Kotlin: two schedulers and two restart paths.

## Consequences

- One owner for scheduling. Proven on the phone in Phase 0B; built in Phase 5.
- Pending: whether the personal build uses the install-time exact-alarm permission.
