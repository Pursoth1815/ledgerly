package com.pursoth.loopd.spikes

import java.io.File
import java.io.FileInputStream
import java.security.MessageDigest
import java.util.Locale
import java.util.concurrent.atomic.AtomicBoolean

/*
 * Phase 0B spike lab: shared helpers. Profile builds only; nothing here ships
 * in a release build. The spikes report through a plain `(String) -> Unit`
 * so that their logic also runs in JVM unit tests.
 */

/** Where a spike writes its report lines. */
typealias Report = (String) -> Unit

const val MIB = 1024L * 1024L

/** The value at percentile [p] (0–100) of an already sorted array. */
fun percentile(sorted: LongArray, p: Double): Long {
    require(sorted.isNotEmpty()) { "No values" }
    require(p in 0.0..100.0) { "Percentile out of range" }
    val index = Math.ceil(p / 100.0 * sorted.size).toInt() - 1
    return sorted[index.coerceIn(0, sorted.size - 1)]
}

/** The median of [values]; the mean of the middle two for an even count. */
fun median(values: List<Long>): Long {
    require(values.isNotEmpty()) { "No values" }
    val sorted = values.sorted()
    val mid = sorted.size / 2
    return if (sorted.size % 2 == 1) sorted[mid] else (sorted[mid - 1] + sorted[mid]) / 2
}

fun nanosToMillis(nanos: Long): String = String.format(Locale.US, "%.2f", nanos / 1_000_000.0)

fun bytesToMib(bytes: Long): String = String.format(Locale.US, "%.1f", bytes / MIB.toDouble())

fun sha256(file: File): ByteArray {
    val digest = MessageDigest.getInstance("SHA-256")
    val buffer = ByteArray(1 shl 20)
    FileInputStream(file).use { input ->
        while (true) {
            val read = input.read(buffer)
            if (read < 0) break
            digest.update(buffer, 0, read)
        }
    }
    return digest.digest()
}

fun passFail(pass: Boolean): String = if (pass) "PASS" else "FAIL"

/**
 * Samples memory on a background thread while an operation runs and keeps the
 * peak growth over the starting level.
 *
 * Java heap growth includes garbage that has not been collected yet, so it is
 * an upper bound on what the operation really keeps alive. With
 * [collectBeforeSample] the sampler runs a garbage collection before each
 * sample, so the peak is the memory the operation really keeps alive (live
 * memory). That slows the operation, so its timings are not used.
 */
class MemoryProbe(
    private val nativeHeapBytes: () -> Long,
    private val intervalMillis: Long = 5,
    private val collectBeforeSample: Boolean = false,
) {
    data class Peak(val javaHeapBytes: Long, val nativeHeapBytes: Long) {
        val totalBytes: Long get() = javaHeapBytes + nativeHeapBytes
    }

    fun <T> measure(block: () -> T): Pair<T, Peak> {
        val runtime = Runtime.getRuntime()
        runtime.gc()
        Thread.sleep(50)
        val javaStart = runtime.totalMemory() - runtime.freeMemory()
        val nativeStart = nativeHeapBytes()
        val running = AtomicBoolean(true)
        // Written only by the sampler thread; read after join().
        var javaPeak = 0L
        var nativePeak = 0L
        val sample = {
            if (collectBeforeSample) runtime.gc()
            javaPeak = maxOf(javaPeak, runtime.totalMemory() - runtime.freeMemory() - javaStart)
            nativePeak = maxOf(nativePeak, nativeHeapBytes() - nativeStart)
        }
        val sampler = Thread {
            while (running.get()) {
                sample()
                Thread.sleep(intervalMillis)
            }
            sample()
        }
        sampler.isDaemon = true
        sampler.start()
        val result = try {
            block()
        } finally {
            running.set(false)
            sampler.join()
        }
        return result to Peak(javaPeak, nativePeak)
    }
}
