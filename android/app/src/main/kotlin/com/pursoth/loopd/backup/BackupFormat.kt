package com.pursoth.loopd.backup

import com.google.crypto.tink.StreamingAead
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.io.DataInputStream
import java.io.File
import java.io.FileInputStream
import java.io.FilterInputStream
import java.io.FilterOutputStream
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.security.GeneralSecurityException
import java.security.MessageDigest

/*
 * Backup format version 1 (ADR 0011):
 *
 *   loopd-<run>.lpdb         "LPDB", format version, the passphrase wrap (Argon2id
 *                            settings, salt, key id, wrapped backup key), then a
 *                            Tink stream (associated data: everything before it)
 *                            holding the manifest as JSON
 *   loopd-<run>-pNNNN.lpdp   Tink streams (associated data: run id and part
 *                            number), each holding a tar of whole entries; an
 *                            entry larger than a part is split into numbered
 *                            members
 *
 * The index is written last: a run without a readable index is not a backup.
 */

/** One part file, as the manifest records it. */
data class PartInfo(val name: String, val size: Long, val sha256: String)

/** Where one piece of an entry lives. */
data class MemberRef(val part: Int, val member: String, val size: Long)

/** One thing backed up, such as the database, with how to open it ([meta]). */
data class EntryInfo(val name: String, val size: Long, val members: List<MemberRef>, val meta: Map<String, String>)

data class Manifest(
    val runId: String,
    val createdAt: Long,
    val appVersion: String,
    val schemaVersion: Int,
    val parts: List<PartInfo>,
    val entries: List<EntryInfo>,
) {
    fun toJson(): String = JSONObject()
        .put("format", FORMAT_VERSION)
        .put("runId", runId)
        .put("createdAt", createdAt)
        .put("appVersion", appVersion)
        .put("schemaVersion", schemaVersion)
        .put("parts", JSONArray(parts.map { JSONObject().put("name", it.name).put("size", it.size).put("sha256", it.sha256) }))
        .put(
            "entries",
            JSONArray(
                entries.map { e ->
                    JSONObject()
                        .put("name", e.name)
                        .put("size", e.size)
                        .put("members", JSONArray(e.members.map { JSONObject().put("part", it.part).put("member", it.member).put("size", it.size) }))
                        .put("meta", JSONObject(e.meta))
                },
            ),
        )
        .toString()

    companion object {
        const val FORMAT_VERSION = 1

        fun fromJson(text: String): Manifest {
            val o = JSONObject(text)
            if (o.getInt("format") != FORMAT_VERSION) throw IOException("Unknown manifest format")
            val parts = o.getJSONArray("parts").let { a ->
                (0 until a.length()).map { a.getJSONObject(it).let { p -> PartInfo(p.getString("name"), p.getLong("size"), p.getString("sha256")) } }
            }
            val entries = o.getJSONArray("entries").let { a ->
                (0 until a.length()).map { i ->
                    val e = a.getJSONObject(i)
                    val members = e.getJSONArray("members").let { m ->
                        (0 until m.length()).map { m.getJSONObject(it).let { r -> MemberRef(r.getInt("part"), r.getString("member"), r.getLong("size")) } }
                    }
                    val metaObject = e.getJSONObject("meta")
                    val meta = metaObject.keys().asSequence().associateWith { metaObject.getString(it) }
                    EntryInfo(e.getString("name"), e.getLong("size"), members, meta)
                }
            }
            return Manifest(o.getString("runId"), o.getLong("createdAt"), o.getString("appVersion"), o.getInt("schemaVersion"), parts, entries)
        }
    }
}

object BackupNames {
    fun index(runId: String) = "loopd-$runId.lpdb"

    fun part(runId: String, number: Int) = "loopd-$runId-p%04d.lpdp".format(number)

    /** Associated data that ties a part to its run and place. */
    fun partAd(runId: String, number: Int): ByteArray = "loopd/backup/part/v1:$runId:$number".toByteArray(Charsets.UTF_8)

    private val MAGIC = "LPDB".toByteArray(Charsets.US_ASCII)

    fun header(wrap: PassphraseWrap): ByteArray = MAGIC + byteArrayOf(Manifest.FORMAT_VERSION.toByte()) + BackupKeys.encode(wrap)

