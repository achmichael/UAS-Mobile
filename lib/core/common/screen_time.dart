import 'package:screen_time/screen_time.dart';
import 'package:flutter/services.dart';

const platform = MethodChannel('com.example.app_limiter');

Future<void> requestScreenTimePermission() async {
  final ScreenTime screenTime = ScreenTime();
  final status = await screenTime.permissionStatus();
  print('is enabled: $status');

  if (status == ScreenTimePermissionStatus.approved) {
    print('✅ Permission granted');
  } else {
    print('⚠️ Permission not granted — opening settings...');
    // await openUsageAccessSettings();
  }
}

// Future<void> openUsageAccessSettings() async {
//   try {
//     // await platform.invokeMethod('openUsageAccessSettings');
//   } on PlatformException catch (e) {
//     print('Failed to open settings: ${e.message}');
//   }
// }

Future<Duration> getScreenTimeToday() async {
  final ScreenTime screenTime = ScreenTime();

  final status = await screenTime.permissionStatus();
  if (status != ScreenTimePermissionStatus.approved) {
    return Duration.zero;
  }

  try {
    final usageInfo = await screenTime.appUsageData();

    if (usageInfo.isEmpty) {
      return Duration.zero;
    }

    Duration totalDuration = Duration.zero;

    for (var app in usageInfo) {
      if (app.usageTime != null) {
        totalDuration += app.usageTime!;
      }
    }

    return totalDuration;
  } catch (e) {
    return Duration.zero;
  }
}

Future<Duration?> getScreenTime({
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final ScreenTime screenTime = ScreenTime();

  final status = await screenTime.permissionStatus();
  if (status != ScreenTimePermissionStatus.approved) {
    return null;
  }

  try {
    final usageInfo = await screenTime.appUsageData();

    if (usageInfo.isEmpty) {
      return Duration.zero;
    }

    Duration totalDuration = Duration.zero;

    for (var app in usageInfo) {
      if (app.usageTime != null) {
        totalDuration += app.usageTime!;
      }
    }

    return totalDuration;
  } catch (e) {
    return null;
  }
}
