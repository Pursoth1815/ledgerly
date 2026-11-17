package com.pursoth.loopd

import com.pursoth.loopd.background.BackgroundRuntime
import com.pursoth.loopd.background.EngineConnection
import com.pursoth.loopd.bridge.AppBackgroundHostApi
import com.pursoth.loopd.bridge.BackgroundHostApi
import com.pursoth.loopd.bridge.KeyStoreApi
import com.pursoth.loopd.bridge.KeyStoreApiImpl
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var connection: EngineConnection? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        KeyStoreApi.setUp(messenger, KeyStoreApiImpl.shared(applicationContext))

        // The app's engine is a database writer: background jobs run in it
        // while it exists (ADR 0013).
        val runtime = BackgroundRuntime.get(applicationContext)
        val appConnection = EngineConnection("app", messenger)
        connection = appConnection
        BackgroundHostApi.setUp(
            messenger,
            AppBackgroundHostApi(runtime.gate, engineId(flutterEngine), appConnection, runtime.log),
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        connection?.close()
        connection = null
        BackgroundRuntime.get(applicationContext).gate.releaseApp(engineId(flutterEngine))
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun engineId(engine: FlutterEngine): Long = System.identityHashCode(engine).toLong()
}
