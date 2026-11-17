package com.pursoth.loopd.spikes

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import java.security.MessageDigest
import java.util.Random

/**
 * Phase 0B spike: writing to and reading back from the phone's folders and
 * cloud providers, through Android's file picker (ADR 0011: backups go to a
 * folder the owner picks; Loopd has no internet, so Drive's own app uploads).
 *
 * Writes [SIZE_MIB] MB of made-up bytes, reads them back, compares SHA-256,
 * then deletes the test file.
 */
class StorageSpike(private val context: Context) {
    /** A folder from the folder picker: the backup design keeps access to it permanently. */
    fun testFolder(tree: Uri, report: Report) {
        report("Picked folder from: ${tree.authority}")
        val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
        val kept = runCatching { context.contentResolver.takePersistableUriPermission(tree, flags) }.isSuccess
        report("Permanent access kept: $kept")
        val folder = DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))
        val file = try {
            DocumentsContract.createDocument(context.contentResolver, folder, MIME, FILE_NAME)
        } catch (e: Exception) {
            report("Could not create a file there: ${e.javaClass.simpleName}")
            report("Storage (folder) overall: FAIL")
            return
        }
        if (file == null) {
            report("Could not create a file there")
            report("Storage (folder) overall: FAIL")
            return
        }
        roundTrip(file, "folder", report)
    }

    /** One file from the save dialog; works with providers that cannot give a whole folder. */
    fun testFile(file: Uri, report: Report) {
        report("Saved file with: ${file.authority}")
        roundTrip(file, "one file", report)
    }

    private fun roundTrip(file: Uri, what: String, report: Report) {
        val resolver = context.contentResolver
        try {
            val digest = MessageDigest.getInstance("SHA-256")
            val chunk = ByteArray(MIB.toInt())
            val random = Random(SEED)
            val writeStart = System.nanoTime()
            resolver.openFileDescriptor(file, "wt")!!.use { pfd ->
                java.io.FileOutputStream(pfd.fileDescriptor).use { out ->
                    repeat(SIZE_MIB) {
                        random.nextBytes(chunk)
                        digest.update(chunk)
                        out.write(chunk)
                    }
                    out.flush()
                    runCatching { pfd.fileDescriptor.sync() }
                }
            }
            val writeMs = (System.nanoTime() - writeStart) / 1_000_000
            val written = digest.digest()

            val readStart = System.nanoTime()
            val readDigest = MessageDigest.getInstance("SHA-256")
            var bytes = 0L
            resolver.openInputStream(file)!!.use { input ->
                val buffer = ByteArray(256 * 1024)
                while (true) {
                    val n = input.read(buffer)
                    if (n < 0) break
                    readDigest.update(buffer, 0, n)
                    bytes += n
                }
            }
            val readMs = (System.nanoTime() - readStart) / 1_000_000
            val matches = readDigest.digest().contentEquals(written)
            report("Wrote $SIZE_MIB MB in $writeMs ms, read back ${bytesToMib(bytes)} MB in $readMs ms, matches: $matches")
            val deleted = runCatching { DocumentsContract.deleteDocument(resolver, file) }.getOrDefault(false)
            report("Test file deleted: $deleted")
            report("Storage ($what) overall: ${passFail(matches)}")
        } catch (e: Exception) {
            report("Storage ($what) stopped: ${e.javaClass.simpleName}")
            report("Storage ($what) overall: FAIL")
        }
    }

    companion object {
        const val FILE_NAME = "loopd-spike-test.bin"
        private const val MIME = "application/octet-stream"
        private const val SIZE_MIB = 20
        private const val SEED = 2026L
    }
}
