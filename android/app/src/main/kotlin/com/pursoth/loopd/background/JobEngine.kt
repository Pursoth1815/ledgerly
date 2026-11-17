package com.pursoth.loopd.background

/** How one run of a background job ended (mirrors the Pigeon `JobOutcome`). */
enum class Outcome { DONE, STOPPED, FAILED }

/** The result of one run. [detail] holds safe fields only, such as `step=412/900`. */
data class RunResult(val outcome: Outcome, val detail: String)

/**
 * A Dart engine that can run background jobs (ADR 0013): the app's own
 * engine, or the short-lived headless engine.
 */
interface JobEngine {
    /** `app` or `headless`, for the run log. */
    val name: String

    /** Runs [kind] and returns how it ended; a closed engine returns [Outcome.STOPPED]. */
    suspend fun run(runId: String, kind: String, attempt: Int): RunResult

    /** Asks [runId] to save its progress and stop at its next checkpoint. */
    suspend fun stop(runId: String)
}
