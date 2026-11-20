package com.pursoth.loopd.backup

import java.io.EOFException
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream

/**
 * The small part of the ustar format a backup part needs: regular files only,
 * names up to 100 bytes, sizes up to 8 GB. Each part file holds one archive.
 */
class TarWriter(private val out: OutputStream) {
    /** Writes a member of [size] bytes, copied from [source]. */
    fun add(name: String, size: Long, source: InputStream) {
        out.write(header(name, size))
        val buffer = ByteArray(COPY_BYTES)
        var left = size
        while (left > 0) {
            val read = source.read(buffer, 0, minOf(buffer.size.toLong(), left).toInt())
            if (read < 0) throw EOFException("$name ended $left bytes early")
            out.write(buffer, 0, read)
            left -= read
        }
        val pad = (BLOCK - (size % BLOCK)) % BLOCK
        if (pad > 0) out.write(ByteArray(pad.toInt()))
    }

    /** Ends the archive with two empty blocks. Does not close [out]. */
    fun finish() {
        out.write(ByteArray(BLOCK * 2))
    }

    private fun header(name: String, size: Long): ByteArray {
        val nameBytes = name.toByteArray(Charsets.UTF_8)
        require(nameBytes.size <= 100) { "Name too long: $name" }
        val h = ByteArray(BLOCK)
        nameBytes.copyInto(h, 0)
        octal(h, 100, 8, 420) // mode 0644
        octal(h, 108, 8, 0) // uid
        octal(h, 116, 8, 0) // gid
        octal(h, 124, 12, size)
        octal(h, 136, 12, 0) // mtime: none, so identical input gives identical bytes
        for (i in 148 until 156) h[i] = ' '.code.toByte() // checksum placeholder
        h[156] = '0'.code.toByte() // regular file
        "ustar".toByteArray().copyInto(h, 257)
        h[263] = '0'.code.toByte()
        h[264] = '0'.code.toByte()
        val sum = h.sumOf { it.toInt() and 0xFF }
        octal(h, 148, 7, sum.toLong())
        h[155] = ' '.code.toByte()
        return h
    }

    private fun octal(h: ByteArray, offset: Int, width: Int, value: Long) {
        val text = value.toString(8).padStart(width - 1, '0')
        require(text.length <= width - 1) { "Value too large for the tar header" }
        text.toByteArray().copyInto(h, offset)
        h[offset + width - 1] = 0
    }

    companion object {
        const val BLOCK = 512
        private const val COPY_BYTES = 64 * 1024

        /** The bytes a member of [size] takes in the archive, header included. */
        fun memberBytes(size: Long): Long = BLOCK + ((size + BLOCK - 1) / BLOCK) * BLOCK
    }
}

/** Reads the archives [TarWriter] writes, one member at a time. */
class TarReader(private val input: InputStream) {
    data class Member(val name: String, val size: Long)

    private var contentLeft = 0L
    private var padding = 0L

    /** The next member's header, or null at the end of the archive. Skips what is left of the current one. */
    fun next(): Member? {
        skipContent()
        val h = ByteArray(TarWriter.BLOCK)
        readFully(h)
        if (h.all { it.toInt() == 0 }) return null
        val stored = parseOctal(h, 148, 8)
        for (i in 148 until 156) h[i] = ' '.code.toByte()
        if (h.sumOf { it.toInt() and 0xFF }.toLong() != stored) throw IOException("Damaged tar header")
        val nameEnd = (0 until 100).firstOrNull { h[it].toInt() == 0 } ?: 100
        val member = Member(String(h, 0, nameEnd, Charsets.UTF_8), parseOctal(h, 124, 12))
        contentLeft = member.size
        padding = (TarWriter.BLOCK - (member.size % TarWriter.BLOCK)) % TarWriter.BLOCK
        return member
    }

    /** Copies the current member's content to [out]. */
    fun copyTo(out: OutputStream) {
        val buffer = ByteArray(64 * 1024)
        while (contentLeft > 0) {
            val read = input.read(buffer, 0, minOf(buffer.size.toLong(), contentLeft).toInt())
            if (read < 0) throw EOFException("Member ended early")
            out.write(buffer, 0, read)
            contentLeft -= read
        }
        skip(padding)
        padding = 0
    }

    /** Skips the current member's content. */
    fun skipContent() {
        skip(contentLeft + padding)
        contentLeft = 0
        padding = 0
    }

    private fun skip(count: Long) {
        var left = count
        val buffer = ByteArray(8 * 1024)
        while (left > 0) {
            val read = input.read(buffer, 0, minOf(buffer.size.toLong(), left).toInt())
            if (read < 0) throw EOFException("Archive ended early")
            left -= read
        }
    }

    private fun readFully(buffer: ByteArray) {
        var at = 0
        while (at < buffer.size) {
            val read = input.read(buffer, at, buffer.size - at)
            if (read < 0) throw EOFException("Archive ended early")
            at += read
        }
    }

    private fun parseOctal(h: ByteArray, offset: Int, width: Int): Long {
        val text = String(h, offset, width, Charsets.US_ASCII).trim { it == ' ' || it.code == 0 }
        return if (text.isEmpty()) 0 else text.toLong(8)
    }
}
