package com.pursoth.loopd.bridge

import android.os.SystemClock
import com.pursoth.loopd.background.BackgroundRunLog
import com.pursoth.loopd.background.EngineConnection
import com.pursoth.loopd.background.HeadlessEngineHost
import com.pursoth.loopd.background.WriterGate

/** [BackgroundHostApi] for the app's own engine (ADR 0013). */
class AppBackgroundHostApi(
    private val gate: WriterGate,
    private val engineId: Long,
    private val connection: EngineConnection,
    private val log: BackgroundRunLog,
) : BackgroundHostApi {
    override suspend fun acquireWriter() {
        val handover = gate.holder is WriterGate.Holder.Background
        val started = SystemClock.elapsedRealtime()
        gate.acquireForApp(engineId)
        if (handover) log.add("app_took_writer waited_ms=${SystemClock.elapsedRealtime() - started}")
    }

    override fun engineReady() = gate.appReady(engineId, connection)

    override fun engineFailed(code: String) {
        log.add("app_engine_failed code=$code")
        // The app shows its failure screen and does not write.
        gate.releaseApp(engineId)
    }
}

/** [BackgroundHostApi] for the headless engine, which already holds the gate. */
class HeadlessBackgroundHostApi(private val host: HeadlessEngineHost) : BackgroundHostApi {
    override suspend fun acquireWriter() = Unit

    override fun engineReady() {
        host.onReady()
    }

    override fun engineFailed(code: String) {
        host.onFailed(code)
    }
}
