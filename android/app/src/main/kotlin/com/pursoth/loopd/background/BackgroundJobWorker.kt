package com.pursoth.loopd.background

import android.app.KeyguardManager
import android.content.Context
import android.os.PowerManager
import android.os.SystemClock
import androidx.work.BackoffPolicy
import androidx.work.CoroutineWorker
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequest
import androidx.work.OutOfQuotaPolicy
import androidx.work.WorkInfo
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.withContext
import java.util.concurrent.TimeUnit

/**
 * Runs one Dart background job (ADR 0013).
 *
 * The job runs in the app's own engine when that engine holds the
 * [WriterGate], and otherwise in the headless engine. A job that stops
 * because the app took the gate continues in the app's engine. A job that
 * Android stops (time limit, battery, restart) is retried, and the Dart job
 * continues from its last checkpoint.
 */
class BackgroundJobWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        val kind = inputData.getString(KEY_KIND) ?: return Result.failure()
        val runtime = BackgroundRuntime.get(applicationContext)
        val runId = id.toString()
        val started = SystemClock.elapsedRealtime()
        val tag = "kind=$kind run=${runId.take(8)} attempt=$runAttemptCount"
        val notBefore = inputData.getLong(KEY_NOT_BEFORE, 0)
        val late = if (notBefore > 0) " late_s=${(System.currentTimeMillis() - notBefore) / 1000}" else ""
        runtime.log.add("start $tag locked=${isDeviceLocked()} screen_on=${isScreenOn()}$late")

        var engineName = "none"
        fun took() = "took_s=${(SystemClock.elapsedRealtime() - started) / 1000}"
        fun end(result: Result, outcome: String): Result {
            runtime.log.add("end $tag engine=$engineName $outcome ${took()}")
            return result
        }

        try {
            repeat(MAX_HANDOVERS + 1) {
                val claim = runtime.gate.claimForBackground(runtime.headless)
                val lease = if (claim == WriterGate.Claim.Acquired) {
                    try {
                        runtime.headless.open()
                    } catch (e: EngineStartException) {
                        return end(Result.retry(), "outcome=retry reason=${e.code}")
                    }
                } else {
                    null
                }
                val engine = lease?.engine
                    ?: (claim as? WriterGate.Claim.UseApp)?.engine
                    ?: runtime.gate.awaitApp(APP_WAIT_MILLIS)
                    ?: return end(Result.retry(), "outcome=retry reason=app_not_ready")
                engineName = engine.name

                val result = try {
                    engine.run(runId, kind, runAttemptCount)
                } finally {
                    if (lease != null) withContext(NonCancellable) { runtime.headless.close(lease) }
                }
                when (result.outcome) {
                    Outcome.DONE -> return end(Result.success(), "outcome=done ${result.detail}")
                    Outcome.FAILED -> return end(Result.failure(), "outcome=failed ${result.detail}")
                    Outcome.STOPPED -> {
                        if (!runtime.gate.appWantsWriter) {
                            return end(Result.retry(), "outcome=stopped ${result.detail}")
                        }
                        runtime.log.add("handover $tag from=$engineName ${result.detail}")
                    }
                }
            }
            return end(Result.retry(), "outcome=retry reason=too_many_handovers")
        } catch (e: CancellationException) {
            runtime.log.add("stopped_by_android $tag engine=$engineName reason=${stopReasonName(stopReason)} ${took()}")
            throw e
        }
    }

    private fun isDeviceLocked(): Boolean =
        applicationContext.getSystemService(KeyguardManager::class.java)?.isDeviceLocked ?: false

    private fun isScreenOn(): Boolean =
        applicationContext.getSystemService(PowerManager::class.java)?.isInteractive ?: false

    companion object {
        private const val KEY_KIND = "kind"
        private const val KEY_NOT_BEFORE = "not_before"
        private const val MAX_HANDOVERS = 3
        private const val APP_WAIT_MILLIS = 30_000L
        const val TAG = "loopd.background"

        /**
         * Schedules the Dart job [kind] to run after [delayMillis], replacing
         * any unfinished work with the same [uniqueName].
         *
         * [expedited] work starts at once and may run while the phone sleeps
         * (Doze); it is for work started by an event, such as an SMS arriving
         * or a notification action, and cannot be delayed. Normal work waits
         * for Android's maintenance windows while the phone sleeps (measured
         * in Phase 0B).
         */
        fun enqueue(
            context: Context,
            kind: String,
            delayMillis: Long = 0,
            uniqueName: String = kind,
            expedited: Boolean = false,
        ) {
            require(!expedited || delayMillis == 0L) { "Expedited work cannot be delayed" }
            val input = Data.Builder()
                .putString(KEY_KIND, kind)
                .putLong(KEY_NOT_BEFORE, System.currentTimeMillis() + delayMillis)
                .build()
            val builder = OneTimeWorkRequest.Builder(BackgroundJobWorker::class.java)
                .setInputData(input)
                .setBackoffCriteria(BackoffPolicy.LINEAR, 30, TimeUnit.SECONDS)
                .addTag(TAG)
            if (expedited) {
                // Out of quota, it still runs, as normal work.
                builder.setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
            } else {
                builder.setInitialDelay(delayMillis, TimeUnit.MILLISECONDS)
            }
            val request = builder.build()
            WorkManager.getInstance(context).enqueueUniqueWork(uniqueName, ExistingWorkPolicy.REPLACE, request)
        }

        fun stopReasonName(reason: Int): String = when (reason) {
            WorkInfo.STOP_REASON_CANCELLED_BY_APP -> "cancelled_by_app"
            WorkInfo.STOP_REASON_PREEMPT -> "preempt"
            WorkInfo.STOP_REASON_TIMEOUT -> "timeout"
            WorkInfo.STOP_REASON_DEVICE_STATE -> "device_state"
            WorkInfo.STOP_REASON_QUOTA -> "quota"
            WorkInfo.STOP_REASON_BACKGROUND_RESTRICTION -> "background_restriction"
            WorkInfo.STOP_REASON_APP_STANDBY -> "app_standby"
            WorkInfo.STOP_REASON_USER -> "user"
            WorkInfo.STOP_REASON_SYSTEM_PROCESSING -> "system_processing"
            else -> "code_$reason"
        }
    }
}
