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
}
