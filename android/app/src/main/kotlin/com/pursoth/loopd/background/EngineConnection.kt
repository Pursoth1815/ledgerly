package com.pursoth.loopd.background

import com.pursoth.loopd.bridge.BackgroundJobApi
import com.pursoth.loopd.bridge.FlutterError
import com.pursoth.loopd.bridge.JobOutcome
import com.pursoth.loopd.bridge.JobResult
import io.flutter.plugin.common.BinaryMessenger
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.async
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.selects.select
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import java.util.Collections

/**
 * A [JobEngine] that runs jobs in one Flutter engine through Pigeon.
 *
 * Messages go out on the main thread, as Flutter requires. A destroyed
 * engine never answers, so [close] ends every waiting run with
 * [Outcome.STOPPED] instead of leaving it hanging.
 */
class EngineConnection(override val name: String, messenger: BinaryMessenger) : JobEngine {
    private val api = BackgroundJobApi(messenger)
    private val closed = CompletableDeferred<Unit>()
    private val running: MutableSet<String> = Collections.synchronizedSet(mutableSetOf())
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    override suspend fun run(runId: String, kind: String, attempt: Int): RunResult = withContext(Dispatchers.Main) {
        if (closed.isCompleted) return@withContext RunResult(Outcome.STOPPED, "engine_closed")
        running += runId
        // Not a child of the caller: if the worker is cancelled, Dart keeps
        // the call until it has saved its progress.
        val call = scope.async { api.runJob(runId, kind, attempt.toLong()) }
        try {
            select {
                call.onAwait { it.toRunResult() }
                closed.onAwait { RunResult(Outcome.STOPPED, "engine_closed") }
            }
        } catch (e: FlutterError) {
            // Nothing is listening yet (or any more): try again later rather
            // than dropping the work.
            if (e.code == "channel-error") {
                RunResult(Outcome.STOPPED, "dart_not_listening")
            } else {
                RunResult(Outcome.FAILED, "dart_error code=${e.code}")
            }
        } catch (e: CancellationException) {
            // Android stopped the worker. Ask Dart to stop at its next
            // checkpoint and give it a moment to save before rethrowing.
            withContext(NonCancellable) {
                stop(runId)
                withTimeoutOrNull(STOP_GRACE_MILLIS) {
                    runCatching { select { call.onAwait {}; closed.onAwait {} } }
                }
            }
            throw e
        } finally {
            running -= runId
        }
    }

    override suspend fun stop(runId: String) {
        withContext(Dispatchers.Main) {
            if (closed.isCompleted) return@withContext
            // A destroyed engine never replies, so the wait is bounded.
            withTimeoutOrNull(STOP_GRACE_MILLIS) { runCatching { api.stopJob(runId) } }
        }
    }

    /** Asks every run in this engine to stop at its next checkpoint. */
    fun stopAll() {
        running.toList().forEach { runId -> scope.launch { stop(runId) } }
    }

    /** The engine is being destroyed: every waiting run ends as stopped. */
    fun close() {
        closed.complete(Unit)
        scope.cancel()
    }

    private fun JobResult.toRunResult() = RunResult(
        outcome = when (outcome) {
            JobOutcome.DONE -> Outcome.DONE
            JobOutcome.STOPPED -> Outcome.STOPPED
            JobOutcome.FAILED -> Outcome.FAILED
        },
        detail = detail,
    )

    private companion object {
        const val STOP_GRACE_MILLIS = 3_000L
    }
}
