package com.pursoth.loopd.background

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.pursoth.loopd.bridge.BackgroundHostApi
import com.pursoth.loopd.bridge.HeadlessBackgroundHostApi
import com.pursoth.loopd.bridge.KeyStoreApi
import com.pursoth.loopd.bridge.KeyStoreApiImpl
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull

class EngineStartException(val code: String) : Exception("The headless engine did not start: $code")

/**
 * The short-lived headless Flutter engine (ADR 0013).
 *
 * It starts at Dart's `backgroundMain()` when a job needs it and the app's
 * own engine is not running, is shared by the jobs running at that moment,
 * and is destroyed when the last one ends. While it exists it holds the
 * [WriterGate]. Everything here runs on the main thread, as Flutter requires.
 */
class HeadlessEngineHost(
    private val context: Context,
    private val gate: WriterGate,
    private val log: BackgroundRunLog,
) : WriterGate.Handover {
    /** One job's use of the engine; [close] it when the job ends. */
    class Lease internal constructor(val engine: JobEngine, internal val generation: Int)

    private val main = Handler(Looper.getMainLooper())
    private var engine: FlutterEngine? = null
    private var connection: EngineConnection? = null
    private var ready = CompletableDeferred<String>()
    private var users = 0
    private var generation = 0

    /** Starts the engine if needed and returns once Dart has opened the database. */
    suspend fun open(): Lease = withContext(Dispatchers.Main) {
        if (engine == null) start()
        val lease = Lease(connection!!, generation)
        users++
        val status = withTimeoutOrNull(START_TIMEOUT_MILLIS) { ready.await() } ?: "start_timeout"
        if (status != READY) {
            close(lease)
            throw EngineStartException(status)
        }
        lease
    }

    suspend fun close(lease: Lease) = withContext(Dispatchers.Main) {
        if (lease.generation != generation || engine == null) return@withContext
        users--
        if (users <= 0) destroy("idle")
    }

    /** Called by the engine's Dart side once the database is open. */
    internal fun onReady() = main.post {
        // Dart opened the database, so the Keystore unwrapped its key.
        log.add("headless_ready database=open")
        ready.complete(READY)
    }

    /** Called by the engine's Dart side when the database cannot be opened. */
    internal fun onFailed(code: String) = main.post {
        log.add("headless_failed code=$code")
        ready.complete(code)
    }

    override fun requestStop() {
        main.post {
            log.add("handover_requested engine=headless")
            connection?.stopAll()
        }
    }

    override fun forceStop() {
        main.post { if (engine != null) destroy("forced") }
    }

    private fun start() {
        val flutter = FlutterEngine(context.applicationContext) // also registers the plugins
        val messenger = flutter.dartExecutor.binaryMessenger
        generation++
        ready = CompletableDeferred()
        KeyStoreApi.setUp(messenger, KeyStoreApiImpl.shared(context))
        BackgroundHostApi.setUp(messenger, HeadlessBackgroundHostApi(this))
        connection = EngineConnection("headless", messenger)
        engine = flutter
        flutter.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(FlutterInjector.instance().flutterLoader().findAppBundlePath(), ENTRYPOINT),
        )
        log.add("headless_started")
    }

    private fun destroy(reason: String) {
        connection?.close()
        engine?.destroy()
        connection = null
        engine = null
        users = 0
        if (!ready.isCompleted) ready.complete("engine_destroyed")
        gate.releaseBackground()
        log.add("headless_stopped reason=$reason")
    }

    private companion object {
        const val ENTRYPOINT = "backgroundMain"
        const val READY = "ready"
        const val START_TIMEOUT_MILLIS = 30_000L
    }
}
