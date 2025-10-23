import 'package:app_limiter/core/common/app_usage.dart';
import 'package:app_limiter/types/entities.dart';
import 'package:app_usage/app_usage.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:collection/collection.dart'; // Tambahkan import ini

Future<List<AppInfo>> getInstalledApps() async {
  List<AppInfo> apps = await InstalledApps.getInstalledApps(
    excludeSystemApps: true,
    excludeNonLaunchableApps: false,
    withIcon: true,
  );

  return apps;
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

    // Jika package name tidak cocok, lewati
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