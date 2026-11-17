package com.pursoth.loopd.spikes

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Process
import java.util.Calendar

/**
 * Phase 0B spike: reading screen time (proposal: the Screen time module).
 *
 * Works out today's time in each app two ways, so the owner can compare both
 * with HiOS's own screen-time page:
 * - from foreground events (resumed to paused), which is what Loopd would use
 * - from Android's daily totals (`totalTimeVisible`)
 */
class UsageSpike(private val context: Context) {
    fun hasAccess(): Boolean {
        val appOps = context.getSystemService(AppOpsManager::class.java)
        val mode = appOps.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName)
        return mode == AppOpsManager.MODE_ALLOWED
    }

    fun run(report: Report) {
        if (!hasAccess()) {
            report("Usage access: NOT ALLOWED. Tap button 14 and turn it on for Loopd.")
            return
        }
        report("Usage access: allowed")
        val usage = context.getSystemService(UsageStatsManager::class.java)
        val start = startOfToday()
        val now = System.currentTimeMillis()

        val began = System.nanoTime()
        val byEvents = foregroundFromEvents(usage, start, now)
        val eventsMillis = (System.nanoTime() - began) / 1_000_000
        val daily = usage.queryAndAggregateUsageStats(start, now).mapValues { it.value.totalTimeVisible }

        val total = byEvents.values.sum()
        report("Today since midnight: ${minutes(total)} in apps (from events, read in $eventsMillis ms)")
        report("Top apps (events · Android's daily total):")
        byEvents.entries.sortedByDescending { it.value }.take(12).forEach { (pkg, millis) ->
            report("  ${label(pkg)}: ${minutes(millis)} · ${minutes(daily[pkg] ?: 0)}")
        }
    }

    /** Foreground time per package, from activity resumed and paused events since [start]. */
    private fun foregroundFromEvents(usage: UsageStatsManager, start: Long, end: Long): Map<String, Long> {
        val totals = mutableMapOf<String, Long>()
        val resumedAt = mutableMapOf<String, Long>()
        val events = usage.queryEvents(start, end)
        val event = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val key = event.packageName + "/" + event.className
            when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED -> resumedAt[key] = event.timeStamp
                UsageEvents.Event.ACTIVITY_PAUSED, UsageEvents.Event.ACTIVITY_STOPPED -> {
                    val from = resumedAt.remove(key) ?: continue
                    totals.merge(event.packageName, event.timeStamp - from, Long::plus)
                }
            }
        }
        // Still in the foreground now.
        resumedAt.forEach { (key, from) -> totals.merge(key.substringBefore('/'), end - from, Long::plus) }
        return totals.filterKeys { it != context.packageName }
    }

    private fun label(pkg: String): String = runCatching {
        val pm = context.packageManager
        pm.getApplicationLabel(pm.getApplicationInfo(pkg, 0)).toString()
    }.getOrDefault(pkg)

    private fun startOfToday(): Long = Calendar.getInstance().apply {
        set(Calendar.HOUR_OF_DAY, 0)
        set(Calendar.MINUTE, 0)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
    }.timeInMillis

    private fun minutes(millis: Long): String {
        val total = millis / 60_000
        return if (total >= 60) "${total / 60} h ${total % 60} min" else "$total min"
    }
}
