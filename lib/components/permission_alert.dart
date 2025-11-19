import 'package:flutter/material.dart';
import 'package:app_limiter/services/overlay_service.dart';
import 'package:app_limiter/services/usage_stats_service.dart';

/// Alert dialog to prompt users to grant overlay permission
class PermissionAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onGrantPressed;

  const PermissionAlertDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onGrantPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This permission is required for the app to function properly.',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Later'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onGrantPressed();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Grant Permission'),
        ),
      ],
    );
  }
}

/// Show permission request dialog for overlay permission
Future<void> showOverlayPermissionDialog(BuildContext context) async {
  final overlayService = OverlayService();
  
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => PermissionAlertDialog(
      title: 'Display Over Other Apps',
      message: 'App Limiter needs permission to display over other apps to show blocking screens when app limits are reached.\n\nPlease enable this permission in the next screen.',
      onGrantPressed: () async {
        await overlayService.requestOverlayPermission();
        
        // Wait and check if permission was granted
        await Future.delayed(const Duration(seconds: 2));
        final hasPermission = await overlayService.hasOverlayPermission();
        
        if (!hasPermission && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Please grant overlay permission for app blocking to work'),
              duration: Duration(seconds: 4),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
    ),
  );
}

/// Show permission request dialog for usage stats permission
Future<void> showUsageStatsPermissionDialog(BuildContext context) async {
  final usageStatsService = UsageStatsService();
  
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => PermissionAlertDialog(
      title: 'Usage Access',
      message: 'App Limiter needs permission to access app usage statistics to monitor and limit your app usage.\n\nPlease find "App Limiter" in the list and enable usage access.',
      onGrantPressed: () async {
        await usageStatsService.openUsageAccessSettings();
        
        // Wait and check if permission was granted
        await Future.delayed(const Duration(seconds: 2));
        final hasPermission = await usageStatsService.hasUsageAccessPermission();
        
        if (!hasPermission && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Please grant usage access permission for app monitoring to work'),
              duration: Duration(seconds: 4),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
    ),
  );
}

/// Check and request all required permissions
Future<void> checkAndRequestAllPermissions(BuildContext context) async {
  final overlayService = OverlayService();
  final usageStatsService = UsageStatsService();
  
  // Check usage stats permission
  final hasUsageStats = await usageStatsService.hasUsageAccessPermission();
  if (!hasUsageStats && context.mounted) {
    await showUsageStatsPermissionDialog(context);
    await Future.delayed(const Duration(milliseconds: 500));
  }
  
  // Check overlay permission
  final hasOverlay = await overlayService.hasOverlayPermission();
  if (!hasOverlay && context.mounted) {
    await showOverlayPermissionDialog(context);
  }
}
