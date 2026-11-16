package com.pursoth.loopd

import com.pursoth.loopd.bridge.KeyStoreApi
import com.pursoth.loopd.bridge.KeyStoreApiImpl
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        KeyStoreApi.setUp(flutterEngine.dartExecutor.binaryMessenger, KeyStoreApiImpl(applicationContext))
    }
}
