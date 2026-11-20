package com.pursoth.loopd.bridge

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import android.util.Log
import com.pursoth.loopd.backup.BackupException
import com.pursoth.loopd.backup.BackupFailure
import com.pursoth.loopd.backup.BackupKeys
import com.pursoth.loopd.backup.BackupReader
import com.pursoth.loopd.backup.BackupWriter
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

        @Volatile private var instance: BackupApiImpl? = null

        fun shared(context: Context): BackupApiImpl =
            instance ?: synchronized(this) {
                instance ?: BackupApiImpl(context.applicationContext).also { instance = it }
            }
    }
}
