import 'package:flutter/material.dart';
import 'package:app_limiter/services/usage_stats_service.dart';
import 'package:app_limiter/services/overlay_service.dart';

/// Widget to check and request required permissions for app monitoring
/// This should be shown on first launch or when permissions are not granted
class PermissionsHelper {
  static final UsageStatsService _usageStatsService = UsageStatsService();
  static final OverlayService _overlayService = OverlayService();

  /// Check if all required permissions are granted
  static Future<bool> hasAllPermissions() async {
    final hasUsageAccess = await _usageStatsService.hasUsageAccessPermission();
    final hasOverlay = await _overlayService.hasOverlayPermission();
    return hasUsageAccess && hasOverlay;
  }

  /// Show a dialog to guide user through permission setup
  static Future<void> showPermissionDialog(BuildContext context) async {
    final hasUsageAccess = await _usageStatsService.hasUsageAccessPermission();
    final hasOverlay = await _overlayService.hasOverlayPermission();

    if (!context.mounted) return;

    if (!hasUsageAccess || !hasOverlay) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Required Permissions'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'App Limiter needs the following permissions to work properly:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (!hasUsageAccess) ...[
                    const Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Usage Access',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Padding(
                      padding: EdgeInsets.only(left: 32),
                      child: Text(
                        'To monitor app usage and enforce time limits',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (!hasOverlay) ...[
                    const Row(
                      children: [
                        Icon(Icons.layers, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Display Over Other Apps',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Padding(
                      padding: EdgeInsets.only(left: 32),
                      child: Text(
                        'To show blocking screen when time limit is reached',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _requestPermissionsSequentially(context);
                },
                child: const Text('Grant Permissions'),
              ),
            ],
          );
        },
      );
    }
  }

  /// Request permissions one by one
  static Future<void> _requestPermissionsSequentially(BuildContext context) async {
    // First check and request usage access
    final hasUsageAccess = await _usageStatsService.hasUsageAccessPermission();
    if (!hasUsageAccess) {
      if (!context.mounted) return;
      
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Usage Access Permission'),
            content: const Text(
              'Please find "App Limiter" in the list and enable usage access.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _usageStatsService.openUsageAccessSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          );
        },
      );
    }

    // Then check and request overlay permission
    await Future.delayed(const Duration(seconds: 1)); // Small delay
    final hasOverlay = await _overlayService.hasOverlayPermission();
    if (!hasOverlay && context.mounted) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Display Over Other Apps'),
            content: const Text(
              'Please allow "App Limiter" to display over other apps.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _overlayService.requestOverlayPermission();
                },
                child: const Text('Open Settings'),
              ),
            ],
          );
        },
      );
    }
  }

  /// Check permissions and show dialog if needed
  /// Call this in your main screen's initState
  static Future<void> checkAndRequestPermissions(BuildContext context) async {
    final hasAll = await hasAllPermissions();
    if (!hasAll && context.mounted) {
      // Small delay to ensure UI is ready
      await Future.delayed(const Duration(milliseconds: 500));
      if (context.mounted) {
        await showPermissionDialog(context);
      }
    }
  }
}
