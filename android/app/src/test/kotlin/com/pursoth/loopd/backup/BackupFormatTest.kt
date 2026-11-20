package com.pursoth.loopd.backup

import com.pursoth.loopd.security.FakeKeyWrapper
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.RandomAccessFile
import kotlin.random.Random

class BackupFormatTest {
    @get:Rule
    val temp = TemporaryFolder()

    // Small Argon2id settings so the tests run fast; the format stores them.
    private val fast = KdfSettings(memoryKib = 1024, iterations = 1, parallelism = 1)
    private val passphrase = "made up passphrase 42".toByteArray()
    private lateinit var keys: BackupKeys
    private lateinit var folderDir: File
    private lateinit var folder: DirectoryFolder

    @Before
    fun setUp() {
        keys = BackupKeys(FakeKeyWrapper(), File(temp.root, "keys/backup.keyset"), File(temp.root, "keys/backup.pass"), fast)
        folderDir = File(temp.root, "folder")
        folder = DirectoryFolder(folderDir)
    }

    private fun source(name: String, size: Int, seed: Int = 1): File =
        File(temp.root, name).apply { writeBytes(Random(seed).nextBytes(size)) }

    private fun write(entries: List<SourceEntry>, maxPart: Long = 64L * 1024 * 1024, run: String = "20261118-0900-a1b2"): WrittenBackup =
        BackupWriter(keys.streamingAead(), folder, maxPart).write(RunInfo(run, 1_763_456_400_000, "1.0.0+1", 7), entries, keys.passphraseWrap())

    @Test
    fun setUpStoresOnlyEncryptedKeysAndNoPassphrase() {
        assertFalse(keys.isSetUp())
        keys.setUp(passphrase)
        assertTrue(keys.isSetUp())
        for (file in File(temp.root, "keys").listFiles()!!) {
            assertFalse("passphrase found in ${file.name}", file.readBytes().containsSlice(passphrase))
        }
        assertFalse(File(temp.root, "keys/backup.keyset.tmp").exists())
    }

    @Test
    fun aShortPassphraseIsRefused() {
        try {
            keys.setUp("too short".toByteArray())
            fail("expected a refusal")
        } catch (e: BackupException) {
            assertFalse(keys.isSetUp())
        }
    }

    @Test
    fun writesPartsThenTheIndexAndReadsEverythingBack() {
        keys.setUp(passphrase)
        val db = source("loopd.db", 300_000)
        val written = write(listOf(SourceEntry("database", db, mapOf("key" to "ab".repeat(32)))))

        assertEquals(listOf("loopd-20261118-0900-a1b2-p0001.lpdp", "loopd-20261118-0900-a1b2.lpdb"), written.files)
        assertEquals(written.files.sumOf { File(folderDir, it).length() }, written.totalBytes)
        val manifest = BackupReader(folder).verify(written.indexName, keys.streamingAead())
        assertEquals("1.0.0+1", manifest.appVersion)
        assertEquals(7, manifest.schemaVersion)
        assertEquals("ab".repeat(32), manifest.entries.single().meta["key"])

        val out = ByteArrayOutputStream()
        BackupReader(folder).extract(manifest, manifest.entries.single(), keys.streamingAead(), out)
        assertArrayEquals(db.readBytes(), out.toByteArray())
        assertFalse("plain bytes in a part", File(folderDir, written.files[0]).readBytes().containsSlice(db.readBytes().copyOfRange(1000, 1064)))
    }

    @Test
    fun aLargeEntryIsSplitAcrossParts() {
        keys.setUp(passphrase)
        val big = source("big.bin", 700_000, seed = 2)
        val small = source("small.bin", 5_000, seed = 3)
        val written = write(listOf(SourceEntry("big", big, emptyMap()), SourceEntry("small", small, emptyMap())), maxPart = 256 * 1024)

        val manifest = BackupReader(folder).verify(written.indexName, keys.streamingAead())
        assertTrue("several parts", manifest.parts.size >= 3)
        assertTrue(manifest.entries[0].members.size >= 3)
        for ((entry, file) in manifest.entries.zip(listOf(big, small))) {
            val out = ByteArrayOutputStream()
            BackupReader(folder).extract(manifest, entry, keys.streamingAead(), out)
            assertArrayEquals(file.readBytes(), out.toByteArray())
        }
    }

