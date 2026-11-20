package com.pursoth.loopd

import android.content.Intent
import com.pursoth.loopd.background.BackgroundRuntime
import com.pursoth.loopd.background.EngineConnection
import com.pursoth.loopd.bridge.AppBackgroundHostApi
import com.pursoth.loopd.bridge.BackgroundHostApi
import com.pursoth.loopd.bridge.BackupApi
import com.pursoth.loopd.bridge.BackupApiImpl
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
        // Backups need this activity for the system folder picker.
        BackupApi.setUp(messenger, BackupApiImpl.shared(applicationContext).also { it.attach(this) })

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

    @Deprecated("The folder picker still reports through it; FlutterActivity has no result API.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (BackupApiImpl.shared(applicationContext).onActivityResult(requestCode, resultCode, data)) return
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        BackupApiImpl.shared(applicationContext).attach(null)
        connection?.close()
        connection = null
        BackgroundRuntime.get(applicationContext).gate.releaseApp(engineId(flutterEngine))
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun engineId(engine: FlutterEngine): Long = System.identityHashCode(engine).toLong()
}
