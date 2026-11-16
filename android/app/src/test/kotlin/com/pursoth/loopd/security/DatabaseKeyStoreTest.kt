package com.pursoth.loopd.security

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File
import java.security.GeneralSecurityException
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class DatabaseKeyStoreTest {
    @get:Rule
    val temp = TemporaryFolder()

    private lateinit var wrapper: FakeKeyWrapper
    private lateinit var keyFile: File

    @Before
    fun setUp() {
        wrapper = FakeKeyWrapper()
        keyFile = File(temp.root, "keys/database.key")
    }

    private fun store() = DatabaseKeyStore(wrapper, keyFile)

    @Test
    fun createsA32ByteKeyAndReturnsTheSameKeyLater() {
        val first = store().databaseKey(createIfMissing = true)
        val again = DatabaseKeyStore(wrapper, keyFile).databaseKey(createIfMissing = false)

        assertEquals(32, first.size)
        assertArrayEquals(first, again)
    }

    @Test
    fun neverWritesTheRawKey() {
        val key = store().databaseKey(createIfMissing = true)
        val stored = keyFile.readBytes()

        assertEquals(DatabaseKeyStore.FORMAT_V1, stored[0])
        assertFalse("raw key bytes found in the key file", stored.containsSlice(key))
        assertFalse(File(keyFile.parentFile, "database.key.tmp").exists())
    }

    @Test
    fun missingKeyIsReportedWhenCreationIsNotAllowed() {
        expectFailure(KeyFailure.KEY_MISSING) { store().databaseKey(createIfMissing = false) }
        assertFalse(keyFile.exists())
    }

    @Test
    fun lostKeystoreKeyIsReportedAndNothingIsRegenerated() {
        store().databaseKey(createIfMissing = true)
        val before = keyFile.readBytes()
        wrapper.forgetKey()

        expectFailure(KeyFailure.KEY_MISSING) { store().databaseKey(createIfMissing = true) }
        assertArrayEquals(before, keyFile.readBytes())
    }

    @Test
    fun tamperedKeyFileIsReportedAsCorrupt() {
        store().databaseKey(createIfMissing = true)
        val bytes = keyFile.readBytes()
        bytes[bytes.size - 1] = (bytes[bytes.size - 1].toInt() xor 0x01).toByte()
        keyFile.writeBytes(bytes)

        expectFailure(KeyFailure.KEY_CORRUPT) { store().databaseKey(createIfMissing = false) }
    }

    @Test
    fun unknownFormatIsReportedAsCorrupt() {
        store().databaseKey(createIfMissing = true)
        val bytes = keyFile.readBytes()
        bytes[0] = 9
        keyFile.writeBytes(bytes)

        expectFailure(KeyFailure.KEY_CORRUPT) { store().databaseKey(createIfMissing = false) }
    }

    @Test
    fun keystoreFailureDuringCreationWritesNothing() {
        wrapper.failEnsureKey = true

        expectFailure(KeyFailure.KEYSTORE_UNAVAILABLE) { store().databaseKey(createIfMissing = true) }
        assertFalse(keyFile.exists())
    }

    private fun expectFailure(expected: KeyFailure, block: () -> Unit) {
        try {
            block()
            fail("expected $expected")
        } catch (e: KeyAccessException) {
            assertEquals(expected, e.failure)
        }
    }

    private fun ByteArray.containsSlice(slice: ByteArray): Boolean =
        (0..size - slice.size).any { start -> slice.indices.all { this[start + it] == slice[it] } }

    /** AES-256-GCM with an in-memory key: stands in for the Android Keystore on the JVM. */
    private class FakeKeyWrapper : KeyWrapper {
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
}
