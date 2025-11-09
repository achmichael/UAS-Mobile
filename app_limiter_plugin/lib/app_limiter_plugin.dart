
import 'app_limiter_plugin_platform_interface.dart';

class AppLimiterPlugin {
  // Overlay methods
  Future<void> showCustomOverlay(String appName) {
    return AppLimiterPluginPlatform.instance.showCustomOverlay(appName);
  }

  Future<void> hideOverlay() {
    return AppLimiterPluginPlatform.instance.hideOverlay();
  }

  Future<bool> hasOverlayPermission() {
    return AppLimiterPluginPlatform.instance.hasOverlayPermission();
  }

  Future<void> requestOverlayPermission() {
    return AppLimiterPluginPlatform.instance.requestOverlayPermission();
  }

  // Usage Stats methods
  Future<String?> getCurrentForegroundApp() {
    return AppLimiterPluginPlatform.instance.getCurrentForegroundApp();
  }

  Future<int> getAppUsageToday(String packageName) {
    return AppLimiterPluginPlatform.instance.getAppUsageToday(packageName);
  }

  Future<Map<String, int>> getAllAppsUsageToday() {
    return AppLimiterPluginPlatform.instance.getAllAppsUsageToday();
  }

  Future<bool> hasUsageAccessPermission() {
    return AppLimiterPluginPlatform.instance.hasUsageAccessPermission();
  }

  Future<void> openUsageAccessSettings() {
    return AppLimiterPluginPlatform.instance.openUsageAccessSettings();
  }
}

