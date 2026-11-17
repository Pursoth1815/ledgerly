package com.pursoth.loopd.spikes

import android.app.Activity
import android.content.Intent
import android.graphics.Typeface
import android.os.Build
import android.os.Bundle
import android.os.Debug
import android.provider.Settings
import android.util.Log
import android.view.View
import android.view.WindowInsets
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
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
        if (busy) {
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
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
    }
}