    /** Reads the header off the start of an index stream: its bytes and the passphrase wrap. */
    fun readHeader(input: InputStream): Pair<ByteArray, PassphraseWrap> {
        val data = DataInputStream(input)
        try {
            val magic = ByteArray(4).also(data::readFully)
            if (!magic.contentEquals(MAGIC)) throw BackupException(BackupFailure.NOT_A_BACKUP, "Not a Loopd backup")
            if (data.readByte().toInt() != Manifest.FORMAT_VERSION) {
                throw BackupException(BackupFailure.NOT_A_BACKUP, "Made by a newer Loopd")
            }
            val wrapStart = ByteArrayOutputStream()
            wrapStart.write(data.readByte().toInt())
            val fixed = ByteArray(4 * 3 + 16 + 16).also(data::readFully)
            wrapStart.write(fixed)
            val size = data.readInt()
            if (size !in 1..64 * 1024) throw BackupException(BackupFailure.NOT_A_BACKUP, "Damaged header")
            java.io.DataOutputStream(wrapStart).writeInt(size)
            wrapStart.write(ByteArray(size).also(data::readFully))
            val wrap = BackupKeys.decode(wrapStart.toByteArray())
            return header(wrap) to wrap
        } catch (e: IOException) {
            throw BackupException(BackupFailure.NOT_A_BACKUP, "Not a Loopd backup", e)
        }
    }
}

/** A file to back up, under [name], with what is needed to open it. */
data class SourceEntry(val name: String, val file: File, val meta: Map<String, String>)

data class RunInfo(val runId: String, val createdAt: Long, val appVersion: String, val schemaVersion: Int)

data class WrittenBackup(val indexName: String, val files: List<String>, val totalBytes: Long)

/**
 * Writes one backup run into [folder]: the parts first, the index last. Parts
 * hold whole entries up to about [maxPartBytes]; a larger entry is split.
 */
class BackupWriter(
    private val aead: StreamingAead,
    private val folder: BackupFolder,
    private val maxPartBytes: Long = 64L * 1024 * 1024,
) {
    /** Writes the run; if anything fails, removes the files it made and rethrows. */
    fun write(run: RunInfo, entries: List<SourceEntry>, wrap: PassphraseWrap): WrittenBackup {
        created.clear()
        try {
            return writeAll(run, entries, wrap)
        } catch (e: Throwable) {
            for (name in created) runCatching { folder.delete(name) }
            throw e
        }
    }

    /** Every file this writer made, so a failed run leaves nothing behind. */
    private val created = mutableListOf<String>()

    private fun create(name: String): OutputStream = folder.create(name).also { created += name }

    private fun writeAll(run: RunInfo, entries: List<SourceEntry>, wrap: PassphraseWrap): WrittenBackup {
        val parts = mutableListOf<PartInfo>()
        val infos = mutableListOf<EntryInfo>()
        var open: OpenPart? = null

        fun closePart() {
            open?.let { parts += it.close() }
            open = null
        }

        fun part(): OpenPart = open ?: OpenPart(run.runId, parts.size + 1).also { open = it }

        for (entry in entries) {
            val total = entry.file.length()
            val members = mutableListOf<MemberRef>()
            FileInputStream(entry.file).use { source ->
                var left = total
                var piece = 0
                do {
                    var current = part()
                    var room = maxPartBytes - current.plainBytes - TarWriter.BLOCK
                    if (room < MIN_PIECE && current.plainBytes > 0) {
                        closePart()
                        current = part()
                        room = maxPartBytes - TarWriter.BLOCK
                    }
                    val size = minOf(left, room)
                    val member = "%s.%03d".format(entry.name, piece++)
                    current.add(member, size, source)
                    members += MemberRef(current.number, member, size)
                    left -= size
                } while (left > 0)
            }
            infos += EntryInfo(entry.name, total, members, entry.meta)
        }
        closePart()

        val manifest = Manifest(run.runId, run.createdAt, run.appVersion, run.schemaVersion, parts, infos)
        val header = BackupNames.header(wrap)
        val indexName = BackupNames.index(run.runId)
        val counter = create(indexName).let(::CountingDigestOutputStream)
        counter.write(header)
        try {
            aead.newEncryptingStream(counter, header).use { it.write(manifest.toJson().toByteArray(Charsets.UTF_8)) }
        } catch (e: GeneralSecurityException) {
            throw BackupException(BackupFailure.WRITE_FAILED, "Encryption failed", e)
        }
        return WrittenBackup(indexName, parts.map { it.name } + indexName, parts.sumOf { it.size } + counter.count)
    }

    private inner class OpenPart(runId: String, val number: Int) {
        val name = BackupNames.part(runId, number)
        private val counter = CountingDigestOutputStream(create(name))
        private val encrypting = try {
            aead.newEncryptingStream(counter, BackupNames.partAd(runId, number))
        } catch (e: GeneralSecurityException) {
            throw BackupException(BackupFailure.WRITE_FAILED, "Encryption failed", e)
        }
        private val tar = TarWriter(encrypting)
        var plainBytes = 0L
            private set

        fun add(member: String, size: Long, source: InputStream) {
            tar.add(member, size, source)
            plainBytes += TarWriter.memberBytes(size)
        }

        fun close(): PartInfo {
            tar.finish()
            encrypting.close()
            return PartInfo(name, counter.count, counter.hex())
        }
    }

    private companion object {
        /** Below this, a new part is started instead of a sliver. */
        const val MIN_PIECE = 64L * 1024
    }
}

