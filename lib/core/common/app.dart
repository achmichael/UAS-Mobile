import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

Future<List<AppInfo>> getInstalledApps() async {
  List<AppInfo> apps = await InstalledApps.getInstalledApps(
    excludeSystemApps: false,
    excludeNonLaunchableApps: false,
    withIcon: true,
  );

  return apps;
}
