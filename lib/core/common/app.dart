import 'package:app_limiter/components/overlay.dart';
import 'package:app_limiter/core/common/app_usage.dart';
import 'package:app_limiter/types/entities.dart';
import 'package:app_usage/app_usage.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:collection/collection.dart';
import 'package:block_app/block_app.dart';
import 'package:flutter/material.dart';

// Global instance of BlockApp
final BlockApp blockAppInstance = BlockApp();

Future<List<AppInfo>> getInstalledApps() async {
  List<AppInfo> apps = await InstalledApps.getInstalledApps(
    excludeSystemApps: false,
    excludeNonLaunchableApps: false,
    withIcon: true,
  );

  return apps;
}

/// Get app name from package name
/// Returns the app name or package name if not found
Future<String> getAppNameFromPackage(String packageName) async {
  try {
    final apps = await getInstalledApps();
    final app = apps.firstWhereOrNull((app) => app.packageName == packageName);
    return app?.name ?? packageName;
  } catch (e) {
    print('[AppName] Error getting app name for $packageName: $e');
    return packageName;
  }
}

Future<List<AppUsageWithIcon>> getAppUsagesWithIcons() async {
  DateTime endDate = DateTime.now();
  DateTime startDate = endDate.subtract(const Duration(hours: 24));

  List<AppUsageInfo> usageInfos = await AppUsageUtils.getUsageData(
    startDate: startDate,
    endDate: endDate,
  );
  List<AppInfo> installedApps = await getInstalledApps();

  final List<AppUsageWithIcon> merged = [];

  for (var usage in usageInfos) {
    final matchedApp = installedApps.firstWhereOrNull(
      (app) => app.packageName == usage.packageName,
    );

    if (matchedApp == null) continue;

    merged.add((
      packageName: usage.packageName,
      appName: matchedApp.name,
      usage: usage.usage,
      icon: matchedApp.icon,
    ));
  }

  return merged;
}

/// Block app when it reaches the usage limit
/// This method should be called from the monitoring service
Future<void> setBlockApp(String packageName) async {
  try {
    print('[BlockApp] Blocking app: $packageName');
    await blockAppInstance.blockApp(packageName);
    print('[BlockApp] Successfully blocked: $packageName');
  } catch (e) {
    print('[BlockApp] Error blocking app: $e');
  }
}

/// Unblock a previously blocked app
Future<void> unblockApp(String packageName) async {
  try {
    print('[BlockApp] Unblocking app: $packageName');
    await blockAppInstance.unblockApp(packageName);
    print('[BlockApp] Successfully unblocked: $packageName');
  } catch (e) {
    print('[BlockApp] Error unblocking app: $e');
  }
}

/// Initialize BlockApp with custom configuration
/// This should be called once during app startup in main.dart
Future<void> initializeBlockApp() async {
  try {
    print('[BlockApp] Initializing BlockApp...');
    
    await blockAppInstance.initialize(
      config: AppBlockConfig(
        defaultMessage: 'This app has been blocked',
        overlayBackgroundColor: Colors.black87,
        overlayTextColor: Colors.white,
        actionButtonText: 'Close',
        autoStartService: true,
        customOverlayBuilder: (context, packageName) {
          return overlay;
        },
      ),
    );
    
    print('[BlockApp] BlockApp initialized successfully');
  } catch (e) {
    print('[BlockApp] Error initializing BlockApp: $e');
  }
}
