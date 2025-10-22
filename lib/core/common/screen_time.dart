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
    await openUsageAccessSettings();
  }
}

Future<void> openUsageAccessSettings() async {
  try {
    await platform.invokeMethod('openUsageAccessSettings');
  } on PlatformException catch (e) {
    print('Failed to open settings: ${e.message}');
  }
}