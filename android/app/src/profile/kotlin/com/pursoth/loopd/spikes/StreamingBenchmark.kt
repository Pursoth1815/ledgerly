package com.pursoth.loopd.spikes

import com.google.crypto.tink.KeysetHandle
import com.google.crypto.tink.StreamingAead
import com.google.crypto.tink.streamingaead.AesGcmHkdfStreamingParameters
import com.google.crypto.tink.streamingaead.PredefinedStreamingAeadParameters
import com.google.crypto.tink.streamingaead.StreamingAeadConfig2026
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.InputStream
import java.io.OutputStream
import java.io.RandomAccessFile
import java.security.MessageDigest
import java.util.Random

/**
 * Phase 0B Tink streaming benchmark (ADR 0009, ADR 0010).
 *
 * Encrypts and decrypts files of each size in [sizesMib] with each segment
 * size in [segments], file to file, as the vault will. Encryption includes the fsync a
 * real save needs; decryption writes a temporary file, as PDFs will.
 *
 * The design does not fix a segment size (ADR 0010), so the pass marks are
 * judged for each segment size, and the fastest one that passes them all is
 * suggested:
 * - a 20 MB file decrypts in under 1 s (the PDF case)
 * - a 10 MB file encrypts in under 1 s (the photo case)
 * - 200 MB completes without a memory failure, with under 10 MB extra memory
 *
 * Extra memory is judged on live memory: a second pass at [liveCheckMib]
 * collects garbage before each sample. The timed passes also report the peak
 * including uncollected garbage, which depends on when the phone's garbage
 * collector happens to run rather than on what the vault code keeps.
 *
 * The keys are throwaway keys made in memory for the test; nothing is stored.
 */
