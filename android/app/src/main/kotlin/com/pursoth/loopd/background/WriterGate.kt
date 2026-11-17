package com.pursoth.loopd.background

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.mapNotNull
import kotlinx.coroutines.withTimeoutOrNull

/**
 * Makes sure only one engine writes the database at a time (ADR 0013).
 *
 * - The app's own engine takes the gate before it opens the database
 *   ([acquireForApp]) and gives it back when it is destroyed ([releaseApp]).
 * - A background job asks for the gate with [claimForBackground]. If the
 *   app's engine holds it, the job runs inside the app's engine instead, so
 *   there is still one writer. Otherwise the headless engine takes it.
 * - If the app starts while the headless engine holds the gate, the
 *   headless engine is asked to stop at its next checkpoint, and forced to
 *   stop after [handoverTimeoutMillis]. The app always wins.
 *
 * Plain Kotlin with no Android types, so it is tested on the JVM.
 */
class WriterGate(private val handoverTimeoutMillis: Long = 10_000) {
    /** How the background holder is asked to let go of the gate. */
    interface Handover {
        /** Ask every running job to save its progress and stop. */
        fun requestStop()

        /** Stop now, for a job that did not stop in time. */
        fun forceStop()
    }

    sealed interface Holder {
        data object Free : Holder

        /** The app's engine; [engine] is set once its database is open. */
        data class App(val engineId: Long, val engine: JobEngine?) : Holder

        data class Background(val handover: Handover) : Holder
    }

    sealed interface Claim {
        /** Run the job in the app's engine, which already writes the database. */
        data class UseApp(val engine: JobEngine) : Claim

        /** The app is starting; wait for it with [awaitApp]. */
        data object AppStarting : Claim

        /** The background engine may write now. */
        data object Acquired : Claim
    }

    private val state = MutableStateFlow<Holder>(Holder.Free)
    private var appsWaiting = 0

    val holder: Holder get() = state.value

    /** True while the app holds the gate or is waiting for it. */
    val appWantsWriter: Boolean
        get() = synchronized(this) { appsWaiting > 0 || state.value is Holder.App }

    /** Returns once the app's engine [engineId] is the only writer. */
    suspend fun acquireForApp(engineId: Long) {
        synchronized(this) { appsWaiting++ }
        try {
            while (true) {
                val background = synchronized(this) {
                    val current = state.value
                    if (current !is Holder.Background) {
                        state.value = Holder.App(engineId, null)
                        return
                    }
                    current
                }
                background.handover.requestStop()
                val freed = withTimeoutOrNull(handoverTimeoutMillis) { state.first { it !is Holder.Background } }
                if (freed == null) {
                    background.handover.forceStop()
                    state.first { it !is Holder.Background }
                }
            }
        } finally {
            synchronized(this) { appsWaiting-- }
        }
    }

    /** The app's engine has opened the database and can run jobs. */
    fun appReady(engineId: Long, engine: JobEngine) = synchronized(this) {
        val current = state.value
        if (current is Holder.App && current.engineId == engineId) state.value = current.copy(engine = engine)
    }

    /** The app's engine is gone, or could not open the database. */
    fun releaseApp(engineId: Long) = synchronized(this) {
        val current = state.value
        if (current is Holder.App && current.engineId == engineId) state.value = Holder.Free
    }

    /** Where a background job should run. [handover] is used only if this takes the gate. */
    fun claimForBackground(handover: Handover): Claim = synchronized(this) {
        if (appsWaiting > 0) return Claim.AppStarting
        when (val current = state.value) {
            Holder.Free -> {
                state.value = Holder.Background(handover)
                Claim.Acquired
            }
            is Holder.App -> current.engine?.let { Claim.UseApp(it) } ?: Claim.AppStarting
            // Jobs share the one headless engine.
            is Holder.Background -> Claim.Acquired
        }
    }

    /** The headless engine has stopped. */
    fun releaseBackground() = synchronized(this) {
        if (state.value is Holder.Background) state.value = Holder.Free
    }

    /** The app's engine once it can run jobs, or null after [timeoutMillis]. */
    suspend fun awaitApp(timeoutMillis: Long): JobEngine? =
        withTimeoutOrNull(timeoutMillis) { state.mapNotNull { (it as? Holder.App)?.engine }.first() }
}
