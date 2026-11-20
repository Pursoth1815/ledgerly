package com.pursoth.loopd.security

import com.google.crypto.tink.integration.android.AndroidKeystore

/**
 * [KeyWrapper] backed by an AES-256-GCM key in the Android Keystore, through
 * Tink's `AndroidKeystore` helper (Tink 1.24.0).
 *
 * `AndroidKeysetManager` is deliberately not used: it falls back to storing
 * keysets unencrypted when the Keystore misbehaves (ADR 0009).
 *
 * The key is created with Tink's default AES-256-GCM spec, which requires
 * neither user authentication nor an unlocked device, so background work can
 * use it while the phone is locked. Phase 0B checks this on the owner's phone.
 *
 * The Tink helper is not thread-safe, and the database key and backup run on
 * different threads, so every call takes one process-wide lock: Keystore
 * calls never overlap (ADR 0009).
 */
class KeystoreKeyWrapper(private val alias: String) : KeyWrapper {
    override fun hasKey(): Boolean = synchronized(LOCK) { AndroidKeystore.hasKey(alias) }

    override fun ensureKey() = synchronized(LOCK) {
        if (!AndroidKeystore.hasKey(alias)) {
            AndroidKeystore.generateNewAes256GcmKey(alias)
        }
    }

    override fun wrap(plaintext: ByteArray, associatedData: ByteArray): ByteArray =
        synchronized(LOCK) { AndroidKeystore.getAead(alias).encrypt(plaintext, associatedData) }

    override fun unwrap(ciphertext: ByteArray, associatedData: ByteArray): ByteArray =
        synchronized(LOCK) { AndroidKeystore.getAead(alias).decrypt(ciphertext, associatedData) }

    private companion object {
        val LOCK = Any()
    }
}
