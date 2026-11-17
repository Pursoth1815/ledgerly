package com.pursoth.loopd.spikes

import android.app.AlarmManager
import android.app.KeyguardManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import com.pursoth.loopd.background.BackgroundJobWorker
import com.pursoth.loopd.background.BackgroundRuntime

/**
 * Phase 0B locked-phone test. An alarm that may fire while the phone sleeps
 * stands in for an SMS arriving: like the SMS receiver will, it starts
 * expedited work, which runs the Dart job in the headless engine. The job
 * opens the database, so it also needs the Keystore while the phone is locked.
 */
class SpikeAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val locked = context.getSystemService(KeyguardManager::class.java)?.isDeviceLocked ?: false
        val due = intent.getLongExtra(EXTRA_DUE_WALL_CLOCK, 0)
        val late = if (due > 0) " late_s=${(System.currentTimeMillis() - due) / 1000}" else ""
        val kind = intent.getStringExtra(EXTRA_KIND) ?: return
        BackgroundRuntime.get(context).log.add("spike_alarm_fired kind=$kind locked=$locked$late")
        BackgroundJobWorker.enqueue(context, kind, uniqueName = kind, expedited = true)
    }

    companion object {
        private const val EXTRA_KIND = "kind"
        private const val EXTRA_DUE_WALL_CLOCK = "due"

        /** Sets an inexact alarm that Android allows while the phone sleeps (no exact-alarm permission). */
        fun schedule(context: Context, kind: String, delayMillis: Long) {
            val intent = Intent(context, SpikeAlarmReceiver::class.java)
                .putExtra(EXTRA_KIND, kind)
                .putExtra(EXTRA_DUE_WALL_CLOCK, System.currentTimeMillis() + delayMillis)
            val pending = PendingIntent.getBroadcast(
                context,
                0,
                intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            context.getSystemService(AlarmManager::class.java).setAndAllowWhileIdle(
                AlarmManager.ELAPSED_REALTIME_WAKEUP,
                SystemClock.elapsedRealtime() + delayMillis,
                pending,
            )
        }
    }
}
