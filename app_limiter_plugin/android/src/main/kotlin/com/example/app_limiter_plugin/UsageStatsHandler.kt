package com.example.app_limiter_plugin

import android.app.Activity
import android.app.AppOpsManager
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.lang.ref.WeakReference
import java.util.*

/**
 * Handler for UsageStatsManager operations
 * Provides methods to query app usage statistics and detect foreground apps
 */
class UsageStatsHandler(private val appContext: Context) {

    private val usageStatsManager: UsageStatsManager? by lazy {
        appContext.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
    }

    private var activityRef: WeakReference<Activity?> = WeakReference(null)

    fun updateActivity(activity: Activity?) {
        activityRef = WeakReference(activity)
    }

    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getCurrentForegroundApp" -> {
                val foregroundApp = getCurrentForegroundApp()
                result.success(foregroundApp)
            }
            "getAppUsageToday" -> {
                val packageName = call.argument<String>("packageName")
                if (packageName != null) {
                    val usage = getAppUsageToday(packageName)
                    result.success(usage)
                } else {
                    result.error("INVALID_ARGUMENT", "Package name is required", null)
                }
            }
            "getAllAppsUsageToday" -> {
                val allUsage = getAllAppsUsageToday()
                result.success(allUsage)
            }
            "hasUsageAccessPermission" -> {
                val hasPermission = hasUsageAccessPermission()
                result.success(hasPermission)
            }
            "openUsageAccessSettings" -> {
                openUsageAccessSettings()
                result.success(null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    /**
     * Get the package name of the currently active foreground app
     * Returns null if unable to determine
     */
    private fun getCurrentForegroundApp(): String? {
        if (!hasUsageAccessPermission()) {
            return null
        }

        try {
            val endTime = System.currentTimeMillis()
            val beginTime = endTime - 1000 * 60 // Last 1 minute

            val usageStatsList = usageStatsManager?.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                beginTime,
                endTime
            )

            if (usageStatsList.isNullOrEmpty()) {
                return null
            }

            // Get the most recently used app
            val sortedStats = usageStatsList.sortedByDescending { it.lastTimeUsed }
            
            // Return the package name of the most recently used app
            return sortedStats.firstOrNull()?.packageName
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        }
    }

    /**
     * Get total usage time for a specific app today
     * Returns usage in milliseconds
     */
    private fun getAppUsageToday(packageName: String): Long {
        if (!hasUsageAccessPermission()) {
            return 0
        }

        try {
            val calendar = Calendar.getInstance()
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            calendar.set(Calendar.MILLISECOND, 0)
            val startOfDay = calendar.timeInMillis
            val now = System.currentTimeMillis()

            val usageStatsList = usageStatsManager?.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                startOfDay,
                now
            )

            if (usageStatsList.isNullOrEmpty()) {
                return 0
            }

            // Find usage for the specified package
            val appUsage = usageStatsList.find { it.packageName == packageName }
            return appUsage?.totalTimeInForeground ?: 0
        } catch (e: Exception) {
            e.printStackTrace()
            return 0
        }
    }

    /**
     * Get usage statistics for all apps today
     * Returns Map<String, Long> where key is package name and value is usage in milliseconds
     */
    private fun getAllAppsUsageToday(): Map<String, Long> {
        if (!hasUsageAccessPermission()) {
            return emptyMap()
        }

        try {
            val calendar = Calendar.getInstance()
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            calendar.set(Calendar.MILLISECOND, 0)
            val startOfDay = calendar.timeInMillis
            val now = System.currentTimeMillis()

            val usageStatsList = usageStatsManager?.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                startOfDay,
                now
            )

            if (usageStatsList.isNullOrEmpty()) {
                return emptyMap()
            }

            val usageMap = mutableMapOf<String, Long>()
            for (usageStats in usageStatsList) {
                if (usageStats.totalTimeInForeground > 0) {
                    usageMap[usageStats.packageName] = usageStats.totalTimeInForeground
                }
            }

            return usageMap
        } catch (e: Exception) {
            e.printStackTrace()
            return emptyMap()
        }
    }

    /**
     * Check if the app has usage access permission
     */
    private fun hasUsageAccessPermission(): Boolean {
        return try {
            val appOps = appContext.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val packageName = appContext.packageName
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOps.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    android.os.Process.myUid(),
                    packageName
                )
            } else {
                @Suppress("DEPRECATION")
                appOps.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    android.os.Process.myUid(),
                    packageName
                )
            }
            mode == AppOpsManager.MODE_ALLOWED
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    /**
     * Open the system settings page for usage access
     */
    private fun openUsageAccessSettings() {
        val activity = activityRef.get()
        if (activity == null) {
            return
        }

        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        activity.startActivity(intent)
    }
}
