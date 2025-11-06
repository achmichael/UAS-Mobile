package com.example.app_limiter

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class AppLimiterPlugin : FlutterPlugin, ActivityAware {

    companion object {
        private const val OVERLAY_CHANNEL = "com.example.app_limiter/overlay"
        private const val USAGE_STATS_CHANNEL = "com.example.app_limiter/usage_stats"
        private const val USAGE_ACCESS_CHANNEL = "com.example.app_limiter/usage_access"
    }

    private var applicationContext: Context? = null
    private var overlayChannel: MethodChannel? = null
    private var usageStatsChannel: MethodChannel? = null
    private var usageAccessChannel: MethodChannel? = null
    private var overlayHandler: OverlayHandler? = null
    private var usageStatsHandler: UsageStatsHandler? = null
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null

    private val activityResultListener = object : PluginRegistry.ActivityResultListener {
        override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
            overlayHandler?.handleActivityResult(requestCode, resultCode, data)
            return false
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext

        overlayChannel = MethodChannel(binding.binaryMessenger, OVERLAY_CHANNEL).also { channel ->
            channel.setMethodCallHandler { call, result ->
                val handler = getOverlayHandler()
                if (handler != null) {
                    handler.handleMethodCall(call, result)
                } else {
                    result.error("NO_CONTEXT", "Overlay handler unavailable", null)
                }
            }
        }

        usageStatsChannel = MethodChannel(binding.binaryMessenger, USAGE_STATS_CHANNEL).also { channel ->
            channel.setMethodCallHandler { call, result ->
                val handler = getUsageStatsHandler()
                if (handler != null) {
                    handler.handleMethodCall(call, result)
                } else {
                    result.error("NO_CONTEXT", "Usage stats handler unavailable", null)
                }
            }
        }

        usageAccessChannel = MethodChannel(binding.binaryMessenger, USAGE_ACCESS_CHANNEL).also { channel ->
            channel.setMethodCallHandler { call, result ->
                handleUsageAccessCall(call, result)
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        overlayChannel?.setMethodCallHandler(null)
        usageStatsChannel?.setMethodCallHandler(null)
        usageAccessChannel?.setMethodCallHandler(null)

        overlayChannel = null
        usageStatsChannel = null
        usageAccessChannel = null
        overlayHandler = null
        usageStatsHandler = null
        applicationContext = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding

        overlayHandler?.updateActivity(activity)
        usageStatsHandler?.updateActivity(activity)

        binding.addActivityResultListener(activityResultListener)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        detachActivity()
    }

    private fun detachActivity() {
        activityBinding?.removeActivityResultListener(activityResultListener)
        activityBinding = null
        activity = null
        overlayHandler?.updateActivity(null)
        usageStatsHandler?.updateActivity(null)
    }

    private fun getOverlayHandler(): OverlayHandler? {
        val context = applicationContext ?: return null
        if (overlayHandler == null) {
            overlayHandler = OverlayHandler(context)
        }
        overlayHandler?.updateActivity(activity)
        return overlayHandler
    }

    private fun getUsageStatsHandler(): UsageStatsHandler? {
        val context = applicationContext ?: return null
        if (usageStatsHandler == null) {
            usageStatsHandler = UsageStatsHandler(context)
        }
        usageStatsHandler?.updateActivity(activity)
        return usageStatsHandler
    }

    private fun handleUsageAccessCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "openUsageAccessSettings" -> {
                val currentActivity = activity
                if (currentActivity != null) {
                    val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    currentActivity.startActivity(intent)
                    result.success(null)
                } else {
                    result.error("NO_ACTIVITY", "Unable to open usage access settings without foreground activity", null)
                }
            }
            else -> result.notImplemented()
        }
    }
}
