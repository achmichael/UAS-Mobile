import 'package:app_limiter_plugin/app_limiter_plugin.dart';

/// Service to manage full-screen overlay for blocking apps
/// Uses native Android System Alert Window to block app access
class OverlayService {
  final _plugin = AppLimiterPlugin();

  /// Show a full-screen blocking overlay for the specified app
  /// This prevents user from interacting with the blocked app
  /// 
  /// [appName] - The display name of the app being blocked
  /// [packageName] - The package name to remove from recents when Cancel is pressed
  Future<void> showCustomOverlay(String appName, {String? packageName}) async {
    try {
      await _plugin.showCustomOverlay(appName, packageName: packageName);
      print('[Overlay] Showing overlay for: $appName (package: $packageName)');
    } catch (e) {
      print('[Overlay] Error showing overlay: $e');
    }
  }

  /// Hide the currently displayed overlay
  Future<void> hideOverlay() async {
    try {
      await _plugin.hideOverlay();
      print('[Overlay] Overlay hidden');
    } catch (e) {
      print('[Overlay] Error hiding overlay: $e');
    }
  }

  /// Check if overlay permission is granted
  Future<bool> hasOverlayPermission() async {
    try {
      final bool hasPermission = await _plugin.hasOverlayPermission();
      return hasPermission;
    } catch (e) {
      print('[Overlay] Error checking overlay permission: $e');
      return false;
    }
  }

  /// Open system settings to grant overlay permission
  Future<void> requestOverlayPermission() async {
    try {
      await _plugin.requestOverlayPermission();
    } catch (e) {
      print('[Overlay] Error requesting overlay permission: $e');
    }
  }

  /// Check if accessibility permission is granted
  Future<bool> hasAccessibilityPermission() async {
    try {
      final bool hasPermission = await _plugin.hasAccessibilityPermission();
      return hasPermission;
    } catch (e) {
      print('[Overlay] Error checking accessibility permission: $e');
      return false;
    }
  }

  /// Open accessibility settings to grant permission
  Future<void> requestAccessibilityPermission() async {
    try {
      await _plugin.requestAccessibilityPermission();
    } catch (e) {
      print('[Overlay] Error requesting accessibility permission: $e');
    }
  }
}
