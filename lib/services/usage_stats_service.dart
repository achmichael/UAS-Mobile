import 'dart:async';
import 'package:flutter/services.dart';

/// Service to interact with Android UsageStatsManager
/// Provides methods to get app usage statistics and detect foreground apps
class UsageStatsService {
  static const MethodChannel _channel =
      MethodChannel('com.example.app_limiter/usage_stats');

  /// Get the currently active foreground app package name
  /// Returns null if unable to detect or if no app is in foreground
  Future<String?> getCurrentForegroundApp() async {
    try {
      final String? packageName = await _channel.invokeMethod('getCurrentForegroundApp');
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
      // Get usage in milliseconds from native side
      final int? usageMillis = await _channel.invokeMethod(
        'getAppUsageToday',
        {'packageName': packageName},
      );
      
      if (usageMillis == null) {
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
      final Map<dynamic, dynamic>? usageMap = await _channel.invokeMethod('getAllAppsUsageToday');
      
      if (usageMap == null) {
        return {};
      }
      
      // Convert to Map<String, int> with minutes
      final result = <String, int>{};
      usageMap.forEach((key, value) {
        if (key is String && value is int) {
          // Value is in milliseconds, convert to minutes
          result[key] = (value / 1000 / 60).floor();
        }
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
      final bool? hasPermission = await _channel.invokeMethod('hasUsageAccessPermission');
      return hasPermission ?? false;
    } catch (e) {
      print('[UsageStats] Error checking permission: $e');
      return false;
    }
  }

  /// Open usage access settings page
  Future<void> openUsageAccessSettings() async {
    try {
      await _channel.invokeMethod('openUsageAccessSettings');
    } catch (e) {
      print('[UsageStats] Error opening settings: $e');
    }
  }
}
