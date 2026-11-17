package com.pursoth.loopd.spikes

import org.bouncycastle.crypto.generators.Argon2BytesGenerator
import org.bouncycastle.crypto.params.Argon2Parameters
import java.security.SecureRandom

/**
 * Phase 0B Argon2id tuning for the backup passphrase (ADR 0009).
 *
 * First checks Bouncy Castle against the Argon2id test vector in RFC 9106,
 * then times a grid of memory and iteration settings and suggests the
 * strongest one that takes 0.5–1.5 s on this phone.
 */
class Argon2Tuning(
    private val memoriesMib: List<Int> = listOf(19, 32, 64, 128),
    private val iterations: List<Int> = listOf(1, 2, 3, 4),
    private val runsPerSetting: Int = 2,
    private val random: SecureRandom = SecureRandom(),
) {
    data class Setting(val memoryMib: Int, val iterations: Int, val parallelism: Int) {
        override fun toString() = "m=$memoryMib MiB, t=$iterations, p=$parallelism"
    }

    data class Timing(val setting: Setting, val slowestNanos: Long?, val error: String?) {
        val inWindow: Boolean get() = slowestNanos != null && slowestNanos in WINDOW_MIN..WINDOW_MAX
    }

    data class Result(val vectorPassed: Boolean, val timings: List<Timing>, val suggestion: Setting?) {
        val passed: Boolean get() = vectorPassed && suggestion != null
    }

    fun run(report: Report): Result {
        report("Argon2id tuning (Bouncy Castle), max app memory ${bytesToMib(Runtime.getRuntime().maxMemory())} MB")
        val vectorPassed = rfc9106VectorMatches()
        report("RFC 9106 test vector: ${passFail(vectorPassed)}")
        if (!vectorPassed) {
            report("Argon2id overall: FAIL")
            return Result(false, emptyList(), null)
        }

        val settings = memoriesMib.flatMap { m -> iterations.map { t -> Setting(m, t, 1) } } +
            Setting(64, 3, 4) // RFC 9106's second recommended setting
        val timings = mutableListOf<Timing>()
        val tooSlow = mutableSetOf<Pair<Int, Int>>()
        for (setting in settings) {
            // More iterations only take longer: skip them once a memory size is past 3 s.
            if (Pair(setting.memoryMib, setting.parallelism) in tooSlow) continue
            val timing = time(setting)
            timings += timing
            val window = if (timing.inWindow) "  ← in the 0.5–1.5 s window" else ""
            report(
                if (timing.error != null) {
                    "  $setting: ${timing.error}"
                } else {
                    "  $setting: ${nanosToMillis(timing.slowestNanos!!)} ms$window"
                },
            )
            if (timing.error != null || timing.slowestNanos!! > 3_000_000_000L) {
                tooSlow += Pair(setting.memoryMib, setting.parallelism)
            }
        }

        val suggestion = timings.filter { it.inWindow }
            .maxWithOrNull(compareBy<Timing>({ it.setting.memoryMib }, { it.setting.iterations }))
            ?.setting
        report(
            if (suggestion != null) {
                "Suggested: $suggestion (the most memory, then iterations, inside 0.5–1.5 s)"
            } else {
                "No setting fell inside 0.5–1.5 s"
            },
        )
        val result = Result(true, timings, suggestion)
        report("Argon2id overall: ${passFail(result.passed)}")
        return result
    }

    private fun time(setting: Setting): Timing {
        val password = "correct horse battery staple".toByteArray(Charsets.UTF_8)
        val salt = ByteArray(16).also(random::nextBytes)
        var slowest = 0L
        return try {
            repeat(runsPerSetting) {
                val start = System.nanoTime()
                derive(password, salt, setting)
                slowest = maxOf(slowest, System.nanoTime() - start)
            }
            Timing(setting, slowest, null)
        } catch (e: OutOfMemoryError) {
            Timing(setting, null, "FAIL, out of memory")
        }
    }

    companion object {
        const val WINDOW_MIN = 500_000_000L
        const val WINDOW_MAX = 1_500_000_000L

        fun derive(password: ByteArray, salt: ByteArray, setting: Setting, length: Int = 32): ByteArray {
            val parameters = Argon2Parameters.Builder(Argon2Parameters.ARGON2_id)
                .withVersion(Argon2Parameters.ARGON2_VERSION_13)
                .withIterations(setting.iterations)
                .withMemoryAsKB(setting.memoryMib * 1024)
                .withParallelism(setting.parallelism)
                .withSalt(salt)
                .build()
            return generate(parameters, password, length)
        }

        /** RFC 9106 section 5.3: the Argon2id test vector. */
        fun rfc9106VectorMatches(): Boolean {
            val parameters = Argon2Parameters.Builder(Argon2Parameters.ARGON2_id)
                .withVersion(Argon2Parameters.ARGON2_VERSION_13)
                .withIterations(3)
                .withMemoryAsKB(32)
                .withParallelism(4)
                .withSalt(ByteArray(16) { 0x02 })
                .withSecret(ByteArray(8) { 0x03 })
                .withAdditional(ByteArray(12) { 0x04 })
                .build()
            val tag = generate(parameters, ByteArray(32) { 0x01 }, 32)
            return tag.contentEquals(hex(RFC9106_ARGON2ID_TAG))
        }

        private fun generate(parameters: Argon2Parameters, password: ByteArray, length: Int): ByteArray {
            val generator = Argon2BytesGenerator()
            generator.init(parameters)
            val out = ByteArray(length)
            generator.generateBytes(password, out)
            return out
        }

        private const val RFC9106_ARGON2ID_TAG =
            "0d640df58d78766c08c037a34a8b53c9d01ef0452d75b65eb52520e96b01e659"

        private fun hex(text: String): ByteArray =
            ByteArray(text.length / 2) { i -> text.substring(i * 2, i * 2 + 2).toInt(16).toByte() }
    }
}
