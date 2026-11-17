package com.pursoth.loopd.background

import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * A short record of background runs, kept in app-private storage that is
 * never backed up: what started, where it ran, how it ended and why Android
 * stopped it. Safe fields only (ADR 0014); never message text, amounts or
 * names. Keeps the newest [maxLines] lines.
 */
class BackgroundRunLog(private val file: File, private val maxLines: Int = 300) {
    @Synchronized
    fun add(event: String) {
        val stamp = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US).format(Date())
        try {
            file.parentFile?.mkdirs()
            file.appendText("$stamp $event\n")
            val lines = file.readLines()
            if (lines.size > maxLines + maxLines / 4) {
                file.writeText(lines.takeLast(maxLines).joinToString("\n", postfix = "\n"))
            }
        } catch (e: java.io.IOException) {
            // The log is a diagnostic aid; losing a line must never stop a job.
        }
    }

    @Synchronized
    fun read(): String = if (file.exists()) file.readText() else ""
}
