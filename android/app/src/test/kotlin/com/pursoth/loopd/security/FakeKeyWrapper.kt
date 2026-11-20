package com.pursoth.loopd.security

import java.security.GeneralSecurityException
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/** A [KeyWrapper] for JVM tests: AES-GCM with an in-memory key, as the Keystore would do. */
class FakeKeyWrapper : KeyWrapper {
    private var key: SecretKey? = null
    var failEnsureKey = false

    fun forgetKey() {
        key = null
    }

    override fun hasKey(): Boolean = key != null

    override fun ensureKey() {
        if (failEnsureKey) throw GeneralSecurityException("keystore broken")
        if (key == null) key = KeyGenerator.getInstance("AES").apply { init(256) }.generateKey()
    }

    override fun wrap(plaintext: ByteArray, associatedData: ByteArray): ByteArray {
        val iv = ByteArray(12).also(SecureRandom()::nextBytes)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, requireKey(), GCMParameterSpec(128, iv))
        cipher.updateAAD(associatedData)
        return iv + cipher.doFinal(plaintext)
    }

    override fun unwrap(ciphertext: ByteArray, associatedData: ByteArray): ByteArray {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, requireKey(), GCMParameterSpec(128, ciphertext, 0, 12))
        cipher.updateAAD(associatedData)
        return cipher.doFinal(ciphertext, 12, ciphertext.size - 12)
    }

    private fun requireKey(): SecretKey = key ?: throw GeneralSecurityException("no key")
}
