package com.pursoth.loopd.bridge

import android.content.Context
import android.util.Log
import com.pursoth.loopd.security.DatabaseKeyStore
import com.pursoth.loopd.security.KeyAccessException
import com.pursoth.loopd.security.KeyFailure
import com.pursoth.loopd.security.KeystoreKeyWrapper
import java.io.File

/**
 * Pigeon host implementation of [KeyStoreApi]. Runs on Pigeon's serial background queue.
 *
 * One instance serves every engine in the process (the app's and the
 * headless one), so Keystore calls never overlap: [DatabaseKeyStore] is
 * synchronised. Use [shared].
 *
 * Logs only what happened (created, unwrapped, failure code), never key bytes.
 */
class KeyStoreApiImpl private constructor(context: Context) : KeyStoreApi {
    private val keyFile = File(context.noBackupFilesDir, "keys/database.key")
    private val databaseKeys = DatabaseKeyStore(
        wrapper = KeystoreKeyWrapper(MASTER_KEY_ALIAS),
        keyFile = keyFile,
    )

    override fun databaseKey(createIfMissing: Boolean): ByteArray =
        try {
            val existed = keyFile.exists()
            databaseKeys.databaseKey(createIfMissing).also {
                Log.i(TAG, if (existed) "key_unwrapped by=android_keystore" else "key_created wrapped_by=android_keystore")
            }
        } catch (e: KeyAccessException) {
            Log.w(TAG, "key_failed code=${e.failure.code}")
            throw FlutterError(e.failure.code, e.message)
        } catch (e: RuntimeException) {
            Log.w(TAG, "key_failed code=${KeyFailure.KEYSTORE_UNAVAILABLE.code} type=${e.javaClass.simpleName}")
            throw FlutterError(KeyFailure.KEYSTORE_UNAVAILABLE.code, e.javaClass.simpleName)
        }

    companion object {
        private const val TAG = "loopd.keys"
        private const val MASTER_KEY_ALIAS = "loopd_master_v1"

        @Volatile private var instance: KeyStoreApiImpl? = null

        fun shared(context: Context): KeyStoreApiImpl =
            instance ?: synchronized(this) {
                instance ?: KeyStoreApiImpl(context.applicationContext).also { instance = it }
            }
    }
}
