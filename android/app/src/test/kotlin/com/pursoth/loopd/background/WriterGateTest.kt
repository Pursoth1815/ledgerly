package com.pursoth.loopd.background

import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.yield
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File

class WriterGateTest {
    @get:Rule
    val temp = TemporaryFolder()

    private val appEngine = FakeEngine("app")

    @Test
    fun aJobRunsInTheAppEngineWhileTheAppHoldsTheGate() = runBlocking {
        val gate = WriterGate()
        gate.acquireForApp(engineId = 1)

        // The app has not opened its database yet.
        assertEquals(WriterGate.Claim.AppStarting, gate.claimForBackground(FakeHandover()))

        gate.appReady(1, appEngine)
        val claim = gate.claimForBackground(FakeHandover())
        assertSame(appEngine, (claim as WriterGate.Claim.UseApp).engine)
        assertTrue(gate.holder is WriterGate.Holder.App)
    }

    @Test
    fun theHeadlessEngineTakesAFreeGateAndJobsShareIt() {
        val gate = WriterGate()
        assertEquals(WriterGate.Claim.Acquired, gate.claimForBackground(FakeHandover()))
        assertEquals(WriterGate.Claim.Acquired, gate.claimForBackground(FakeHandover()))
        assertTrue(gate.holder is WriterGate.Holder.Background)

        gate.releaseBackground()
        assertEquals(WriterGate.Holder.Free, gate.holder)
    }

    @Test
    fun theAppAsksABackgroundJobToStopAndTakesOverWhenItHasStopped() = runBlocking {
        val gate = WriterGate()
        val handover = FakeHandover()
        gate.claimForBackground(handover)

        val app = launch(Dispatchers.Default) { gate.acquireForApp(engineId = 7) }
        withTimeout(2_000) { while (handover.stopRequests == 0) yield() }

        // While the app waits, no new background work may start.
        assertTrue(gate.appWantsWriter)
        assertEquals(WriterGate.Claim.AppStarting, gate.claimForBackground(FakeHandover()))
        assertTrue(app.isActive)

        gate.releaseBackground()
        withTimeout(2_000) { app.join() }
        assertEquals(WriterGate.Holder.App(7, null), gate.holder)
        assertEquals(0, handover.forcedStops)
    }

    @Test
    fun aBackgroundJobThatDoesNotStopInTimeIsForcedToStop() = runBlocking {
        val gate = WriterGate(handoverTimeoutMillis = 50)
        val handover = FakeHandover(onForceStop = { gate.releaseBackground() })
        gate.claimForBackground(handover)

        withTimeout(2_000) { gate.acquireForApp(engineId = 3) }

        assertEquals(1, handover.forcedStops)
        assertEquals(WriterGate.Holder.App(3, null), gate.holder)
    }

    @Test
    fun onlyTheEngineThatHoldsTheGateCanReleaseIt() = runBlocking {
        val gate = WriterGate()
        gate.acquireForApp(engineId = 1)

        gate.releaseApp(engineId = 2)
        gate.releaseBackground()
        assertTrue(gate.holder is WriterGate.Holder.App)

        gate.releaseApp(engineId = 1)
        assertEquals(WriterGate.Holder.Free, gate.holder)
        assertFalse(gate.appWantsWriter)
    }

    @Test
    fun awaitAppReturnsTheEngineOnceItIsReadyOrNullAfterTheTimeout() = runBlocking {
        val gate = WriterGate()
        assertNull(gate.awaitApp(timeoutMillis = 20))

        gate.acquireForApp(engineId = 5)
        val waiting = async(Dispatchers.Default, start = CoroutineStart.UNDISPATCHED) { gate.awaitApp(2_000) }
        delay(20)
        gate.appReady(5, appEngine)
        assertSame(appEngine, waiting.await())
    }

    @Test
    fun theRunLogKeepsOnlyTheNewestLines() {
        val log = BackgroundRunLog(File(temp.root, "runs.log"), maxLines = 8)
        repeat(30) { log.add("event=$it") }

        val lines = log.read().trim().lines()
        assertTrue(lines.size <= 10)
        assertTrue(lines.last().endsWith("event=29"))
        assertFalse(lines.any { it.endsWith("event=0") })
    }
}

private class FakeHandover(private val onForceStop: () -> Unit = {}) : WriterGate.Handover {
    var stopRequests = 0
    var forcedStops = 0

    override fun requestStop() {
        stopRequests++
    }

    override fun forceStop() {
        forcedStops++
        onForceStop()
    }
}

private class FakeEngine(override val name: String) : JobEngine {
    override suspend fun run(runId: String, kind: String, attempt: Int) = RunResult(Outcome.DONE, "")

    override suspend fun stop(runId: String) = Unit
}
