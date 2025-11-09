import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app_limiter_plugin_platform_interface.dart';

/// An implementation of [AppLimiterPluginPlatform] that uses method channels.
class MethodChannelAppLimiterPlugin extends AppLimiterPluginPlatform {
  /// The method channel used to interact with overlay functionality
  @visibleForTesting
  final overlayChannel = const MethodChannel('com.example.app_limiter_plugin/overlay');

  /// The method channel used to interact with usage stats
  @visibleForTesting
  final usageStatsChannel = const MethodChannel('com.example.app_limiter_plugin/usage_stats');

  /// The method channel used to interact with usage access settings
  @visibleForTesting
  final usageAccessChannel = const MethodChannel('com.example.app_limiter_plugin/usage_access');

  // Overlay methods
  @override
  Future<void> showCustomOverlay(String appName) async {
    await overlayChannel.invokeMethod('showCustomOverlay', {'appName': appName});
  }

  @override
  Future<void> hideOverlay() async {
    await overlayChannel.invokeMethod('hideOverlay');
  }

  @override
  Future<bool> hasOverlayPermission() async {
    final bool? hasPermission = await overlayChannel.invokeMethod<bool>('hasOverlayPermission');
    return hasPermission ?? false;
  }

  @override
  Future<void> requestOverlayPermission() async {
    await overlayChannel.invokeMethod('requestOverlayPermission');
  }

  // Usage Stats methods
  @override
  Future<String?> getCurrentForegroundApp() async {
    final String? app = await usageStatsChannel.invokeMethod<String>('getCurrentForegroundApp');
    return app;
  }

  @override
  Future<int> getAppUsageToday(String packageName) async {
    final int? usage = await usageStatsChannel.invokeMethod<int>(
      'getAppUsageToday',
      {'packageName': packageName},
    );
    return usage ?? 0;
  }

  @override
  Future<Map<String, int>> getAllAppsUsageToday() async {
    final Map<dynamic, dynamic>? result = 
        await usageStatsChannel.invokeMethod<Map<dynamic, dynamic>>('getAllAppsUsageToday');
    
    if (result == null) return {};
    
    return result.map((key, value) => MapEntry(key.toString(), value as int));
  }

  @override
  Future<bool> hasUsageAccessPermission() async {
    final bool? hasPermission = 
        await usageStatsChannel.invokeMethod<bool>('hasUsageAccessPermission');
    return hasPermission ?? false;
  }

  @override
  Future<void> openUsageAccessSettings() async {
    await usageStatsChannel.invokeMethod('openUsageAccessSettings');
  }
}
