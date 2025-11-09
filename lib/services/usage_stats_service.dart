import 'dart:async';
import 'package:app_limiter_plugin/app_limiter_plugin.dart';

class UsageStatsService {
  final _plugin = AppLimiterPlugin();

  Future<String?> getCurrentForegroundApp() async {
    try {
      final String? packageName = await _plugin.getCurrentForegroundApp();
      return packageName;
    } catch (e) {
      print('[UsageStats] Error getting foreground app: $e');
      return null;
    }
  }

  /// Get total usage time for a specific app today (in minutes)
  /// Returns 0 if unable to get usage or if app hasn't been used
  Future<int> getAppUsageToday(String packageName) async {
    try {
      // Get usage in milliseconds from plugin
      final int usageMillis = await _plugin.getAppUsageToday(packageName);
      
      if (usageMillis == 0) {
        return 0;
      }
      
      // Convert milliseconds to minutes
      final minutes = (usageMillis / 1000 / 60).floor();
      return minutes;
    } catch (e) {
      print('[UsageStats] Error getting app usage: $e');
      return 0;
    }
  }

  /// Get usage stats for all apps today
  /// Returns Map<String, int> where key is package name and value is usage in minutes
  Future<Map<String, int>> getAllAppsUsageToday() async {
    try {
      final Map<String, int> usageMap = await _plugin.getAllAppsUsageToday();
      
      if (usageMap.isEmpty) {
        return {};
      }
      
      // Convert to Map<String, int> with minutes
      final result = <String, int>{};
      usageMap.forEach((key, value) {
        // Value is in milliseconds, convert to minutes
        result[key] = (value / 1000 / 60).floor();
      });
      
      return result;
    } catch (e) {
      print('[UsageStats] Error getting all apps usage: $e');
      return {};
    }
  }

  /// Check if usage access permission is granted
  Future<bool> hasUsageAccessPermission() async {
    try {
      final bool hasPermission = await _plugin.hasUsageAccessPermission();
      return hasPermission;
    } catch (e) {
      print('[UsageStats] Error checking permission: $e');
      return false;
    }
  }

  /// Open usage access settings page
  Future<void> openUsageAccessSettings() async {
    try {
      await _plugin.openUsageAccessSettings();
    } catch (e) {
      print('[UsageStats] Error opening settings: $e');
    }
  }
}