class StreamingBenchmark(
    private val workDir: File,
    private val nativeHeapBytes: () -> Long,
    private val sizesMib: List<Int> = listOf(1, 10, 20, 50, 200),
    private val repeatsUpTo50Mib: Int = 3,
    private val liveCheckMib: Int = 200,
    private val segments: List<Pair<String, AesGcmHkdfStreamingParameters>> = SEGMENTS,
) {
    data class Measurement(
        val segment: String,
        val sizeMib: Int,
        val encryptNanos: Long,
        val decryptNanos: Long,
        val peakExtraBytes: Long,
        val verified: Boolean,
        /** Peak live memory (garbage collected before each sample); null when not measured. */
        val liveExtraBytes: Long? = null,
    )

    data class Result(val measurements: List<Measurement>, val errors: List<String>) {
        private fun find(segment: String, size: Int) =
            measurements.firstOrNull { it.segment == segment && it.sizeMib == size }

        fun decrypt20Pass(segment: String): Boolean? = find(segment, 20)?.let { it.decryptNanos < 1_000_000_000L }
        fun encrypt10Pass(segment: String): Boolean? = find(segment, 10)?.let { it.encryptNanos < 1_000_000_000L }
        fun memory200Pass(segment: String): Boolean? = find(segment, 200)?.liveExtraBytes?.let { it < 10 * MIB }

        val segments: List<String> get() = measurements.map { it.segment }.distinct()
        val allVerified: Boolean get() = measurements.isNotEmpty() && measurements.all { it.verified }

        /** Segment sizes that meet all three pass marks. */
        val passingSegments: List<String>
            get() = segments.filter {
                decrypt20Pass(it) == true && encrypt10Pass(it) == true && memory200Pass(it) == true
            }

        /** The passing segment size with the fastest 200 MB encrypt plus decrypt. */
        val suggestedSegment: String?
            get() = passingSegments.minByOrNull { segment ->
                find(segment, 200)!!.let { it.encryptNanos + it.decryptNanos }
            }

        val passed: Boolean get() = errors.isEmpty() && allVerified && passingSegments.isNotEmpty()
    }

    fun run(report: Report): Result {
        val config = StreamingAeadConfig2026.get()
        val measurements = mutableListOf<Measurement>()
        val errors = mutableListOf<String>()
        val probe = MemoryProbe(nativeHeapBytes)
        val liveProbe = MemoryProbe(nativeHeapBytes, intervalMillis = 20, collectBeforeSample = true)
        if (!workDir.exists()) workDir.mkdirs()
        val plain = File(workDir, "plain.bin")
        val encrypted = File(workDir, "encrypted.bin")
        val decrypted = File(workDir, "decrypted.bin")

        report("Tink streaming benchmark: sizes ${sizesMib.joinToString()} MB, segments ${segments.joinToString { it.first }}")
        try {
            for ((segment, parameters) in segments) {
                val aead = streamingAead(parameters, config)
                // Warm up the code paths once so the first size is not penalised.
                writeRandom(plain, 1, seed = 0)
                encrypt(aead, plain, encrypted)
                decrypt(aead, encrypted, decrypted)

                for (size in sizesMib) {
                    val needed = size * 3L * MIB + 64 * MIB
                    if (workDir.usableSpace < needed) {
                        val message = "$segment $size MB: skipped, needs ${bytesToMib(needed)} MB free space"
                        report(message)
                        errors += message
                        continue
                    }
                    try {
                        measurements += measure(aead, segment, size, plain, encrypted, decrypted, probe, liveProbe, report)
                    } catch (e: OutOfMemoryError) {
                        val message = "$segment $size MB: FAIL, out of memory"
                        report(message)
                        errors += message
                    } finally {
                        decrypted.delete()
                        encrypted.delete()
                    }
                }
            }
        } catch (e: Exception) {
            val message = "Benchmark stopped: ${e.javaClass.simpleName}: ${e.message}"
            report(message)
            errors += message
        } finally {
            plain.delete()
            encrypted.delete()
            decrypted.delete()
        }

        val result = Result(measurements, errors)
        fun mark(value: Boolean?) = when (value) {
            true -> "PASS"
            false -> "FAIL"
            null -> "NOT RUN"
        }
        for (segment in result.segments) {
            report(
                "$segment: 20 MB decrypt under 1 s ${mark(result.decrypt20Pass(segment))} · " +
                    "10 MB encrypt under 1 s ${mark(result.encrypt10Pass(segment))} · " +
                    "200 MB under 10 MB extra live memory ${mark(result.memory200Pass(segment))}",
            )
        }
        report("Every decrypted file matched its original: ${passFail(result.allVerified)}")
        report(
            "Segment sizes that pass every mark: " +
                result.passingSegments.ifEmpty { listOf("none") }.joinToString(),
        )
        result.suggestedSegment?.let { report("Suggested: $it (the fastest at 200 MB that passes every mark)") }
        report("Streaming overall: ${passFail(result.passed)}")
        return result
    }

    private fun measure(
        aead: StreamingAead,
        segment: String,
        size: Int,
        plain: File,
        encrypted: File,
        decrypted: File,
        probe: MemoryProbe,
        liveProbe: MemoryProbe,
        report: Report,
    ): Measurement {
        val originalHash = writeRandom(plain, size, seed = size.toLong())
        val repeats = if (size <= 50) repeatsUpTo50Mib else 1
        val encryptTimes = mutableListOf<Long>()
        val decryptTimes = mutableListOf<Long>()
        var peak = 0L
        var verified = true
        repeat(repeats) {
            val (encryptNanos, encryptPeak) = probe.measure { timed { encrypt(aead, plain, encrypted) } }
            val (decryptNanos, decryptPeak) = probe.measure { timed { decrypt(aead, encrypted, decrypted) } }
            encryptTimes += encryptNanos
            decryptTimes += decryptNanos
            peak = maxOf(peak, encryptPeak.totalBytes, decryptPeak.totalBytes)
            verified = verified && sha256(decrypted).contentEquals(originalHash)
        }
        val runs = if (repeats > 1) " (median of $repeats)" else ""
        report(
            "$segment $size MB: encrypt ${nanosToMillis(median(encryptTimes))} ms, " +
                "decrypt ${nanosToMillis(median(decryptTimes))} ms$runs, " +
                "peak extra memory incl. garbage ${bytesToMib(peak)} MB, " +
                if (verified) "matches" else "DOES NOT MATCH",
        )

        var live: Long? = null
        if (size == liveCheckMib) {
            val (_, encryptLive) = liveProbe.measure { encrypt(aead, plain, encrypted) }
            val (_, decryptLive) = liveProbe.measure { decrypt(aead, encrypted, decrypted) }
            verified = verified && sha256(decrypted).contentEquals(originalHash)
            live = maxOf(encryptLive.totalBytes, decryptLive.totalBytes)
            fun split(p: MemoryProbe.Peak) =
                "${bytesToMib(p.totalBytes)} MB (Java ${bytesToMib(p.javaHeapBytes)}, native ${bytesToMib(p.nativeHeapBytes)})"
            report("  $size MB live memory: encrypt ${split(encryptLive)}, decrypt ${split(decryptLive)}")
        }
        return Measurement(segment, size, median(encryptTimes), median(decryptTimes), peak, verified, live)
    }

    private inline fun timed(block: () -> Unit): Long {
        val start = System.nanoTime()
        block()
        return System.nanoTime() - start
    }

    companion object {
        const val SEGMENT_1MB = "AES256_GCM_HKDF_1MB"
        const val SEGMENT_256KB = "AES256_GCM_HKDF_256KB"
        const val SEGMENT_64KB = "AES256_GCM_HKDF_64KB"
        const val SEGMENT_4KB = "AES256_GCM_HKDF_4KB"

        /** Tink's two predefined sizes, plus two in between built the same way (AES-256, SHA-256). */
        val SEGMENTS: List<Pair<String, AesGcmHkdfStreamingParameters>> by lazy {
            listOf(
                SEGMENT_1MB to PredefinedStreamingAeadParameters.AES256_GCM_HKDF_1MB,
                SEGMENT_256KB to aes256GcmHkdf(256 * 1024),
                SEGMENT_64KB to aes256GcmHkdf(64 * 1024),
                SEGMENT_4KB to PredefinedStreamingAeadParameters.AES256_GCM_HKDF_4KB,
            )
        }

        fun aes256GcmHkdf(ciphertextSegmentBytes: Int): AesGcmHkdfStreamingParameters =
            AesGcmHkdfStreamingParameters.builder()
                .setKeySizeBytes(32)
                .setDerivedAesGcmKeySizeBytes(32)
                .setHkdfHashType(AesGcmHkdfStreamingParameters.HashType.SHA256)
                .setCiphertextSegmentSizeBytes(ciphertextSegmentBytes)
                .build()
        private const val COPY_BUFFER_BYTES = 256 * 1024
        private val ASSOCIATED_DATA = "loopd/spike/streaming/v1".toByteArray(Charsets.UTF_8)

        fun streamingAead(
            parameters: AesGcmHkdfStreamingParameters,
            config: com.google.crypto.tink.Configuration = StreamingAeadConfig2026.get(),
        ): StreamingAead = KeysetHandle.generateNew(parameters, config).getPrimitive(config, StreamingAead::class.java)

        /** Encrypts [source] into [target] and syncs it to storage, as a vault save would. */
        fun encrypt(aead: StreamingAead, source: File, target: File) {
            FileInputStream(source).use { input ->
                aead.newEncryptingStream(FileOutputStream(target), ASSOCIATED_DATA).use { output ->
                    copy(input, output)
                }
            }
            // Any descriptor of the file flushes its data to storage.
            RandomAccessFile(target, "rw").use { it.fd.sync() }
        }

        /** Decrypts [source] into the temporary file [target]. */
        fun decrypt(aead: StreamingAead, source: File, target: File) {
            aead.newDecryptingStream(FileInputStream(source), ASSOCIATED_DATA).use { input ->
                FileOutputStream(target).use { output -> copy(input, output) }
            }
        }

        /** Writes [sizeMib] MB of pseudo-random bytes to [file] and returns their SHA-256. */
        fun writeRandom(file: File, sizeMib: Int, seed: Long): ByteArray {
            val random = Random(seed)
            val digest = MessageDigest.getInstance("SHA-256")
            val chunk = ByteArray(MIB.toInt())
            FileOutputStream(file).use { out ->
                repeat(sizeMib) {
                    random.nextBytes(chunk)
                    digest.update(chunk)
                    out.write(chunk)
                }
            }
            return digest.digest()
        }

        private fun copy(input: InputStream, output: OutputStream) {
            val buffer = ByteArray(COPY_BUFFER_BYTES)
            while (true) {
                val read = input.read(buffer)
                if (read < 0) break
                output.write(buffer, 0, read)
            }
        }
    }
}
