package com.example.app_limiter

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.KeyEvent
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.Button
import android.widget.FrameLayout
import android.widget.TextView
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.lang.ref.WeakReference

/**
 * Handler for managing full-screen overlay windows
 * Used to block apps when usage limit is reached
 */
class OverlayHandler(private val appContext: Context) {

    private val mainHandler = Handler(Looper.getMainLooper())
    private var activityRef: WeakReference<Activity?> = WeakReference(null)

    companion object {
        private const val OVERLAY_PERMISSION_REQUEST_CODE = 1001
        private const val TAG = "OverlayHandler"
        private var overlayView: View? = null
        private var windowManager: WindowManager? = null
    }

    fun updateActivity(activity: Activity?) {
        activityRef = WeakReference(activity)
        Log.d(TAG, "Activity updated: ${if (activity != null) "attached" else "detached"}")
    }

    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "showCustomOverlay" -> {
                val appName = call.argument<String>("appName")
                if (appName != null) {
                    Log.d(TAG, "MethodChannel: showCustomOverlay called for: $appName")
                    showCustomOverlay(appName)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENT", "App name is required", null)
                }
            }
            "hideOverlay" -> {
                Log.d(TAG, "MethodChannel: hideOverlay called")
                hideOverlay()
                result.success(null)
            }
            "hasOverlayPermission" -> {
                val hasPermission = hasOverlayPermission()
                Log.d(TAG, "MethodChannel: hasOverlayPermission = $hasPermission")
                result.success(hasPermission)
            }
            "requestOverlayPermission" -> {
                Log.d(TAG, "MethodChannel: requestOverlayPermission called")
                val success = requestOverlayPermission()
                if (success) {
                    result.success(null)
                } else {
                    result.error("NO_ACTIVITY", "Unable to open overlay permission screen without foreground activity", null)
                }
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
        Log.d(TAG, "showCustomOverlay: Starting for app: $appName")
        
        // Check permission first
        if (!hasOverlayPermission()) {
            Log.e(TAG, "showCustomOverlay: PERMISSION DENIED - Cannot display overlay without overlay permission")
            return
        }
        
        Log.d(TAG, "showCustomOverlay: Permission check passed")

        runOnMainThread {
            Log.d(TAG, "showCustomOverlay: Running on main thread")
            
            // Check if overlay already exists
            if (overlayView != null) {
                Log.d(TAG, "showCustomOverlay: Overlay already visible, ignoring duplicate request")
                return@runOnMainThread
            }

            try {
                Log.d(TAG, "showCustomOverlay: Inflating layout")
                val inflater = LayoutInflater.from(appContext)
                val contentView = inflater.inflate(R.layout.overlay_block, null)

                Log.d(TAG, "showCustomOverlay: Creating blocking container")
                val blockingContainer = FocusInterceptLayout(appContext)
                blockingContainer.addView(contentView)
                blockingContainer.layoutParams = ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT
                )
                
                // Add touch listener to consume all touches
                blockingContainer.setOnTouchListener { _, _ -> 
                    Log.d(TAG, "Touch event consumed by overlay")
                    true 
                }
                
                overlayView = blockingContainer

                Log.d(TAG, "showCustomOverlay: Getting WindowManager")
                windowManager = windowManager
                    ?: appContext.getSystemService(Context.WINDOW_SERVICE) as WindowManager

                Log.d(TAG, "showCustomOverlay: Setting up UI elements")
                val appNameTextView = contentView.findViewById<TextView>(R.id.blocked_app_name)
                appNameTextView?.text = "Time limit reached for:\n$appName"

                val closeButton = contentView.findViewById<Button>(R.id.close_button)
                closeButton?.setOnClickListener {
                    Log.d(TAG, "Close button clicked, going to home screen")
                    val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                        addCategory(Intent.CATEGORY_HOME)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    appContext.startActivity(homeIntent)
                    hideOverlay()
                }

                Log.d(TAG, "showCustomOverlay: Creating layout params")
                val params = createLayoutParams()
                
                Log.d(TAG, "showCustomOverlay: Adding view to WindowManager")
                windowManager?.addView(blockingContainer, params)
                
                Log.d(TAG, "showCustomOverlay: Requesting focus")
                blockingContainer.requestFocus()
                
                Log.d(TAG, "showCustomOverlay: SUCCESS - Overlay displayed")
            } catch (e: WindowManager.BadTokenException) {
                Log.e(TAG, "showCustomOverlay: FAILED - BadTokenException", e)
                overlayView = null
            } catch (e: SecurityException) {
                Log.e(TAG, "showCustomOverlay: FAILED - SecurityException (permission issue?)", e)
                overlayView = null
            } catch (e: Exception) {
                Log.e(TAG, "showCustomOverlay: FAILED - Unexpected error", e)
                overlayView = null
            }
        }
    }

    /**
     * Hide the currently displayed overlay
     */
    fun hideOverlay() {
        Log.d(TAG, "hideOverlay: Starting")
        
        runOnMainThread {
            val viewToRemove = overlayView
            
            if (viewToRemove == null) {
                Log.d(TAG, "hideOverlay: No overlay to remove")
                return@runOnMainThread
            }

            Log.d(TAG, "hideOverlay: Removing overlay view")
            try {
                if (viewToRemove.parent != null) {
                    windowManager?.removeView(viewToRemove)
                    Log.d(TAG, "hideOverlay: SUCCESS - Overlay removed")
                } else {
                    Log.d(TAG, "hideOverlay: View has no parent, skipping removal")
                }
            } catch (e: WindowManager.BadTokenException) {
                Log.e(TAG, "hideOverlay: BadTokenException while removing", e)
            } catch (e: IllegalArgumentException) {
                Log.e(TAG, "hideOverlay: IllegalArgumentException - view not attached", e)
            } catch (e: Exception) {
                Log.e(TAG, "hideOverlay: Unexpected error while removing", e)
            } finally {
                overlayView = null
                Log.d(TAG, "hideOverlay: overlayView set to null")
            }
        }
    }

    /**
     * Check if overlay permission is granted
     */
    fun hasOverlayPermission(): Boolean {
        val hasPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(appContext)
        } else {
            true // Permission not required for older versions
        }
        Log.d(TAG, "hasOverlayPermission: $hasPermission (SDK: ${Build.VERSION.SDK_INT})")
        return hasPermission
    }

    /**
     * Request overlay permission from user
     */
    fun requestOverlayPermission(): Boolean {
        Log.d(TAG, "requestOverlayPermission: Starting")
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val activity = activityRef.get()
            if (activity == null) {
                Log.e(TAG, "requestOverlayPermission: No activity attached, cannot open settings")
                return false
            }

            if (!Settings.canDrawOverlays(appContext)) {
                Log.d(TAG, "requestOverlayPermission: Opening permission settings")
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:${appContext.packageName}")
                )
                activity.startActivityForResult(intent, OVERLAY_PERMISSION_REQUEST_CODE)
            } else {
                Log.d(TAG, "requestOverlayPermission: Permission already granted")
            }
        } else {
            Log.d(TAG, "requestOverlayPermission: Not needed for SDK < 23")
        }

        return true
    }

    /**
     * Handle activity result for overlay permission
     */
    fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == OVERLAY_PERMISSION_REQUEST_CODE) {
            val hasPermission = hasOverlayPermission()
            Log.d(TAG, "handleActivityResult: Overlay permission result = $hasPermission")
        }
    }

    private fun createLayoutParams(): WindowManager.LayoutParams {
        Log.d(TAG, "createLayoutParams: Creating window layout parameters")
        
        val windowType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Log.d(TAG, "createLayoutParams: Using TYPE_APPLICATION_OVERLAY (Android O+)")
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            Log.d(TAG, "createLayoutParams: Using TYPE_SYSTEM_ALERT (Android < O)")
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_SYSTEM_ALERT
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            windowType,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_INSET_DECOR or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
            PixelFormat.TRANSLUCENT
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            params.layoutInDisplayCutoutMode =
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }

        params.gravity = Gravity.CENTER
        params.flags = params.flags or WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
        params.flags = params.flags or WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
        params.softInputMode = WindowManager.LayoutParams.SOFT_INPUT_STATE_ALWAYS_HIDDEN

        Log.d(TAG, "createLayoutParams: Flags = 0x${Integer.toHexString(params.flags)}")
        return params
    }

    private fun runOnMainThread(action: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            Log.d(TAG, "runOnMainThread: Already on main thread, executing immediately")
            action()
        } else {
            Log.d(TAG, "runOnMainThread: Posting to main thread")
            mainHandler.post { action() }
        }
    }

    /**
     * Transparent container that captures focus and input so touches never reach the host app
     */
    private class FocusInterceptLayout(context: Context) : FrameLayout(context) {
        init {
            isFocusable = true
            isFocusableInTouchMode = true
            Log.d(TAG, "FocusInterceptLayout: Created with focusable=true")
        }

        override fun onAttachedToWindow() {
            super.onAttachedToWindow()
            Log.d(TAG, "FocusInterceptLayout: Attached to window")
        }

        override fun onDetachedFromWindow() {
            super.onDetachedFromWindow()
            Log.d(TAG, "FocusInterceptLayout: Detached from window")
        }

        override fun dispatchTouchEvent(event: MotionEvent): Boolean {
            // Let child views (buttons) handle touches first
            val handled = super.dispatchTouchEvent(event)
            // Always consume the event so it doesn't pass through
            return true
        }

        override fun onInterceptTouchEvent(ev: MotionEvent): Boolean {
            // Don't intercept so children can receive touches
            return false
        }

        override fun onTouchEvent(event: MotionEvent): Boolean {
            // Consume touches that weren't handled by children
            return true
        }

        override fun dispatchKeyEvent(event: KeyEvent): Boolean {
            val shouldConsume = when (event.keyCode) {
                KeyEvent.KEYCODE_BACK,
                KeyEvent.KEYCODE_APP_SWITCH -> {
                    Log.d(TAG, "FocusInterceptLayout: Blocking key: ${event.keyCode}")
                    true
                }
                else -> false
            }

            return if (shouldConsume) {
                true
            } else {
                super.dispatchKeyEvent(event)
            }
        }
    }
}
