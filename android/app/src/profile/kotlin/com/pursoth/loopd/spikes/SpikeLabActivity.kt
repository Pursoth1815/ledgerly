package com.pursoth.loopd.spikes

import android.app.Activity
import android.app.ActivityManager
import android.app.usage.UsageStatsManager
import android.content.Intent
import android.net.Uri
import android.graphics.Typeface
import android.os.Build
import android.os.Bundle
import android.os.Debug
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import android.view.View
import android.view.WindowInsets
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.work.WorkManager
import com.pursoth.loopd.background.BackgroundJobWorker
import com.pursoth.loopd.background.BackgroundRuntime
import com.pursoth.loopd.security.KeystoreKeyWrapper
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Phase 0B spike lab ("Loopd Spikes" on the launcher). Profile builds only.
 *
 * One button per spike. Every line is shown here, logged under the tag
 * `loopd.spike`, and appended to a results file in app-private storage, so
 * results survive a restart and can be shared with the Share button. The
 * results hold timings and pass marks only: no keys, no personal data.
 */
class SpikeLabActivity : Activity() {
    private lateinit var output: TextView
    private lateinit var scroll: ScrollView
    private val buttons = mutableListOf<Button>()
    private val worker: ExecutorService = Executors.newSingleThreadExecutor()
    private val resultsFile by lazy { File(filesDir, "spikes/results.txt") }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val pad = (16 * resources.displayMetrics.density).toInt()
        val column = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }

        column.addView(
            TextView(this).apply {
                text = "Loopd Spikes · Phase 0B"
                textSize = 22f
                setTypeface(typeface, Typeface.BOLD)
            },
        )
        column.addView(TextView(this).apply { text = deviceSummary(); textSize = 13f })

        addButton(column, "1 · Keystore: 1,000 cycles + restart check") { runKeystore() }
        addButton(column, "2 · Tink streaming benchmark (needs ~700 MB free)") { runStreaming() }
        addButton(column, "3 · Argon2id tuning") { runArgon2() }
        addButton(column, "Run 1, 2 and 3") { runKeystore(); runStreaming(); runArgon2() }
        addButton(column, "4 · Background: short job in 2 min (then lock the phone)") {
            startBackground(SHORT_JOB, delayMillis = 2 * 60_000L)
        }
        addButton(column, "4b · Locked test: alarm starts an urgent job in 2 min (then lock the phone)") {
            startLockedTest(SHORT_JOB)
        }
        addButton(column, "4c · Locked test, quick job (3 s, like saving one SMS)") { startLockedTest(QUICK_JOB) }
        addButton(column, "7 · Battery: allow Loopd to run in the background") { askUnrestrictedBattery() }
        addButton(column, "5 · Background: long job (15 min of work)") { startBackground(LONG_JOB, delayMillis = 0) }
        addButton(column, "6 · Background log and battery check") { showBackgroundLog() }
        addButton(column, "Share results") { shareResults() }
        addButton(column, "Clear results") { clearResults() }

        output = TextView(this).apply {
            typeface = Typeface.MONOSPACE
            textSize = 12f
            setTextIsSelectable(true)
            setPadding(0, pad, 0, pad)
            text = if (resultsFile.exists()) resultsFile.readText() else ""
        }
        column.addView(output)

        scroll = ScrollView(this).apply {
            addView(column)
            setOnApplyWindowInsetsListener { v, insets ->
                val bars = insets.getInsets(WindowInsets.Type.systemBars())
                v.setPadding(bars.left + pad, bars.top + pad, bars.right + pad, bars.bottom + pad)
                insets
            }
        }
        setContentView(scroll)
        // The long background test needs the screen on for about 15 minutes.
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    override fun onDestroy() {
        worker.shutdownNow()
        super.onDestroy()
    }

    private fun addButton(column: LinearLayout, label: String, action: () -> Unit) {
        val button = Button(this).apply {
            text = label
            isAllCaps = false
            setOnClickListener { action() }
        }
        buttons += button
        column.addView(button)
    }

    private fun runKeystore() = runSpike("Keystore stress") { report ->
        val stress = KeystoreStress(
            wrapper = KeystoreKeyWrapper(KeystoreStress.MASTER_KEY_ALIAS),
            probeFile = File(noBackupFilesDir, "spikes/keystore_probe.bin"),
            bootCount = { Settings.Global.getInt(contentResolver, Settings.Global.BOOT_COUNT, -1) },
        )
        stress.run(cycles = 1000, report = report)
    }

    private fun runStreaming() = runSpike("Tink streaming") { report ->
        StreamingBenchmark(
            workDir = File(cacheDir, "spike_streaming"),
            nativeHeapBytes = { Debug.getNativeHeapAllocatedSize() },
        ).run(report)
    }

    private fun runArgon2() = runSpike("Argon2id") { report -> Argon2Tuning().run(report) }

    /** Schedules a Dart self-test job through the real background path (ADR 0013). */
    private fun startBackground(kind: String, delayMillis: Long) = runSpike("Background $kind") { report ->
        BackgroundJobWorker.enqueue(applicationContext, kind, delayMillis)
        val at = SimpleDateFormat("HH:mm:ss", Locale.US).format(Date(System.currentTimeMillis() + delayMillis))
        report("Scheduled $kind to start at about $at (Android may run it later)")
        batteryStatus().forEach(report)
    }

    private fun startLockedTest(kind: String) = runSpike("Locked test $kind") { report ->
        SpikeAlarmReceiver.schedule(applicationContext, kind, delayMillis = 2 * 60_000L)
        val at = SimpleDateFormat("HH:mm:ss", Locale.US).format(Date(System.currentTimeMillis() + 2 * 60_000L))
        report("Alarm set for about $at; it starts $kind as urgent (expedited) work")
        batteryStatus().forEach(report)
    }

    /** Android's own dialog; the answer shows in the battery line of button 6. */
    private fun askUnrestrictedBattery() {
        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Uri.parse("package:$packageName"))
        startActivity(intent)
    }

    private fun showBackgroundLog() = runSpike("Background log") { report ->
        batteryStatus().forEach(report)
        val work = WorkManager.getInstance(applicationContext)
        for (kind in listOf(QUICK_JOB, SHORT_JOB, LONG_JOB)) {
            val states = work.getWorkInfosForUniqueWork(kind).get().map { "${it.state} (attempts ${it.runAttemptCount})" }
            report("$kind now: ${states.ifEmpty { listOf("never scheduled") }.joinToString()}")
        }
        val log = BackgroundRuntime.get(applicationContext).log.read().trim()
        report("Background run log, newest last:")
        if (log.isEmpty()) report("  (empty)") else log.lines().takeLast(80).forEach { report("  $it") }
    }

    /** What Android and HiOS allow this app to do in the background. */
    private fun batteryStatus(): List<String> {
        val power = getSystemService(PowerManager::class.java)
        val activity = getSystemService(ActivityManager::class.java)
        val usage = getSystemService(UsageStatsManager::class.java)
        val bucket = when (val value = usage.appStandbyBucket) {
            UsageStatsManager.STANDBY_BUCKET_ACTIVE -> "active"
            UsageStatsManager.STANDBY_BUCKET_WORKING_SET -> "working set"
            UsageStatsManager.STANDBY_BUCKET_FREQUENT -> "frequent"
            UsageStatsManager.STANDBY_BUCKET_RARE -> "rare"
            UsageStatsManager.STANDBY_BUCKET_RESTRICTED -> "restricted"
            else -> "other ($value)"
        }
        val unrestricted = power.isIgnoringBatteryOptimizations(packageName)
        return listOf(
            "Battery: ${if (unrestricted) "unrestricted (not optimised)" else "optimised (Android's default)"}" +
                " · background restricted: ${activity.isBackgroundRestricted}" +
                " · standby bucket: $bucket",
        )
    }

    /** Queues [spike] on the single worker thread, so spikes never overlap. */
    private fun runSpike(name: String, spike: (Report) -> Unit) {
        setRunning(true)
        worker.execute {
            val stamp = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US).format(Date())
            val report: Report = { line -> append(line) }
            report("")
            report("=== $name · $stamp")
            report(deviceSummary())
            try {
                spike(report)
            } catch (e: Throwable) {
                report("$name stopped: ${e.javaClass.simpleName}: ${e.message}")
            } finally {
                runOnUiThread { setRunning(false) }
            }
        }
    }

    private fun append(line: String) {
        Log.i(TAG, line)
        try {
            resultsFile.parentFile?.mkdirs()
            resultsFile.appendText(line + "\n")
        } catch (e: Exception) {
            Log.w(TAG, "results_write_failed type=${e.javaClass.simpleName}")
        }
        runOnUiThread {
            output.append(line + "\n")
            scroll.post { scroll.fullScroll(View.FOCUS_DOWN) }
        }
    }

    private var running = 0

    private fun setRunning(start: Boolean) {
        running += if (start) 1 else -1
        val busy = running > 0
        // Run buttons wait while a spike runs; Share stays usable.
        buttons.forEach { if (it.text != "Share results") it.isEnabled = !busy }
    }

    private fun shareResults() {
        val text = if (resultsFile.exists()) resultsFile.readText() else "No results yet."
        val send = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_SUBJECT, "Loopd Phase 0B spike results")
            putExtra(Intent.EXTRA_TEXT, text)
        }
        startActivity(Intent.createChooser(send, "Share results"))
    }

    private fun clearResults() {
        resultsFile.delete()
        output.text = ""
    }

    private fun deviceSummary(): String {
        val debuggable = (applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0
        return "${Build.MANUFACTURER} ${Build.MODEL} · Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT}) · " +
            "build ${Build.DISPLAY} · debuggable=$debuggable · max app memory " +
            "${bytesToMib(Runtime.getRuntime().maxMemory())} MB"
    }

    private companion object {
        const val TAG = "loopd.spike"
        const val QUICK_JOB = "self_test.quick"
        const val SHORT_JOB = "self_test.short"
        const val LONG_JOB = "self_test.long"
    }
}
