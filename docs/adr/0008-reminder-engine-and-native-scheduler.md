# 0008 Reminder engine and native scheduler

Status: Accepted (16 Nov 2026)

## Context

Trip stages, task reminders, the daily task summary, expiry and backup nudges must survive restarts and fire when the app is closed. The final ticket notification stays until Done.

## Decision

- The Dart reminder engine works out the desired schedule from records and compares it with what is scheduled.
- Kotlin owns alarms and notifications:
  - it stores the schedule it was given, each item with its notification content
  - it sets alarm-clock alarms (`setAlarmClock`), which need the exact-alarm permission, falling back to 10 minutes earlier if they are refused (owner's choice, 17 Nov 2026, from the Phase 0B results below)
  - it re-registers alarms and re-posts the ticket notification after a restart, a time change or an app update, without needing Dart
  - it draws and updates notifications
- Quiet hours apply to task reminders only. Fake-clock tests cover stage timing.

## Phase 0B results (17 Nov 2026, Tecno Pova Curve 5G, HiOS 16.3)

Read from the phone's system log over USB.

- **HiOS freezes the app.** About 5–12 s after Loopd leaves the screen, HiOS's `Usf_Hiber` freezes it and holds back its alarms ("proxy alarm"). This happened even with battery Unrestricted, App Launch allowed, and a running foreground service.
- **Alarms while frozen:**
  - A normal alarm (`setAndAllowWhileIdle`) was held about 7 minutes, until the owner opened the app.
  - An exact alarm (`setExactAndAllowWhileIdle`) was held until something else woke the app (60 s late in the test).
  - An alarm clock (`setAlarmClock`) unfroze the app (`reason=alarmClock`) and fired on time.
- **Notification actions:** HiOS unfreezes Loopd for a notification action, so Done works while it is frozen. The swipe's delete intent is not delivered to a frozen app, which is why re-posting after a swipe was dropped.
- **When Loopd is not running at all** (swiped out of recent apps), alarms start it normally. A normal alarm fired 90 s late while the phone slept.
- **Lock screen:** the ticket showed on the lock screen in the first test. In a later test its sound played but it was not shown there. The phone's "show only new notifications on the lock screen" setting is on (`lock_screen_show_only_unseen_notifications=1`). Phase 5 checks how this treats the final-stage update.
- **After a restart:** the ticket did not come back, either on the lock screen or after unlocking (owner's observation; the cause was not investigated, at the owner's request). The spike's receiver listens for `LOCKED_BOOT_COMPLETED` and `BOOT_COMPLETED`. HiOS may hold back start-up broadcasts the way it holds back alarms. **Not working yet: revisit when the real ticket is built in Phase 5.**
- Notification testing stopped here, at the owner's request (17 Nov 2026).

## Alternatives considered

- A scheduling package plus Kotlin: two schedulers and two restart paths.

## Consequences

- One owner for scheduling. Proven on the phone in Phase 0B; built in Phase 5.
- Pending: whether the personal build uses the install-time exact-alarm permission (`USE_EXACT_ALARM`). The spike lab uses it.
- The ⏰ icon shows while a Loopd reminder is pending, and Android lists it as the next alarm.