/**
 * Reads backups back: their header, their manifest, a full check of every part
 * (its SHA-256, its size, and every stream authenticated to the end), and the
 * entries themselves.
 */
class BackupReader(private val folder: BackupFolder) {
    fun header(indexName: String): PassphraseWrap = folder.open(indexName).use { BackupNames.readHeader(it).second }

    fun manifest(indexName: String, aead: StreamingAead): Manifest =
        folder.open(indexName).use { input ->
            val (header, _) = BackupNames.readHeader(input)
            try {
                val text = aead.newDecryptingStream(input, header).use { it.readBytes() }.toString(Charsets.UTF_8)
                Manifest.fromJson(text)
            } catch (e: GeneralSecurityException) {
                throw BackupException(BackupFailure.VERIFY_FAILED, "The index does not open with this key", e)
            } catch (e: IOException) {
                throw BackupException(BackupFailure.VERIFY_FAILED, "The index is damaged", e)
            } catch (e: org.json.JSONException) {
                throw BackupException(BackupFailure.VERIFY_FAILED, "The manifest is damaged", e)
            }
        }

    /** Reads every part back and checks it against the manifest. Returns the manifest. */
    fun verify(indexName: String, aead: StreamingAead): Manifest {
        val manifest = manifest(indexName, aead)
        val expected = manifest.entries.flatMap { it.members }.groupBy { it.part }
        manifest.parts.forEachIndexed { i, part ->
            val number = i + 1
            val counter = CountingDigestInputStream(folder.open(part.name))
            try {
                counter.use {
                    aead.newDecryptingStream(counter, BackupNames.partAd(manifest.runId, number)).use { plain ->
                        val tar = TarReader(plain)
                        val found = mutableListOf<TarReader.Member>()
                        while (true) found += tar.next() ?: break
                        val wanted = expected[number].orEmpty().map { TarReader.Member(it.member, it.size) }
                        if (found != wanted) throw BackupException(BackupFailure.VERIFY_FAILED, "${part.name} holds the wrong members")
                        // Read to the very end, so the last segment is authenticated too.
                        while (plain.read(ByteArray(8 * 1024)) >= 0) Unit
                    }
                }
            } catch (e: IOException) {
                throw BackupException(BackupFailure.VERIFY_FAILED, "${part.name} is damaged", e)
            } catch (e: GeneralSecurityException) {
                throw BackupException(BackupFailure.VERIFY_FAILED, "${part.name} does not open", e)
            }
            if (counter.count != part.size || counter.hex() != part.sha256) {
                throw BackupException(BackupFailure.VERIFY_FAILED, "${part.name} does not match its checksum")
            }
        }
        return manifest
    }

    /** Copies [entry] out of the backup into [out], piece by piece. */
    fun extract(manifest: Manifest, entry: EntryInfo, aead: StreamingAead, out: OutputStream) {
        for (ref in entry.members) {
            val part = manifest.parts[ref.part - 1]
            folder.open(part.name).use { raw ->
                aead.newDecryptingStream(raw, BackupNames.partAd(manifest.runId, ref.part)).use { plain ->
                    val tar = TarReader(plain)
                    while (true) {
                        val member = tar.next() ?: throw BackupException(BackupFailure.VERIFY_FAILED, "${ref.member} is missing")
                        if (member.name == ref.member) {
                            tar.copyTo(out)
                            break
                        }
                    }
                }
            }
        }
    }
}

/** Counts and hashes (SHA-256) what passes through. */
class CountingDigestOutputStream(out: OutputStream) : FilterOutputStream(out) {
    private val digest = MessageDigest.getInstance("SHA-256")
    var count = 0L
        private set

    override fun write(b: Int) {
        out.write(b)
        digest.update(b.toByte())
        count++
    }

    override fun write(b: ByteArray, off: Int, len: Int) {
        out.write(b, off, len)
        digest.update(b, off, len)
        count += len
    }

    fun hex(): String = digest.digest().joinToString("") { "%02x".format(it) }
}

class CountingDigestInputStream(input: InputStream) : FilterInputStream(input) {
    private val digest = MessageDigest.getInstance("SHA-256")
    var count = 0L
        private set

    override fun read(): Int = super.read().also {
        if (it >= 0) {
            digest.update(it.toByte())
            count++
        }
    }

    override fun read(b: ByteArray, off: Int, len: Int): Int = super.read(b, off, len).also {
        if (it > 0) {
            digest.update(b, off, it)
            count += it
        }
    }

    fun hex(): String = digest.digest().joinToString("") { "%02x".format(it) }
}
