package com.pursoth.loopd.background

import android.content.Context
import java.io.File

/** The process-wide pieces of background execution (ADR 0013). */
class BackgroundRuntime private constructor(context: Context) {
    val gate = WriterGate()
    val log = BackgroundRunLog(File(context.noBackupFilesDir, "background/runs.log"))
    val headless = HeadlessEngineHost(context, gate, log)

    companion object {
        @Volatile private var instance: BackgroundRuntime? = null

        fun get(context: Context): BackgroundRuntime =
            instance ?: synchronized(this) {
                instance ?: BackgroundRuntime(context.applicationContext).also { instance = it }
            }
    }
}
