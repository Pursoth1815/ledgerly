package com.pursoth.loopd.spikes

import com.pursoth.loopd.security.KeyWrapper
import java.io.DataInputStream
import java.io.DataOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.security.MessageDigest
import java.security.SecureRandom

/**
 * Phase 0B Keystore stress test (ADR 0009).
 *
 * 1. **Cycles:** wraps and unwraps a fresh 32-byte secret [cycles] times with
 *    the app's real master key and checks every round trip.
 * 2. **Restart probe:** the first run saves one wrapped secret with the phone's
 *    boot count. A run after a restart unwraps it, which proves the Keystore
 *    key survives a reboot.
 *
 * It only encrypts and decrypts with the master key. It never creates,
 * replaces or deletes a Keystore key, and never touches the database key file.
 */
class KeystoreStress(
    private val wrapper: KeyWrapper,
    private val probeFile: File,
    private val bootCount: () -> Int,
    private val random: SecureRandom = SecureRandom(),
) {
    enum class Probe { SAVED_NOW, SAME_BOOT, AFTER_RESTART, FAILED }

    data class Result(val cycles: Int, val failures: Int, val probe: Probe) {
        /** The pass mark: every cycle succeeded and the key worked after a restart. */
        val passed: Boolean get() = cycles > 0 && failures == 0 && probe == Probe.AFTER_RESTART
    }

    fun run(cycles: Int, report: Report): Result {
        report("Keystore stress test: $cycles wrap-and-unwrap cycles")
        val hasKey = try {
            wrapper.hasKey()
        } catch (e: Exception) {
            report("FAIL: the Keystore could not be queried (${e.javaClass.simpleName})")
            return Result(0, 1, Probe.FAILED)
        }
        if (!hasKey) {
            report("FAIL: no master key yet. Open the Loopd app once, then run this again.")
            return Result(0, 1, Probe.FAILED)
        }

        val probe = checkProbe(report)

        val times = LongArray(cycles)
        val failureTypes = linkedMapOf<String, Int>()
        val started = System.nanoTime()
        for (i in 0 until cycles) {
            val secret = ByteArray(32).also(random::nextBytes)
            val t0 = System.nanoTime()
            try {
                val wrapped = wrapper.wrap(secret, ASSOCIATED_DATA)
                val back = wrapper.unwrap(wrapped, ASSOCIATED_DATA)
                if (!back.contentEquals(secret)) failureTypes.merge("Mismatch", 1, Int::plus)
            } catch (e: Exception) {
                failureTypes.merge(e.javaClass.simpleName, 1, Int::plus)
            }
            times[i] = System.nanoTime() - t0
            if ((i + 1) % 250 == 0) report("  ${i + 1} cycles done")
        }
        val total = System.nanoTime() - started
        val failures = failureTypes.values.sum()

        times.sort()
        report("  total ${nanosToMillis(total)} ms")
        report(
            "  per cycle: median ${nanosToMillis(percentile(times, 50.0))} ms, " +
                "p95 ${nanosToMillis(percentile(times, 95.0))} ms, max ${nanosToMillis(times.last())} ms",
        )
        if (failures == 0) {
            report("  failures: 0")
        } else {
            report("  failures: $failures (${failureTypes.entries.joinToString { "${it.key} ×${it.value}" }})")
        }

        val result = Result(cycles, failures, probe)
        report("Cycles: ${passFail(failures == 0)}")
        report(
            when (probe) {
                Probe.AFTER_RESTART -> "After restart: PASS"
                Probe.SAVED_NOW, Probe.SAME_BOOT ->
                    "After restart: NOT YET. Restart the phone, open Loopd Spikes and run this again."
                Probe.FAILED -> "After restart: FAIL"
            },
        )
        report("Keystore overall: ${if (result.passed) "PASS" else if (failures == 0 && probe != Probe.FAILED) "WAITING FOR RESTART" else "FAIL"}")
        return result
    }

    private fun checkProbe(report: Report): Probe {
        val bootNow = bootCount()
        if (!probeFile.exists()) {
            return try {
                saveProbe(bootNow)
                report("  restart probe saved (boot $bootNow)")
                Probe.SAVED_NOW
            } catch (e: Exception) {
                report("  restart probe could not be saved (${e.javaClass.simpleName})")
                Probe.FAILED
            }
        }
        return try {
            val saved = readProbe()
            val secret = wrapper.unwrap(saved.wrapped, ASSOCIATED_DATA)
            if (!sha256(secret).contentEquals(saved.secretHash)) {
                report("  restart probe: the unwrapped secret does not match")
                Probe.FAILED
            } else if (saved.boot != bootNow) {
                report("  restart probe saved in boot ${saved.boot}, unwrapped in boot $bootNow")
                Probe.AFTER_RESTART
            } else {
                report("  restart probe unwrapped, but the phone has not restarted since it was saved (boot $bootNow)")
                Probe.SAME_BOOT
            }
        } catch (e: Exception) {
            report("  restart probe could not be unwrapped (${e.javaClass.simpleName})")
            Probe.FAILED
        }
    }

    private class SavedProbe(val boot: Int, val secretHash: ByteArray, val wrapped: ByteArray)

    private fun saveProbe(boot: Int) {
        val secret = ByteArray(32).also(random::nextBytes)
        val wrapped = wrapper.wrap(secret, ASSOCIATED_DATA)
        val dir = probeFile.parentFile ?: throw IOException("The probe file has no folder")
        if (!dir.exists() && !dir.mkdirs()) throw IOException("Cannot create the probe folder")
        val temp = File(dir, probeFile.name + ".tmp")
        DataOutputStream(FileOutputStream(temp)).use { out ->
            out.writeByte(PROBE_FORMAT)
            out.writeInt(boot)
            out.write(sha256(secret))
            out.writeInt(wrapped.size)
            out.write(wrapped)
        }
        if (!temp.renameTo(probeFile)) throw IOException("Cannot move the probe file into place")
    }

    private fun readProbe(): SavedProbe =
        DataInputStream(probeFile.inputStream()).use { input ->
            if (input.readByte().toInt() != PROBE_FORMAT) throw IOException("Unknown probe format")
            val boot = input.readInt()
            val hash = ByteArray(32).also(input::readFully)
            val size = input.readInt()
            if (size !in 1..4096) throw IOException("Bad probe size")
            val wrapped = ByteArray(size).also(input::readFully)
            SavedProbe(boot, hash, wrapped)
        }

    private fun sha256(bytes: ByteArray): ByteArray = MessageDigest.getInstance("SHA-256").digest(bytes)

    companion object {
        /** The app's master key alias (KeyStoreApiImpl). Used here to encrypt and decrypt only. */
        const val MASTER_KEY_ALIAS = "loopd_master_v1"
        private const val PROBE_FORMAT = 1
        private val ASSOCIATED_DATA = "loopd/spike/keystore-probe/v1".toByteArray(Charsets.UTF_8)
    }
}
