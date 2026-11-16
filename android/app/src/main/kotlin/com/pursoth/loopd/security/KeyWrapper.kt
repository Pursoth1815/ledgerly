package com.pursoth.loopd.security

import java.security.GeneralSecurityException

/**
 * Encrypts small secrets with a key that never leaves the Android Keystore.
 *
 * It is an interface only so that [DatabaseKeyStore] can be tested on the JVM,
 * where no Keystore exists. The production implementation is
 * [KeystoreKeyWrapper]. There is deliberately no way to store anything
 * unencrypted (ADR 0009).
 */
interface KeyWrapper {
    /** True when the Keystore key behind this wrapper exists. */
    @Throws(GeneralSecurityException::class)
    fun hasKey(): Boolean

    /** Creates the Keystore key if it does not exist yet. */
    @Throws(GeneralSecurityException::class)
    fun ensureKey()

    @Throws(GeneralSecurityException::class)
    fun wrap(plaintext: ByteArray, associatedData: ByteArray): ByteArray

    @Throws(GeneralSecurityException::class)
    fun unwrap(ciphertext: ByteArray, associatedData: ByteArray): ByteArray
}
