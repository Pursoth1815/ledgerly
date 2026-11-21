package com.pursoth.loopd.bridge

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.net.Uri
import android.provider.DocumentsContract
import android.util.Log
import com.pursoth.loopd.MainActivity
import com.pursoth.loopd.backup.BackupException
import com.pursoth.loopd.backup.BackupFailure
import com.pursoth.loopd.backup.BackupKeys
import com.pursoth.loopd.backup.BackupReader
import com.pursoth.loopd.backup.BackupWriter
import com.pursoth.loopd.backup.Manifest
import com.pursoth.loopd.backup.findBackups
import com.google.crypto.tink.StreamingAead
import com.pursoth.loopd.backup.DocumentTreeFolder
import com.pursoth.loopd.backup.Passphrase
import com.pursoth.loopd.backup.RunInfo
import com.pursoth.loopd.backup.SourceEntry
import com.pursoth.loopd.security.KeystoreKeyWrapper
import kotlinx.coroutines.CancellableContinuation
import kotlinx.coroutines.asCoroutineDispatcher
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileNotFoundException
import java.io.IOException
import java.util.concurrent.Executors
import kotlin.coroutines.resume

/**
 * Pigeon host implementation of [BackupApi] (ADR 0011).
 *
 * Heavy work (Argon2id, encryption, reading back) runs on one background
 * thread, one call at a time. The folder picker needs the activity, which
 * [MainActivity] hands over with [attach].
 *
 * Logs only what happened and failure codes, never names, keys or sizes of
 * what is inside.
 */
class BackupApiImpl private constructor(private val context: Context) : BackupApi {
    private val worker = Executors.newSingleThreadExecutor { r -> Thread(r, "loopd-backup") }.asCoroutineDispatcher()
    private val keyDir = File(context.noBackupFilesDir, "keys")
    private val keys = BackupKeys(
        wrapper = KeystoreKeyWrapper(MASTER_KEY_ALIAS),
        keysetFile = File(keyDir, "backup.keyset"),
        passphraseFile = File(keyDir, "backup.pass"),
    )

    private var activity: Activity? = null

    /** The backup unlocked by [openBackup], for checking and extracting it. */
    private class Opened(val folderUri: String, val indexName: String, val aead: StreamingAead, val manifest: Manifest)

    private var opened: Opened? = null
    private var pendingPick: CancellableContinuation<BackupFolderInfo?>? = null

    fun attach(activity: Activity?) {
        this.activity = activity
    }

    /** Called from the activity's onActivityResult. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != PICK_FOLDER) return false
        val waiting = pendingPick ?: return true
        pendingPick = null
        val tree = data?.data
        if (resultCode != Activity.RESULT_OK || tree == null) {
            waiting.resume(null)
            return true
        }
        val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
        val kept = runCatching { context.contentResolver.takePersistableUriPermission(tree, flags) }.isSuccess
        Log.i(TAG, "folder_picked kept=$kept")
        waiting.resume(if (kept) BackupFolderInfo(tree.toString(), displayName(tree)) else null)
        return true
    }

    override suspend fun pickFolder(): BackupFolderInfo? {
        val host = activity ?: throw FlutterError("cancelled", "No screen to show the picker on")
        return suspendCancellableCoroutine { continuation ->
            pendingPick?.resume(null)
            pendingPick = continuation
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
            )
            host.startActivityForResult(intent, PICK_FOLDER)
            continuation.invokeOnCancellation { pendingPick = null }
        }
    }

    override fun canWrite(folderUri: String): Boolean =
        context.contentResolver.persistedUriPermissions.any { it.uri.toString() == folderUri && it.isWritePermission }

    override suspend fun setUp(passphrase: String) = work("set_up") {
        val bytes = passphrase.toByteArray(Charsets.UTF_8)
        try {
            if (passphrase.length < Passphrase.MIN_LENGTH) throw FlutterError("write_failed", "Too short")
            keys.setUp(bytes)
        } finally {
            bytes.fill(0)
        }
    }

    override fun isSetUp(): Boolean = runCatching { keys.isSetUp() }.getOrDefault(false)

    override suspend fun writeBackup(request: BackupRequest): BackupWritten = work("write") {
        val folder = folder(request.folderUri)
        val database = File(request.databasePath)
        val written = BackupWriter(keys.streamingAead(), folder).write(
            RunInfo(request.runId, request.createdAt, request.appVersion.ifBlank { appVersion() }, request.schemaVersion.toInt()),
            listOf(SourceEntry("database", database, mapOf("kind" to "sqlcipher", "key" to request.databaseKeyHex))),
            keys.passphraseWrap(),
        )
        BackupWritten(written.indexName, written.files, written.totalBytes)
    }

    override suspend fun verifyBackup(folderUri: String, indexName: String) = work("verify") {
        BackupReader(folder(folderUri)).verify(indexName, keys.streamingAead())
        Unit
    }

    override suspend fun deleteFiles(folderUri: String, names: List<String>) = work("delete") {
        val folder = folder(folderUri)
        for (name in names) {
            if (!name.startsWith("loopd-")) continue // only files Loopd made
            folder.delete(name)
        }
    }

    /** "0.1.0+1": the installed version name and code, recorded in each manifest. */
    private fun appVersion(): String = runCatching {
        val info = context.packageManager.getPackageInfo(context.packageName, 0)
        "${info.versionName}+${info.longVersionCode}"
    }.getOrDefault("unknown")

