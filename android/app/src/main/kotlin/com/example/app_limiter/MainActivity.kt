package com.example.app_limiter

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine
import android.provider.Settings
import android.net.Uri

class MainActivity: FlutterActivity() {
    private val USAGE_ACCESS_CHANNEL = "com.example.app_limiter/usage_access"
    private val USAGE_STATS_CHANNEL = "com.example.app_limiter/usage_stats"
    private val OVERLAY_CHANNEL = "com.example.app_limiter/overlay"

    private lateinit var usageStatsHandler: UsageStatsHandler
    private lateinit var overlayHandler: OverlayHandler

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize handlers
        usageStatsHandler = UsageStatsHandler(this)
        overlayHandler = OverlayHandler(this)

        // Original usage access channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, USAGE_ACCESS_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "openUsageAccessSettings") {
                    val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }

        // Usage stats channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, USAGE_STATS_CHANNEL)
            .setMethodCallHandler { call, result ->
                usageStatsHandler.handleMethodCall(call, result)
            }

        // Overlay channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OVERLAY_CHANNEL)
            .setMethodCallHandler { call, result ->
                overlayHandler.handleMethodCall(call, result)
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        overlayHandler.handleActivityResult(requestCode, resultCode, data)
    }
}
