package com.pursoth.loopd.spikes

import com.pursoth.loopd.security.KeyWrapper
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File
import java.security.GeneralSecurityException
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class SpikeLogicTest {
    @get:Rule
    val temp = TemporaryFolder()

    private val lines = mutableListOf<String>()
    private val report: Report = { lines += it }

    // --- helpers -----------------------------------------------------------

    @Test
    fun percentileAndMedian() {
        val sorted = longArrayOf(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
        assertEquals(5L, percentile(sorted, 50.0))
        assertEquals(10L, percentile(sorted, 95.0))
        assertEquals(1L, percentile(sorted, 0.0))
        assertEquals(2L, median(listOf(3, 1, 2)))
        assertEquals(2L, median(listOf(4, 1, 3, 2)))
    }

    // --- Keystore stress ---------------------------------------------------

    @Test
    fun keystoreStressNeedsARestartBeforeItPasses() {
        val wrapper = FakeKeyWrapper()
        var boot = 7
        val probe = File(temp.root, "spikes/keystore_probe.bin")
        fun stress() = KeystoreStress(wrapper, probe, bootCount = { boot })

        val first = stress().run(cycles = 20, report = report)
        assertEquals(KeystoreStress.Probe.SAVED_NOW, first.probe)
        assertEquals(0, first.failures)
        assertFalse(first.passed)

        val sameBoot = stress().run(cycles = 20, report = report)
        assertEquals(KeystoreStress.Probe.SAME_BOOT, sameBoot.probe)
        assertFalse(sameBoot.passed)

        boot = 8
        val afterRestart = stress().run(cycles = 20, report = report)
        assertEquals(KeystoreStress.Probe.AFTER_RESTART, afterRestart.probe)
        assertTrue(afterRestart.passed)
        assertTrue(lines.contains("Keystore overall: PASS"))
    }

    @Test
    fun keystoreStressNeverCreatesAMasterKey() {
        val wrapper = FakeKeyWrapper(present = false)
        val result = KeystoreStress(wrapper, File(temp.root, "probe.bin"), bootCount = { 1 }).run(10, report)

        assertFalse(result.passed)
        assertFalse(wrapper.hasKey())
        assertEquals(0, wrapper.ensureCalls)
    }

    @Test
    fun keystoreStressCountsFailures() {
        val wrapper = FakeKeyWrapper(failEvery = 5)
        val result = KeystoreStress(wrapper, File(temp.root, "probe.bin"), bootCount = { 1 }).run(20, report)

        assertTrue(result.failures > 0)
        assertFalse(result.passed)
    }

    @Test
    fun keystoreStressRejectsATamperedProbe() {
        val wrapper = FakeKeyWrapper()
        val probe = File(temp.root, "probe.bin")
        KeystoreStress(wrapper, probe, bootCount = { 1 }).run(1, report)
        val bytes = probe.readBytes()
        bytes[bytes.size - 1] = (bytes[bytes.size - 1].toInt() xor 1).toByte()
        probe.writeBytes(bytes)

        val result = KeystoreStress(wrapper, probe, bootCount = { 2 }).run(1, report)
        assertEquals(KeystoreStress.Probe.FAILED, result.probe)
    }

    // --- Tink streaming ----------------------------------------------------

    @Test
    fun streamingRoundTripRestoresTheOriginal() {
        val aead = StreamingBenchmark.streamingAead(
            com.google.crypto.tink.streamingaead.PredefinedStreamingAeadParameters.AES256_GCM_HKDF_4KB,
        )
        val plain = File(temp.root, "plain.bin")
        val encrypted = File(temp.root, "encrypted.bin")
        val decrypted = File(temp.root, "decrypted.bin")
        val hash = StreamingBenchmark.writeRandom(plain, 2, seed = 42)

        StreamingBenchmark.encrypt(aead, plain, encrypted)
        StreamingBenchmark.decrypt(aead, encrypted, decrypted)

        assertTrue(encrypted.length() > plain.length())
        assertArrayEquals(hash, sha256(decrypted))
    }

    @Test
    fun customSegmentSizesRoundTrip() {
        val plain = File(temp.root, "plain.bin")
        val hash = StreamingBenchmark.writeRandom(plain, 1, seed = 7)
        for (bytes in listOf(64 * 1024, 256 * 1024)) {
            val aead = StreamingBenchmark.streamingAead(StreamingBenchmark.aes256GcmHkdf(bytes))
            val encrypted = File(temp.root, "e$bytes.bin")
            val decrypted = File(temp.root, "d$bytes.bin")
            StreamingBenchmark.encrypt(aead, plain, encrypted)
            StreamingBenchmark.decrypt(aead, encrypted, decrypted)
            assertArrayEquals(hash, sha256(decrypted))
        }
    }

    @Test
    fun streamingBenchmarkVerifiesEveryFileAndLeavesNothingBehind() {
        val work = File(temp.root, "work")
        val result = StreamingBenchmark(
            work,
            nativeHeapBytes = { 0L },
            sizesMib = listOf(1, 2),
            repeatsUpTo50Mib = 1,
            liveCheckMib = 2,
            segments = StreamingBenchmark.SEGMENTS.filter {
                it.first == StreamingBenchmark.SEGMENT_1MB || it.first == StreamingBenchmark.SEGMENT_4KB
            },
        ).run(report)

        assertEquals(4, result.measurements.size)
        assertTrue(result.allVerified)
        // Live memory is measured only at the live-check size.
        result.measurements.forEach {
            if (it.sizeMib == 2) assertNotNull(it.liveExtraBytes) else assertNull(it.liveExtraBytes)
        }
        // The pass-mark sizes were not run, so the overall result cannot pass.
        assertNull(result.decrypt20Pass(StreamingBenchmark.SEGMENT_1MB))
        assertTrue(result.passingSegments.isEmpty())
        assertNull(result.suggestedSegment)
        assertFalse(result.passed)
        assertEquals(0, work.listFiles()?.size ?: 0)
    }

    // --- Argon2id ------------------------------------------------------------

    @Test
    fun argon2idMatchesTheRfc9106Vector() {
        assertTrue(Argon2Tuning.rfc9106VectorMatches())
    }

    @Test
    fun argon2TuningReportsTimingsForASmallGrid() {
        val result = Argon2Tuning(memoriesMib = listOf(1), iterations = listOf(1), runsPerSetting = 1).run(report)

        assertTrue(result.vectorPassed)
        // The grid always adds RFC 9106's 64 MiB, t=3, p=4 setting.
        assertEquals(2, result.timings.size)
        result.timings.forEach { assertNotNull(it.slowestNanos) }
    }

    @Test
    fun argon2DeriveIsDeterministic() {
        val setting = Argon2Tuning.Setting(memoryMib = 1, iterations = 1, parallelism = 1)
        val salt = ByteArray(16) { 9 }
        val a = Argon2Tuning.derive("pass".toByteArray(), salt, setting)
        val b = Argon2Tuning.derive("pass".toByteArray(), salt, setting)
        assertArrayEquals(a, b)
    }
}

/** AES-GCM in memory, standing in for the Android Keystore on the JVM. */
private class FakeKeyWrapper(present: Boolean = true, private val failEvery: Int = 0) : KeyWrapper {
    private var key: SecretKey? = if (present) newKey() else null
    private var calls = 0
    var ensureCalls = 0

    override fun hasKey() = key != null

    override fun ensureKey() {
        ensureCalls++
        if (key == null) key = newKey()
    }

    override fun wrap(plaintext: ByteArray, associatedData: ByteArray): ByteArray {
        maybeFail()
        val iv = ByteArray(12).also(SecureRandom()::nextBytes)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key ?: throw GeneralSecurityException("no key"), GCMParameterSpec(128, iv))
        cipher.updateAAD(associatedData)
        return iv + cipher.doFinal(plaintext)
    }

    override fun unwrap(ciphertext: ByteArray, associatedData: ByteArray): ByteArray {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(
            Cipher.DECRYPT_MODE,
            key ?: throw GeneralSecurityException("no key"),
            GCMParameterSpec(128, ciphertext, 0, 12),
        )
        cipher.updateAAD(associatedData)
        return cipher.doFinal(ciphertext, 12, ciphertext.size - 12)
    }

    private fun maybeFail() {
        calls++
        if (failEvery > 0 && calls % failEvery == 0) throw GeneralSecurityException("simulated failure")
    }

    private fun newKey(): SecretKey = KeyGenerator.getInstance("AES").apply { init(256) }.generateKey()
}
