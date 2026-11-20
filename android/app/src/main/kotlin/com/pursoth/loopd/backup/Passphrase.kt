package com.pursoth.loopd.backup

import com.google.crypto.tink.Aead
import org.bouncycastle.crypto.generators.Argon2BytesGenerator
import org.bouncycastle.crypto.params.Argon2Parameters
import java.security.GeneralSecurityException
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

/**
 * Argon2id settings for the backup passphrase (ADR 0009). They travel in each
 * backup's header, so they can be raised later without breaking older ones.
 */
data class KdfSettings(val memoryKib: Int, val iterations: Int, val parallelism: Int) {
    companion object {
        /** Chosen from the Phase 0B tuning on the owner's phone: about 1.1 s. */
        val DEFAULT = KdfSettings(memoryKib = 128 * 1024, iterations = 4, parallelism = 1)
    }
}

object Passphrase {
    /** The shortest passphrase allowed (owner's decision, 17 Nov 2026). */
    const val MIN_LENGTH = 12

    /** A 32-byte key from [passphrase] and [salt] with Argon2id (Bouncy Castle). */
    fun derive(passphrase: ByteArray, salt: ByteArray, settings: KdfSettings): ByteArray {
        val parameters = Argon2Parameters.Builder(Argon2Parameters.ARGON2_id)
            .withVersion(Argon2Parameters.ARGON2_VERSION_13)
            .withIterations(settings.iterations)
            .withMemoryAsKB(settings.memoryKib)
            .withParallelism(settings.parallelism)
            .withSalt(salt)
            .build()
        val generator = Argon2BytesGenerator()
        generator.init(parameters)
        val out = ByteArray(32)
        generator.generateBytes(passphrase, out)
        return out
    }
}

/**
 * AES-256-GCM with the key derived from the passphrase, as a Tink [Aead], so
 * the backup keyset can be stored only in encrypted form
 * (`TinkProtoKeysetFormat.serializeEncryptedKeyset`). Plain Java crypto, so no
 * raw-key access to Tink is needed. The output is a 12-byte nonce, then the
 * ciphertext and its tag.
 */
class PassphraseAead(key: ByteArray, private val random: SecureRandom = SecureRandom()) : Aead {
    private val secret = SecretKeySpec(key.copyOf(), "AES")

    override fun encrypt(plaintext: ByteArray, associatedData: ByteArray?): ByteArray {
        val nonce = ByteArray(NONCE_BYTES).also(random::nextBytes)
        val cipher = Cipher.getInstance(TRANSFORM)
        cipher.init(Cipher.ENCRYPT_MODE, secret, GCMParameterSpec(TAG_BITS, nonce))
        associatedData?.let(cipher::updateAAD)
        return nonce + cipher.doFinal(plaintext)
    }

    override fun decrypt(ciphertext: ByteArray, associatedData: ByteArray?): ByteArray {
        if (ciphertext.size < NONCE_BYTES + TAG_BITS / 8) throw GeneralSecurityException("Too short")
        val cipher = Cipher.getInstance(TRANSFORM)
        cipher.init(Cipher.DECRYPT_MODE, secret, GCMParameterSpec(TAG_BITS, ciphertext, 0, NONCE_BYTES))
        associatedData?.let(cipher::updateAAD)
        return cipher.doFinal(ciphertext, NONCE_BYTES, ciphertext.size - NONCE_BYTES)
    }

    private companion object {
        const val TRANSFORM = "AES/GCM/NoPadding"
        const val NONCE_BYTES = 12
        const val TAG_BITS = 128
    }
}
