# 0013 Background execution: headless engine and one writer

Status: Accepted (16 Nov 2026). Built and verified on the owner's phone in Phase 0B (17 Nov 2026).

## Context

The SMS parser is Dart. The review-card notification, notification actions, the daily usage snapshot and the weekly backup all happen while the app may be closed.

## Decision

- The SMS receiver saves the message to an encrypted queue and starts expedited WorkManager work.
- If the app is running, the work is handed to it. Otherwise a short-lived headless Flutter engine starts at `backgroundMain()`, uses the same engines, and shuts down when done.
- Notification actions, the usage snapshot and backups use the same path.
- Only one copy of the app writes the database at a time. The open app refreshes its live queries when it returns to the foreground.

## How it is built (Phase 0B)

- **Kotlin, `background/`:**
  - `BackgroundJobWorker`, a WorkManager `CoroutineWorker`, runs one Dart job by its kind.
  - `HeadlessEngineHost` starts the headless engine, shares it between the jobs running at that moment, and destroys it when the last one ends.
  - `WriterGate` holds the single-writer rule. Plain Kotlin, unit-tested.
- **Dart:** `core/background/` has `JobRunner`, the `BackgroundJob` interface and the `job_checkpoints` table (schema version 2). `app/background/app_jobs.dart` lists every job.
- **Pigeon:** `BackgroundHostApi` (Dart to Kotlin: `acquireWriter`, `engineReady`, `engineFailed`) and `BackgroundJobApi` (Kotlin to Dart: `runJob`, `stopJob`).
- **The writer gate:**
  - The app's engine calls `acquireWriter()` before opening the database and holds the gate until it is destroyed. While it holds the gate, every job runs inside it.
  - Otherwise the headless engine takes the gate.
  - If the app starts while the headless engine holds it, the running jobs are asked to stop at their next checkpoint. They are forced to stop after 10 s. The app then takes the gate, and the stopped job continues inside the app's engine.
  - While the app waits for the gate, no new background work starts.
- **Interruption:** long jobs save a checkpoint after each step. If Android stops the worker (time limit, battery, restart), Dart is asked to stop and given 3 s to save. WorkManager then retries the work (linear back-off, 30 s), and the job continues from its checkpoint.
- **The headless engine never creates a database.** If the app has not been opened yet, it reports `database.missing`.
- **Run log:** each run's start, engine, outcome and Android's stop reason go to `noBackupFilesDir/background/runs.log` (the newest 300 lines). Safe fields only (ADR 0014).
- **Keystore:** one `KeyStoreApiImpl` serves both engines, so Keystore calls never overlap.
- **Library:** `androidx.work:work-runtime` 2.12.0, pinned after checking Google's Maven on 17 Nov 2026 (released 23 Sep 2026).
  - It adds `WAKE_LOCK`, `RECEIVE_BOOT_COMPLETED` and `FOREGROUND_SERVICE`.
  - Its `ACCESS_NETWORK_STATE` is removed in the manifest, because Loopd never uses network constraints.
- **Self-test jobs**, in profile builds only, are started from the spike lab:
  - `self_test.quick`: 3 steps of 1 s, about the work of saving one SMS.
  - `self_test.short`: 30 steps of 1 s.
  - `self_test.long`: 900 steps of 1 s, about 15 minutes.

## Phase 0B results (17 Nov 2026)

- **Normal work while the phone sleeps (default HiOS battery settings):**
  - A job due at 15:09:17 started at 15:13:50, 272 s late.
  - It started only when the owner unlocked the phone and opened Loopd (`locked=false`), so it was held while the phone slept (Doze).
  - The headless engine then started, opened the database, finished all 30 steps in 30 s and shut down: PASS for the engine itself.
- **Expedited work started by an alarm while the phone is locked** (screen off, both apps closed):
  - The alarm fired 90 s late, and the work started at once with `locked=true screen_on=false`.
  - The headless engine opened the database within 1 s (`headless_ready database=open`). **Keystore while locked: PASS.**
  - The work was stopped about 5 s after it started, with stop reason `user`, in both runs: 15:28 with default battery settings, and 15:53 with battery Unrestricted (standby bucket exempted) and HiOS App Launch allowed.
  - When the phone was unlocked, WorkManager retried the work and it continued.
- **An SMS-sized expedited job while locked** (`self_test.quick`, 3 s of work, default battery settings): the alarm fired at 16:12:42 with `locked=true screen_on=false`, the engine was ready within 1 s, and the job finished with `outcome=done` in 4 s. PASS.
- **Hand-over and resume** (`self_test.long`, 900 steps, screen on):
  - The job started in the headless engine at 16:21:04.
  - The owner opened Loopd at 16:23:14. The job stopped at step 128 and the app took the gate in 317 ms.
  - The job continued in the app's engine from step 128 and finished at 16:36:18 (`step=900/900 resumes=1 this_run=772`, 914 s in all). PASS.
  - Android's run-time limit did not stop it in 15 minutes while Loopd was in the foreground. The stop-and-retry path was seen in the locked tests instead.

**Conclusions for the design:**
- **Event work** (an SMS arriving, a notification action) is **expedited** work started from the event. On HiOS 16 it gets about 5 s with the screen off, which is enough for saving one SMS to the Review Inbox, because the engine is ready in about 1 s. If it is cut short, it continues when the phone is unlocked, and nothing is lost.
- **Long work** (backup) is normal work. It runs when the phone is awake and continues from its checkpoint after any stop.
- Neither needs the owner to change battery settings. HiOS App Launch was already allowed, and Unrestricted battery did not change the 5 s limit. So the real app does not ask for a battery exemption.

## Alternatives considered

- Native parsing in Kotlin: would duplicate the parser.
- A permanent background service: costs battery and shows a notification.
- A cross-process file lock for the gate: not needed, because the app runs in one process.

## Consequences

- Behaviour on Tecno's HiOS is checked in Phase 0B (auto-start and battery settings).
- Not Yet Verified: whether a database connection can outlive a destroyed engine's isolates. SQLite's WAL mode and the busy timeout keep the file safe even then, but the rule is one writer, so the phone tests watch for it.
- iOS has no background engine yet (Not Yet Verified); `bootstrap()` skips the gate on iOS.
