package com.pursoth.loopd.backup

import com.google.crypto.tink.Aead
import com.google.crypto.tink.KeysetHandle
import com.google.crypto.tink.StreamingAead
import com.google.crypto.tink.TinkProtoKeysetFormat
import com.google.crypto.tink.streamingaead.AesGcmHkdfStreamingParameters
import com.google.crypto.tink.streamingaead.StreamingAeadConfig
import com.pursoth.loopd.security.KeyWrapper
import java.io.ByteArrayOutputStream
import java.io.DataInputStream
import java.io.DataOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.security.GeneralSecurityException
import java.security.SecureRandom

/** Why backup keys could not be used. The codes are part of the Pigeon contract. */
enum class BackupFailure(val code: String) {
    NOT_SET_UP("not_set_up"),
    WRONG_PASSPHRASE("wrong_passphrase"),
    KEYSTORE_UNAVAILABLE("keystore_unavailable"),
    FOLDER_LOST("folder_lost"),
    OUT_OF_SPACE("out_of_space"),
    WRITE_FAILED("write_failed"),
    VERIFY_FAILED("verify_failed"),
    NOT_A_BACKUP("not_a_backup"),
}

class BackupException(val failure: BackupFailure, message: String, cause: Throwable? = null) :
    Exception(message, cause)

/**
 * The backup key with the passphrase settings that wrap it, as every backup
 * file's header carries them (ADR 0011).
 */
class PassphraseWrap(
    val settings: KdfSettings,
    val salt: ByteArray,
    val keyId: ByteArray,
    val wrappedKeyset: ByteArray,
)

/**
 * The backup key (ADR 0009, 0011): a Tink streaming keyset (AES-256-GCM-HKDF,
 * 256 KiB segments) made once at setup.
 *
 * It is stored only in encrypted form, twice, in app-private storage that
 * Android never backs up:
 * - [keysetFile]: wrapped by the Keystore, so a backup can run without the
 *   passphrase;
 * - [passphraseFile]: wrapped by a key derived from the passphrase with
 *   Argon2id, with its salt and settings; this copy goes into every backup, so
 *   a backup can be opened on any phone with the passphrase.
 *
 * The passphrase itself is never stored.
 */