    override suspend fun listBackups(folderUri: String): List<FoundBackupInfo> = work("list") {
        findBackups(folder(folderUri)).map { FoundBackupInfo(it.indexName, it.runId, it.parts.toLong(), it.totalBytes) }
    }

    override suspend fun openBackup(folderUri: String, indexName: String, passphrase: String): OpenedBackupInfo =
        work("open") {
            opened = null
            val folder = folder(folderUri)
            val reader = BackupReader(folder)
            val wrap = reader.header(indexName)
            val bytes = passphrase.toByteArray(Charsets.UTF_8)
            val aead = try {
                BackupKeys.open(wrap, bytes)
            } finally {
                bytes.fill(0)
            }
            val manifest = reader.manifest(indexName, aead)
            opened = Opened(folderUri, indexName, aead, manifest)
            OpenedBackupInfo(manifest.runId, manifest.createdAt, manifest.appVersion, manifest.schemaVersion.toLong(), manifest.parts.size.toLong())
        }

    override suspend fun verifyOpenedBackup() = work("check") {
        val o = opened ?: throw BackupException(BackupFailure.NOT_A_BACKUP, "No backup is open")
        BackupReader(folder(o.folderUri)).verify(o.indexName, o.aead)
        Unit
    }

    override suspend fun extractOpenedDatabase(targetPath: String): String = work("extract") {
        val o = opened ?: throw BackupException(BackupFailure.NOT_A_BACKUP, "No backup is open")
        try {
            val entry = o.manifest.entries.firstOrNull { it.name == "database" }
                ?: throw BackupException(BackupFailure.NOT_A_BACKUP, "No database in this backup")
            val key = entry.meta["key"] ?: throw BackupException(BackupFailure.NOT_A_BACKUP, "No key for the database")
            val target = File(targetPath)
            target.parentFile?.mkdirs()
            target.outputStream().use { out -> BackupReader(folder(o.folderUri)).extract(o.manifest, entry, o.aead, out) }
            if (target.length() != entry.size) {
                target.delete()
                throw BackupException(BackupFailure.VERIFY_FAILED, "The database came out the wrong size")
            }
            key
        } finally {
            opened = null
        }
    }

    override fun restartApp() {
        Log.i(TAG, "restart_for_restore")
        // Loopd's own screen by name: profile builds have a second launcher
        // icon (the Phase 0B spike lab), which the package's launch intent
        // could pick instead.
        val launch = Intent(context, MainActivity::class.java)
            .setAction(Intent.ACTION_MAIN)
            .addCategory(Intent.CATEGORY_LAUNCHER)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
        context.startActivity(launch)
        // A fresh process, so the database is opened (and the restore switched in) from the start.
        android.os.Process.killProcess(android.os.Process.myPid())
    }

    override suspend fun changePassphrase(current: String, next: String) = work("change_passphrase") {
        val old = current.toByteArray(Charsets.UTF_8)
        val new = next.toByteArray(Charsets.UTF_8)
        try {
            if (!keys.checkPassphrase(old)) throw BackupException(BackupFailure.WRONG_PASSPHRASE, "Not the current passphrase")
            keys.setUp(new)
        } finally {
            old.fill(0)
            new.fill(0)
        }
    }

    /** When the owner last confirmed it is them, for [resetPassphrase]. */
    @Volatile private var confirmedAt = 0L

