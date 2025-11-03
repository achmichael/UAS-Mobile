package com.example.app_limiter

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Handler for managing full-screen overlay windows
 * Used to block apps when usage limit is reached
 */
class OverlayHandler(private val activity: Activity) {

    companion object {
        private const val OVERLAY_PERMISSION_REQUEST_CODE = 1001
        private var overlayView: View? = null
        private var windowManager: WindowManager? = null
    }

    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "showCustomOverlay" -> {
                val appName = call.argument<String>("appName")
                if (appName != null) {
                    showCustomOverlay(appName)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENT", "App name is required", null)
                }
            }
            "hideOverlay" -> {
                hideOverlay()
                result.success(null)
            }
            "hasOverlayPermission" -> {
                val hasPermission = hasOverlayPermission()
                result.success(hasPermission)
            }
            "requestOverlayPermission" -> {
                requestOverlayPermission()
                result.success(null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    /**
     * Show a full-screen blocking overlay
     */
    fun showCustomOverlay(appName: String) {
        if (!hasOverlayPermission()) {
            return
        }

        try {
            // Remove existing overlay if any
            hideOverlay()

            // Get window manager
            windowManager = activity.getSystemService(Context.WINDOW_SERVICE) as WindowManager

            // Create overlay view
            val inflater = activity.getSystemService(Context.LAYOUT_INFLATER_SERVICE) as LayoutInflater
            overlayView = inflater.inflate(R.layout.overlay_block, null)

            // Set app name in overlay
            val appNameTextView = overlayView?.findViewById<TextView>(R.id.blocked_app_name)
            appNameTextView?.text = "Time limit reached for:\n$appName"

            // Setup close button to go to home screen
            val closeButton = overlayView?.findViewById<Button>(R.id.close_button)
            closeButton?.setOnClickListener {
                // Go to home screen
                val homeIntent = Intent(Intent.ACTION_MAIN)
                homeIntent.addCategory(Intent.CATEGORY_HOME)
                homeIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                activity.startActivity(homeIntent)
                
                // Hide overlay after a short delay
                hideOverlay()
            }

            // Setup window parameters for overlay
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_SYSTEM_ALERT
                },
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                        WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                PixelFormat.TRANSLUCENT
            )

            params.gravity = Gravity.CENTER

            // Add view to window manager
            windowManager?.addView(overlayView, params)

        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /**
     * Hide the currently displayed overlay
     */
    fun hideOverlay() {
        try {
            if (overlayView != null && windowManager != null) {
                windowManager?.removeView(overlayView)
                overlayView = null
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /**
     * Check if overlay permission is granted
     */
    fun hasOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(activity)
        } else {
            true // Permission not required for older versions
        }
    }

    /**
     * Request overlay permission from user
     */
    fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(activity)) {
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:${activity.packageName}")
                )
                activity.startActivityForResult(intent, OVERLAY_PERMISSION_REQUEST_CODE)
            }
        }
    }

    /**
     * Handle activity result for overlay permission
     */
    fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == OVERLAY_PERMISSION_REQUEST_CODE) {
            // Permission result handled, you can check permission status
            // and notify Flutter side if needed
        }
    }
}
