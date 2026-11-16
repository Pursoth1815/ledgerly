package com.pursoth.loopd.security

import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.security.GeneralSecurityException
import java.security.ProviderException
import java.security.SecureRandom

/** Why a key could not be returned. The codes are part of the Pigeon contract. */
enum class KeyFailure(val code: String) {
    /** No key has been stored, or its Keystore key is gone. Nothing is regenerated. */
    KEY_MISSING("key_missing"),

    /** The stored key exists but cannot be decrypted or has the wrong shape. */
    KEY_CORRUPT("key_corrupt"),

    /** The Keystore could not create or use its key, or the key file could not be written. */
    KEYSTORE_UNAVAILABLE("keystore_unavailable"),
}

class KeyAccessException(val failure: KeyFailure, message: String, cause: Throwable? = null) :
    Exception(message, cause)

/**
 * Creates, stores and returns the 256-bit SQLCipher key (ADR 0009).
 *
 * The key is random, wrapped by [wrapper] (the Android Keystore in production),
 * and written to [keyFile], which lives in app-private storage that Android
 * never backs up. The file holds a format byte followed by the Keystore
 * ciphertext; the raw key is never written anywhere.
 *
 * Failures are never "fixed" by creating a new key: a new key would make the
 * existing database unreadable. They are reported, and the app shows a
 * recovery screen instead.
 */
class DatabaseKeyStore(
    private val wrapper: KeyWrapper,
    private val keyFile: File,
    private val random: SecureRandom = SecureRandom(),
) {
    @Synchronized
    @Throws(KeyAccessException::class)
    fun databaseKey(createIfMissing: Boolean): ByteArray {
        if (keyFile.exists()) return read()
        if (!createIfMissing) {
            throw KeyAccessException(KeyFailure.KEY_MISSING, "No database key has been stored")
        }
        return create()
    }

    private fun read(): ByteArray {
        val keystoreKeyExists = keystoreCall { wrapper.hasKey() }
        if (!keystoreKeyExists) {
            throw KeyAccessException(
                KeyFailure.KEY_MISSING,
                "A wrapped database key exists but its Keystore key is gone",
            )
        }
        val blob = try {
            keyFile.readBytes()
        } catch (e: IOException) {
            throw KeyAccessException(KeyFailure.KEY_CORRUPT, "The key file cannot be read", e)
        }
        if (blob.isEmpty() || blob[0] != FORMAT_V1) {
            throw KeyAccessException(KeyFailure.KEY_CORRUPT, "Unknown key file format")
        }
        val key = try {
            wrapper.unwrap(blob.copyOfRange(1, blob.size), ASSOCIATED_DATA)
        } catch (e: GeneralSecurityException) {
            throw KeyAccessException(KeyFailure.KEY_CORRUPT, "The database key cannot be decrypted", e)
        } catch (e: ProviderException) {
            throw KeyAccessException(KeyFailure.KEYSTORE_UNAVAILABLE, "The Keystore failed", e)
        }
        if (key.size != KEY_BYTES) {
            throw KeyAccessException(KeyFailure.KEY_CORRUPT, "The database key has the wrong length")
        }
        return key
    }

    private fun create(): ByteArray {
        keystoreCall { wrapper.ensureKey() }
        val key = ByteArray(KEY_BYTES).also(random::nextBytes)
        val wrapped = keystoreCall { wrapper.wrap(key, ASSOCIATED_DATA) }
        // Prove the round trip before anything is stored.
        val check = keystoreCall { wrapper.unwrap(wrapped, ASSOCIATED_DATA) }
        if (!check.contentEquals(key)) {
            throw KeyAccessException(KeyFailure.KEYSTORE_UNAVAILABLE, "Keystore round trip failed")
        }
        writeAtomically(byteArrayOf(FORMAT_V1) + wrapped)
        return key
    }

    private fun writeAtomically(bytes: ByteArray) {
        try {
            val dir = keyFile.parentFile ?: throw IOException("The key file has no folder")
            if (!dir.exists() && !dir.mkdirs()) throw IOException("Cannot create $dir")
            val temp = File(dir, keyFile.name + ".tmp")
            FileOutputStream(temp).use { out ->
                out.write(bytes)
                out.fd.sync()
            }
            if (!temp.renameTo(keyFile)) throw IOException("Cannot move the key file into place")
        } catch (e: IOException) {
            throw KeyAccessException(KeyFailure.KEYSTORE_UNAVAILABLE, "The key file cannot be written", e)
        }
    }

    private inline fun <T> keystoreCall(block: () -> T): T =
        try {
            block()
        } catch (e: GeneralSecurityException) {
            throw KeyAccessException(KeyFailure.KEYSTORE_UNAVAILABLE, "The Keystore failed", e)
        } catch (e: ProviderException) {
            throw KeyAccessException(KeyFailure.KEYSTORE_UNAVAILABLE, "The Keystore failed", e)
        }

    companion object {
        const val KEY_BYTES = 32
        const val FORMAT_V1: Byte = 1
        val ASSOCIATED_DATA: ByteArray = "loopd/database-key/v1".toByteArray(Charsets.UTF_8)
    }
}
