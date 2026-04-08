package com.bitlynx.safely

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val geofenceManager = SafelyGeofenceManager(this)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SafelyGeofenceManager.CHANNEL_NAME
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "registerGeofences" -> geofenceManager.registerGeofences(call.arguments, result)
                "clearGeofences" -> geofenceManager.clearGeofences(result)
                else -> result.notImplemented()
            }
        }
    }
}