    @Test
    fun anyPhoneOpensTheBackupWithThePassphraseAndOnlyWithIt() {
        keys.setUp(passphrase)
        val written = write(listOf(SourceEntry("database", source("loopd.db", 10_000), emptyMap())))
        val wrap = BackupReader(folder).header(written.indexName)
        assertEquals(fast, wrap.settings)

        // A new phone: no Keystore key, only the file and the passphrase.
        val opened = BackupKeys.open(wrap, passphrase)
        BackupReader(folder).verify(written.indexName, opened)

        try {
            BackupKeys.open(wrap, "not the passphrase at all".toByteArray())
            fail("a wrong passphrase must not open it")
        } catch (e: BackupException) {
            assertEquals(BackupFailure.WRONG_PASSPHRASE, e.failure)
        }
    }

    @Test
    fun aChangedByteInAPartOrTheIndexFailsTheCheck() {
        keys.setUp(passphrase)
        val written = write(listOf(SourceEntry("database", source("loopd.db", 50_000), emptyMap())))
        for (name in written.files) {
            val file = File(folderDir, name)
            val original = file.readBytes()
            RandomAccessFile(file, "rw").use { raf ->
                raf.seek(file.length() - 40)
                val b = raf.read()
                raf.seek(file.length() - 40)
                raf.write(b xor 0x01)
            }
            try {
                BackupReader(folder).verify(written.indexName, keys.streamingAead())
                fail("$name: a changed byte must fail the check")
            } catch (e: BackupException) {
                assertEquals(BackupFailure.VERIFY_FAILED, e.failure)
            }
            file.writeBytes(original)
        }
        BackupReader(folder).verify(written.indexName, keys.streamingAead())
    }

    @Test
    fun aPartFromAnotherRunIsRefused() {
        keys.setUp(passphrase)
        val first = write(listOf(SourceEntry("database", source("a.db", 20_000, 4), emptyMap())), run = "run-one")
        write(listOf(SourceEntry("database", source("b.db", 20_000, 5), emptyMap())), run = "run-two")
        // Swap run two's part in under run one's name.
        File(folderDir, "loopd-run-two-p0001.lpdp").copyTo(File(folderDir, "loopd-run-one-p0001.lpdp"), overwrite = true)
        try {
            BackupReader(folder).verify(first.indexName, keys.streamingAead())
            fail("a part from another run must be refused")
        } catch (e: BackupException) {
            assertEquals(BackupFailure.VERIFY_FAILED, e.failure)
        }
    }

    @Test
    fun aFailedRunLeavesNoFilesBehind() {
        keys.setUp(passphrase)
        val gone = File(temp.root, "missing.db") // does not exist: reading it fails mid-run
        try {
            write(listOf(SourceEntry("database", source("ok.db", 10_000), emptyMap()), SourceEntry("vault", gone, emptyMap())))
            fail("expected a failure")
        } catch (e: java.io.IOException) {
            assertEquals(emptyList<String>(), folder.names())
        }
    }

    @Test
    fun aFileThatIsNotABackupIsSaidSo() {
        File(folderDir.apply { mkdirs() }, "notes.lpdb").writeText("hello")
        try {
            BackupReader(folder).header("notes.lpdb")
            fail("expected not_a_backup")
        } catch (e: BackupException) {
            assertEquals(BackupFailure.NOT_A_BACKUP, e.failure)
        }
    }

    @Test
    fun tarRoundTripSkipsUnreadMembers() {
        val bytes = ByteArrayOutputStream()
        val tar = TarWriter(bytes)
        val a = Random(9).nextBytes(1_000)
        val b = Random(10).nextBytes(513)
        tar.add("a.000", a.size.toLong(), ByteArrayInputStream(a))
        tar.add("b.000", b.size.toLong(), ByteArrayInputStream(b))
        tar.finish()
        val reader = TarReader(ByteArrayInputStream(bytes.toByteArray()))
        assertEquals(TarReader.Member("a.000", 1_000), reader.next())
        assertEquals(TarReader.Member("b.000", 513), reader.next())
        val out = ByteArrayOutputStream()
        reader.copyTo(out)
        assertArrayEquals(b, out.toByteArray())
        assertEquals(null, reader.next())
    }

    private fun ByteArray.containsSlice(slice: ByteArray): Boolean =
        (0..size - slice.size).any { start -> slice.indices.all { this[start + it] == slice[it] } }
}
