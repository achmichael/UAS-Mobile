import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'app_limiter_plugin_method_channel.dart';

abstract class AppLimiterPluginPlatform extends PlatformInterface {
  /// Constructs a AppLimiterPluginPlatform.
  AppLimiterPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static AppLimiterPluginPlatform _instance = MethodChannelAppLimiterPlugin();

  /// The default instance of [AppLimiterPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelAppLimiterPlugin].
  static AppLimiterPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AppLimiterPluginPlatform] when
  /// they register themselves.
  static set instance(AppLimiterPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // Overlay methods
  Future<void> showCustomOverlay(String appName) {
    throw UnimplementedError('showCustomOverlay() has not been implemented.');
  }

  Future<void> hideOverlay() {
    throw UnimplementedError('hideOverlay() has not been implemented.');
  }

  Future<bool> hasOverlayPermission() {
    throw UnimplementedError('hasOverlayPermission() has not been implemented.');
  }

  Future<void> requestOverlayPermission() {
    throw UnimplementedError('requestOverlayPermission() has not been implemented.');
  }

  // Usage Stats methods
  Future<String?> getCurrentForegroundApp() {
    throw UnimplementedError('getCurrentForegroundApp() has not been implemented.');
  }

  Future<int> getAppUsageToday(String packageName) {
    throw UnimplementedError('getAppUsageToday() has not been implemented.');
  }

  Future<Map<String, int>> getAllAppsUsageToday() {
    throw UnimplementedError('getAllAppsUsageToday() has not been implemented.');
  }

  Future<bool> hasUsageAccessPermission() {
    throw UnimplementedError('hasUsageAccessPermission() has not been implemented.');
  }

  Future<void> openUsageAccessSettings() {
    throw UnimplementedError('openUsageAccessSettings() has not been implemented.');
  }
}
