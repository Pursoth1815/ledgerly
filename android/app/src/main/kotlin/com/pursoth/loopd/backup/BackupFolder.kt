package com.pursoth.loopd.backup

import android.content.Context
import android.net.Uri
import android.provider.DocumentsContract
import java.io.File
import java.io.FileInputStream
import java.io.FileNotFoundException
import java.io.FileOutputStream
import java.io.InputStream
import java.io.OutputStream

/** Where backup files go: the folder picked in the system picker, or a plain folder in tests. */
interface BackupFolder {
    /** Creates [name] (replacing nothing: names are unique per run) and returns its stream. */
    fun create(name: String): OutputStream

    fun open(name: String): InputStream

    /** Removes [name] if it exists; true when it is gone. */
    fun delete(name: String): Boolean

    /** The names of the files in the folder. */
    fun names(): List<String>
}

class DirectoryFolder(private val dir: File) : BackupFolder {
    override fun create(name: String): OutputStream {
        dir.mkdirs()
        val file = File(dir, name)
        if (file.exists()) throw java.io.IOException("$name exists")
        return FileOutputStream(file)
    }

    override fun open(name: String): InputStream = FileInputStream(File(dir, name))

    override fun delete(name: String): Boolean = File(dir, name).let { !it.exists() || it.delete() }

    override fun names(): List<String> = dir.list()?.toList() ?: emptyList()
}

/**
 * A folder picked with ACTION_OPEN_DOCUMENT_TREE and kept with a persistable
 * permission (Phase 0B: the phone's own storage and Google Drive both work).
 */
class DocumentTreeFolder(private val context: Context, treeUri: Uri) : BackupFolder {
    private val resolver = context.contentResolver
    private val tree = treeUri
    private val folder = DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))

    override fun create(name: String): OutputStream {
        val doc = DocumentsContract.createDocument(resolver, folder, MIME, name)
            ?: throw FileNotFoundException("The folder refused $name")
        return resolver.openOutputStream(doc, "w") ?: throw FileNotFoundException("Cannot write $name")
    }

    override fun open(name: String): InputStream {
        val doc = find(name) ?: throw FileNotFoundException("$name is not in the folder")
        return resolver.openInputStream(doc) ?: throw FileNotFoundException("Cannot read $name")
    }

    override fun delete(name: String): Boolean {
        val doc = find(name) ?: return true
        return DocumentsContract.deleteDocument(resolver, doc)
    }

    override fun names(): List<String> = children().map { it.first }

    private fun find(name: String): Uri? = children().firstOrNull { it.first == name }?.second

    private fun children(): List<Pair<String, Uri>> {
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(tree, DocumentsContract.getDocumentId(folder))
        val projection = arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME, DocumentsContract.Document.COLUMN_DOCUMENT_ID)
        val out = mutableListOf<Pair<String, Uri>>()
        resolver.query(childrenUri, projection, null, null, null)?.use { cursor ->
            while (cursor.moveToNext()) {
                val name = cursor.getString(0) ?: continue
                out += name to DocumentsContract.buildDocumentUriUsingTree(tree, cursor.getString(1))
            }
        } ?: throw FileNotFoundException("The folder cannot be read")
        return out
    }

    private companion object {
        // Opaque bytes; the extension says what they are.
        const val MIME = "application/octet-stream"
    }
}