    override suspend fun confirmOwner(title: String, subtitle: String): Boolean {
        val host = activity ?: throw FlutterError("cancelled", "No screen to ask on")
        val ok = OwnerCheck.ask(host, title, subtitle)
        if (ok) confirmedAt = SystemClock.elapsedRealtime()
        Log.i(TAG, "owner_check passed=$ok")
        return ok
    }

    override suspend fun resetPassphrase(next: String) = work("reset_passphrase") {
        val fresh = confirmedAt != 0L && SystemClock.elapsedRealtime() - confirmedAt < CONFIRM_WINDOW_MS
        confirmedAt = 0L
        if (!fresh) throw FlutterError("cancelled", "Confirm it is you first")
        val bytes = next.toByteArray(Charsets.UTF_8)
        try {
            keys.rewrap(bytes)
        } finally {
            bytes.fill(0)
        }
    }

    private fun folder(uri: String): DocumentTreeFolder {
        if (!canWrite(uri)) throw BackupException(BackupFailure.FOLDER_LOST, "No access to the folder")
        return DocumentTreeFolder(context, Uri.parse(uri))
    }

    /** "Drive › Loopd backups": the provider's name, then the folder's. */
    private fun displayName(tree: Uri): String {
        val provider = when (tree.authority) {
            "com.google.android.apps.docs.storage" -> "Drive"
            "com.android.externalstorage.documents" -> "Phone"
            "com.android.providers.downloads.documents" -> "Downloads"
            else -> runCatching {
                context.packageManager.resolveContentProvider(tree.authority ?: "", 0)?.loadLabel(context.packageManager)?.toString()
            }.getOrNull() ?: "Files"
        }
        val document = DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))
        val folder = runCatching {
            context.contentResolver.query(document, arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME), null, null, null)
                ?.use { if (it.moveToFirst()) it.getString(0) else null }
        }.getOrNull()
        return if (folder.isNullOrBlank()) provider else "$provider › $folder"
    }

    /** Runs [block] on the backup thread and turns failures into the Pigeon codes. */
    private suspend fun <T> work(step: String, block: () -> T): T = withContext(worker) {
        try {
            block().also { Log.i(TAG, "${step}_done") }
        } catch (e: FlutterError) {
            Log.w(TAG, "${step}_failed code=${e.code}")
            throw e
        } catch (e: BackupException) {
            Log.w(TAG, "${step}_failed code=${e.failure.code}")
            throw FlutterError(e.failure.code, e.message)
        } catch (e: SecurityException) {
            Log.w(TAG, "${step}_failed code=folder_lost")
            throw FlutterError(BackupFailure.FOLDER_LOST.code, "No access to the folder")
        } catch (e: FileNotFoundException) {
            Log.w(TAG, "${step}_failed code=folder_lost")
            throw FlutterError(BackupFailure.FOLDER_LOST.code, "The folder is gone")
        } catch (e: IOException) {
            val full = e.message?.contains("ENOSPC") == true || e.message?.contains("No space", ignoreCase = true) == true
            val code = if (full) BackupFailure.OUT_OF_SPACE.code else BackupFailure.WRITE_FAILED.code
            Log.w(TAG, "${step}_failed code=$code type=${e.javaClass.simpleName}")
            throw FlutterError(code, e.javaClass.simpleName)
        } catch (e: OutOfMemoryError) {
            Log.w(TAG, "${step}_failed code=write_failed type=out_of_memory")
            throw FlutterError(BackupFailure.WRITE_FAILED.code, "Out of memory")
        } catch (e: RuntimeException) {
            Log.w(TAG, "${step}_failed code=write_failed type=${e.javaClass.simpleName}")
            throw FlutterError(BackupFailure.WRITE_FAILED.code, e.javaClass.simpleName)
        }
    }

    companion object {
        private const val TAG = "loopd.backup"
        private const val MASTER_KEY_ALIAS = "loopd_master_v1"
        private const val PICK_FOLDER = 4101

        /** How long a fingerprint or PIN check counts for a passphrase reset. */
        private const val CONFIRM_WINDOW_MS = 2 * 60 * 1000L

        @Volatile private var instance: BackupApiImpl? = null

        fun shared(context: Context): BackupApiImpl =
            instance ?: synchronized(this) {
                instance ?: BackupApiImpl(context.applicationContext).also { instance = it }
            }
    }
}
