package com.example.app_limiter_plugin

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Path
import android.graphics.Rect
import android.os.Build
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import androidx.annotation.RequiresApi

/**
 * AccessibilityService untuk menghapus aplikasi dari Recent Apps
 * Digunakan ketika user menekan tombol Cancel di overlay
 */
class AppControlAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "AppControlAccessibility"
        private var instance: AppControlAccessibilityService? = null
        
        /**
         * Get singleton instance dari service
         */
        fun getInstance(): AppControlAccessibilityService? {
            return instance
        }
    }

    private var isProcessingRecents = false
    private var targetPackageToRemove: String? = null
    private var retryCount = 0
    private val maxRetries = 3

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.d(TAG, "AccessibilityService connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        Log.d(TAG, "onAccessibilityEvent: type=${event.eventType}, package=${event.packageName}, class=${event.className}")
        
        // Jika sedang memproses recent apps
        if (isProcessingRecents && targetPackageToRemove != null) {
            when (event.eventType) {
                AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,
                AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                    Log.d(TAG, "Window state/content changed while processing recents")
                    
                    // Tunggu sebentar agar UI recent apps selesai loading
                    rootInActiveWindow?.let { rootNode ->
                        android.os.Handler(mainLooper).postDelayed({
                            processRecentApps(rootNode)
                        }, 500) // Delay 500ms untuk memastikan UI sudah siap
                    }
                }
            }
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "Service interrupted")
        resetProcessing()
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        Log.d(TAG, "AccessibilityService destroyed")
    }

    /**
     * Method utama untuk menghapus aplikasi dari Recent Apps
     * Dipanggil dari overlay ketika tombol Cancel ditekan
     */
    fun removeTargetAppFromRecents(packageName: String) {
        Log.d(TAG, "removeTargetAppFromRecents: Starting for package=$packageName")
        
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            Log.w(TAG, "removeTargetAppFromRecents: Not supported on Android < N")
            return
        }

        if (isProcessingRecents) {
            Log.w(TAG, "removeTargetAppFromRecents: Already processing, ignoring request")
            return
        }

        targetPackageToRemove = packageName
        isProcessingRecents = true
        retryCount = 0

        Log.d(TAG, "removeTargetAppFromRecents: Opening recent apps")
        
        // Buka recent apps screen
        val success = performGlobalAction(GLOBAL_ACTION_RECENTS)
        
        if (success) {
            Log.d(TAG, "removeTargetAppFromRecents: Successfully triggered GLOBAL_ACTION_RECENTS")
            
            // Set timeout untuk reset jika gagal
            android.os.Handler(mainLooper).postDelayed({
                if (isProcessingRecents) {
                    Log.w(TAG, "removeTargetAppFromRecents: Timeout reached, resetting")
                    resetProcessing()
                }
            }, 5000) // 5 detik timeout
        } else {
            Log.e(TAG, "removeTargetAppFromRecents: Failed to open recent apps")
            resetProcessing()
        }
    }

    /**
     * Process recent apps window untuk mencari dan menghapus target app
     */
    private fun processRecentApps(rootNode: AccessibilityNodeInfo) {
        val packageToRemove = targetPackageToRemove ?: return
        
        Log.d(TAG, "processRecentApps: Searching for package=$packageToRemove")
        
        try {
            // Cari node "Clear All" button terlebih dahulu
            val clearAllNode = findClearAllButton(rootNode)
            if (clearAllNode != null) {
                Log.d(TAG, "processRecentApps: Found Clear All button, clicking it")
                clearAllNode.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                resetProcessing()
                return
            }

            // Cari aplikasi target di recent apps
            val targetNode = findAppNodeInRecents(rootNode, packageToRemove)
            
            if (targetNode != null) {
                Log.d(TAG, "processRecentApps: Found target app node")
                
                // Coba klik tombol close/dismiss jika ada
                val closeButton = findCloseButton(targetNode)
                if (closeButton != null) {
                    Log.d(TAG, "processRecentApps: Found close button, clicking it")
                    closeButton.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                    resetProcessing()
                    return
                }
                
                // Jika tidak ada tombol close, lakukan swipe gesture
                val bounds = Rect()
                targetNode.getBoundsInScreen(bounds)
                
                if (bounds.width() > 0 && bounds.height() > 0) {
                    Log.d(TAG, "processRecentApps: Performing swipe gesture on bounds=$bounds")
                    performSwipeToClose(bounds)
                    resetProcessing()
                } else {
                    Log.w(TAG, "processRecentApps: Invalid bounds, retrying...")
                    retryIfNeeded()
                }
            } else {
                Log.w(TAG, "processRecentApps: Target app not found in recents")
                retryIfNeeded()
            }
        } catch (e: Exception) {
            Log.e(TAG, "processRecentApps: Error processing recents", e)
            resetProcessing()
        } finally {
            rootNode.recycle()
        }
    }

    /**
     * Cari node aplikasi di recent apps berdasarkan package name atau label
     */
    private fun findAppNodeInRecents(rootNode: AccessibilityNodeInfo, packageName: String): AccessibilityNodeInfo? {
        Log.d(TAG, "findAppNodeInRecents: Searching for $packageName")
        
        // Cari berdasarkan package name
        val nodesByPackage = rootNode.findAccessibilityNodeInfosByViewId("android:id/snapshot")
        for (node in nodesByPackage) {
            if (node.packageName?.toString() == packageName) {
                Log.d(TAG, "findAppNodeInRecents: Found by package name")
                return node.parent ?: node
            }
        }
        
        // Cari berdasarkan text atau content description
        val allNodes = getAllNodes(rootNode)
        for (node in allNodes) {
            val text = node.text?.toString() ?: ""
            val contentDesc = node.contentDescription?.toString() ?: ""
            val nodePackage = node.packageName?.toString() ?: ""
            
            if (nodePackage.contains(packageName) || 
                text.contains(packageName, ignoreCase = true) ||
                contentDesc.contains(packageName, ignoreCase = true)) {
                Log.d(TAG, "findAppNodeInRecents: Found by text/description match")
                return node
            }
        }
        
        Log.d(TAG, "findAppNodeInRecents: Not found")
        return null
    }

    /**
     * Cari tombol "Clear All" di recent apps
     */
    private fun findClearAllButton(rootNode: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        val clearTexts = listOf("clear all", "close all", "hapus semua", "tutup semua")
        val allNodes = getAllNodes(rootNode)
        
        for (node in allNodes) {
            val text = node.text?.toString()?.lowercase() ?: ""
            val contentDesc = node.contentDescription?.toString()?.lowercase() ?: ""
            
            for (clearText in clearTexts) {
                if (text.contains(clearText) || contentDesc.contains(clearText)) {
                    if (node.isClickable) {
                        Log.d(TAG, "findClearAllButton: Found clear all button with text='$text'")
                        return node
                    }
                }
            }
        }
        
        return null
    }

    /**
     * Cari tombol close/dismiss pada card aplikasi
     */
    private fun findCloseButton(cardNode: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        // Cari di dalam card node
        for (i in 0 until cardNode.childCount) {
            val child = cardNode.getChild(i) ?: continue
            
            val contentDesc = child.contentDescription?.toString()?.lowercase() ?: ""
            val text = child.text?.toString()?.lowercase() ?: ""
            
            if ((contentDesc.contains("close") || contentDesc.contains("dismiss") || 
                 text.contains("close") || text.contains("dismiss")) && 
                child.isClickable) {
                Log.d(TAG, "findCloseButton: Found close button")
                return child
            }
            
            // Rekursif cari di child
            val foundInChild = findCloseButton(child)
            if (foundInChild != null) return foundInChild
        }
        
        return null
    }

    /**
     * Perform swipe gesture untuk menutup aplikasi dari recent apps
     * Swipe dari tengah card ke atas
     */
    @RequiresApi(Build.VERSION_CODES.N)
    private fun performSwipeToClose(bounds: Rect) {
        val centerX = bounds.centerX().toFloat()
        val startY = bounds.centerY().toFloat()
        val endY = bounds.top - 200f // Swipe ke atas
        
        Log.d(TAG, "performSwipeToClose: Swiping from ($centerX, $startY) to ($centerX, $endY)")
        
        performSwipeGesture(centerX, startY, centerX, endY)
    }

    /**
     * Helper untuk perform swipe gesture
     */
    @RequiresApi(Build.VERSION_CODES.N)
    private fun performSwipeGesture(startX: Float, startY: Float, endX: Float, endY: Float) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            Log.w(TAG, "performSwipeGesture: Gestures not supported on Android < N")
            return
        }

        val path = Path()
        path.moveTo(startX, startY)
        path.lineTo(endX, endY)

        val gestureBuilder = GestureDescription.Builder()
        val strokeDescription = GestureDescription.StrokeDescription(path, 0, 300) // 300ms duration
        gestureBuilder.addStroke(strokeDescription)

        val gestureDescription = gestureBuilder.build()

        val result = dispatchGesture(gestureDescription, object : GestureResultCallback() {
            override fun onCompleted(gestureDescription: GestureDescription) {
                super.onCompleted(gestureDescription)
                Log.d(TAG, "performSwipeGesture: Gesture completed successfully")
            }

            override fun onCancelled(gestureDescription: GestureDescription) {
                super.onCancelled(gestureDescription)
                Log.w(TAG, "performSwipeGesture: Gesture cancelled")
            }
        }, null)

        if (!result) {
            Log.e(TAG, "performSwipeGesture: Failed to dispatch gesture")
        }
    }

    /**
     * Get semua nodes dalam tree
     */
    private fun getAllNodes(rootNode: AccessibilityNodeInfo): List<AccessibilityNodeInfo> {
        val nodes = mutableListOf<AccessibilityNodeInfo>()
        
        fun traverseNode(node: AccessibilityNodeInfo) {
            nodes.add(node)
            for (i in 0 until node.childCount) {
                node.getChild(i)?.let { traverseNode(it) }
            }
        }
        
        traverseNode(rootNode)
        return nodes
    }

    /**
     * Retry jika masih ada kesempatan
     */
    private fun retryIfNeeded() {
        retryCount++
        if (retryCount < maxRetries) {
            Log.d(TAG, "retryIfNeeded: Retrying ($retryCount/$maxRetries)")
            android.os.Handler(mainLooper).postDelayed({
                rootInActiveWindow?.let { processRecentApps(it) }
            }, 1000)
        } else {
            Log.w(TAG, "retryIfNeeded: Max retries reached")
            resetProcessing()
        }
    }

    /**
     * Reset processing state
     */
    private fun resetProcessing() {
        Log.d(TAG, "resetProcessing: Cleaning up")
        isProcessingRecents = false
        targetPackageToRemove = null
        retryCount = 0
        
        // Kembali ke home screen
        performGlobalAction(GLOBAL_ACTION_HOME)
    }
}