class BackupKeys(
    private val wrapper: KeyWrapper,
    private val keysetFile: File,
    private val passphraseFile: File,
    private val settings: KdfSettings = KdfSettings.DEFAULT,
    private val random: SecureRandom = SecureRandom(),
) {
    @Synchronized
    fun isSetUp(): Boolean = keysetFile.exists() && passphraseFile.exists() && keystore { wrapper.hasKey() }

    /** Makes a new backup key, wrapped by the Keystore and by [passphrase]. Replaces any earlier one. */
    @Synchronized
    fun setUp(passphrase: ByteArray) {
        if (passphrase.size < Passphrase.MIN_LENGTH) {
            throw BackupException(BackupFailure.WRITE_FAILED, "The passphrase is too short")
        }
        keystore { wrapper.ensureKey() }
        val handle = KeysetHandle.generateNew(PARAMETERS)
        val keyId = ByteArray(16).also(random::nextBytes)
        val wrap = wrapWithPassphrase(handle, passphrase, keyId)
        val local = keystore { TinkProtoKeysetFormat.serializeEncryptedKeyset(handle, keystoreAead(), LOCAL_AD) }
        // Prove both copies open before anything is stored.
        keystore { TinkProtoKeysetFormat.parseEncryptedKeyset(local, keystoreAead(), LOCAL_AD) }
        open(wrap, passphrase)
        writeAtomically(keysetFile, byteArrayOf(FORMAT_V1) + keyId + local)
        writeAtomically(passphraseFile, encode(wrap))
    }

    /** Whether [passphrase] opens the backup key (about a second: Argon2id). */
    @Synchronized
    fun checkPassphrase(passphrase: ByteArray): Boolean =
        try {
            open(passphraseWrap(), passphrase)
            true
        } catch (e: BackupException) {
            if (e.failure != BackupFailure.WRONG_PASSPHRASE) throw e
            false
        }

    /**
     * A forgotten passphrase (owner's decision, 17 Nov 2026): the same backup
     * key, wrapped again by [passphrase], so new backups use it. Older backup
     * files keep the old wrap and still need the old passphrase. The caller
     * checks the phone's owner first.
     */
    @Synchronized
    fun rewrap(passphrase: ByteArray) {
        if (passphrase.size < Passphrase.MIN_LENGTH) {
            throw BackupException(BackupFailure.WRITE_FAILED, "The passphrase is too short")
        }
        if (!isSetUp()) throw BackupException(BackupFailure.NOT_SET_UP, "Backup is not set up")
        val blob = keysetFile.readBytes()
        val keyId = blob.copyOfRange(1, 1 + 16)
        val handle = keystore {
            TinkProtoKeysetFormat.parseEncryptedKeyset(blob.copyOfRange(1 + 16, blob.size), keystoreAead(), LOCAL_AD)
        }
        val wrap = wrapWithPassphrase(handle, passphrase, keyId)
        open(wrap, passphrase)
        writeAtomically(passphraseFile, encode(wrap))
    }

    /** The backup key, unwrapped by the Keystore, for writing and checking backups. */
    @Synchronized
    fun streamingAead(): StreamingAead {
        if (!isSetUp()) throw BackupException(BackupFailure.NOT_SET_UP, "Backup is not set up")
        val blob = keysetFile.readBytes()
        if (blob.isEmpty() || blob[0] != FORMAT_V1) {
            throw BackupException(BackupFailure.KEYSTORE_UNAVAILABLE, "Unknown backup key format")
        }
        val handle = keystore {
            TinkProtoKeysetFormat.parseEncryptedKeyset(blob.copyOfRange(1 + 16, blob.size), keystoreAead(), LOCAL_AD)
        }
        return primitive(handle)
    }

    /** What goes into each backup's header. */
    @Synchronized
    fun passphraseWrap(): PassphraseWrap {
        if (!isSetUp()) throw BackupException(BackupFailure.NOT_SET_UP, "Backup is not set up")
        return decode(passphraseFile.readBytes())
    }

    private fun wrapWithPassphrase(handle: KeysetHandle, passphrase: ByteArray, keyId: ByteArray): PassphraseWrap {
        val salt = ByteArray(16).also(random::nextBytes)
        val key = Passphrase.derive(passphrase, salt, settings)
        try {
            val wrapped = TinkProtoKeysetFormat.serializeEncryptedKeyset(handle, PassphraseAead(key, random), passphraseAd(keyId))
            return PassphraseWrap(settings, salt, keyId, wrapped)
        } finally {
            key.fill(0)
        }
    }

    private fun keystoreAead(): Aead = object : Aead {
        override fun encrypt(plaintext: ByteArray, associatedData: ByteArray?): ByteArray =
            wrapper.wrap(plaintext, associatedData ?: ByteArray(0))

        override fun decrypt(ciphertext: ByteArray, associatedData: ByteArray?): ByteArray =
            wrapper.unwrap(ciphertext, associatedData ?: ByteArray(0))
    }

    private fun writeAtomically(file: File, bytes: ByteArray) {
        try {
            val dir = file.parentFile ?: throw IOException("No folder")
            if (!dir.exists() && !dir.mkdirs()) throw IOException("Cannot create $dir")
            val temp = File(dir, file.name + ".tmp")
            FileOutputStream(temp).use { out ->
                out.write(bytes)
                out.fd.sync()
            }
            if (!temp.renameTo(file)) throw IOException("Cannot move ${file.name} into place")
        } catch (e: IOException) {
            throw BackupException(BackupFailure.KEYSTORE_UNAVAILABLE, "The backup key cannot be stored", e)
        }
    }

    private inline fun <T> keystore(block: () -> T): T =
        try {
            block()
        } catch (e: GeneralSecurityException) {
            throw BackupException(BackupFailure.KEYSTORE_UNAVAILABLE, "The Keystore failed", e)
        } catch (e: java.security.ProviderException) {
            throw BackupException(BackupFailure.KEYSTORE_UNAVAILABLE, "The Keystore failed", e)
        }

    companion object {
        const val FORMAT_V1: Byte = 1
        private val LOCAL_AD = "loopd/backup-key/local/v1".toByteArray(Charsets.UTF_8)

        /** AES-256-GCM-HKDF with 256 KiB segments (ADR 0009, chosen from Phase 0B). */
        val PARAMETERS: AesGcmHkdfStreamingParameters by lazy {
            StreamingAeadConfig.register()
            AesGcmHkdfStreamingParameters.builder()
                .setKeySizeBytes(32)
                .setDerivedAesGcmKeySizeBytes(32)
                .setHkdfHashType(AesGcmHkdfStreamingParameters.HashType.SHA256)
                .setCiphertextSegmentSizeBytes(256 * 1024)
                .build()
        }

        fun passphraseAd(keyId: ByteArray): ByteArray = "loopd/backup-key/passphrase/v1:".toByteArray(Charsets.UTF_8) + keyId

        /** Opens a backup's key with its [wrap] and the [passphrase]; fails with wrong_passphrase. */
        fun open(wrap: PassphraseWrap, passphrase: ByteArray): StreamingAead {
            val key = Passphrase.derive(passphrase, wrap.salt, wrap.settings)
            try {
                val handle = TinkProtoKeysetFormat.parseEncryptedKeyset(wrap.wrappedKeyset, PassphraseAead(key), passphraseAd(wrap.keyId))
                return primitive(handle)
            } catch (e: GeneralSecurityException) {
                throw BackupException(BackupFailure.WRONG_PASSPHRASE, "The passphrase does not open this backup", e)
            } finally {
                key.fill(0)
            }
        }

        private fun primitive(handle: KeysetHandle): StreamingAead {
            PARAMETERS // registers the streaming key type
            return handle.getPrimitive(StreamingAead::class.java)
        }

        fun encode(wrap: PassphraseWrap): ByteArray {
            val bytes = ByteArrayOutputStream()
            DataOutputStream(bytes).use { out ->
                out.writeByte(FORMAT_V1.toInt())
                out.writeInt(wrap.settings.memoryKib)
                out.writeInt(wrap.settings.iterations)
                out.writeInt(wrap.settings.parallelism)
                out.write(wrap.salt)
                out.write(wrap.keyId)
                out.writeInt(wrap.wrappedKeyset.size)
                out.write(wrap.wrappedKeyset)
            }
            return bytes.toByteArray()
        }

        fun decode(bytes: ByteArray): PassphraseWrap {
            try {
                DataInputStream(bytes.inputStream()).use { input ->
                    if (input.readByte() != FORMAT_V1) throw IOException("Unknown passphrase format")
                    val settings = KdfSettings(input.readInt(), input.readInt(), input.readInt())
                    val salt = ByteArray(16).also(input::readFully)
                    val keyId = ByteArray(16).also(input::readFully)
                    val size = input.readInt()
                    if (size !in 1..64 * 1024) throw IOException("Bad key size")
                    val wrapped = ByteArray(size).also(input::readFully)
                    return PassphraseWrap(settings, salt, keyId, wrapped)
                }
            } catch (e: IOException) {
                throw BackupException(BackupFailure.NOT_A_BACKUP, "The key header is damaged", e)
            }
        }
    }
}
