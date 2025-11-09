import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_limiter_plugin/app_limiter_plugin_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelAppLimiterPlugin platform = MethodChannelAppLimiterPlugin();
  const MethodChannel overlayChannel = MethodChannel('com.example.app_limiter_plugin/overlay');
  const MethodChannel usageStatsChannel = MethodChannel('com.example.app_limiter_plugin/usage_stats');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      overlayChannel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'hasOverlayPermission':
            return true;
          case 'showCustomOverlay':
          case 'hideOverlay':
          case 'requestOverlayPermission':
            return null;
          default:
            return null;
        }
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      usageStatsChannel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getCurrentForegroundApp':
            return 'com.test.app';
          case 'getAppUsageToday':
            return 3600000;
          case 'getAllAppsUsageToday':
            return {'com.test.app': 3600000};
          case 'hasUsageAccessPermission':
            return true;
          case 'openUsageAccessSettings':
            return null;
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(overlayChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(usageStatsChannel, null);
  });

  test('hasOverlayPermission returns true', () async {
    expect(await platform.hasOverlayPermission(), true);
  });

  test('getCurrentForegroundApp returns package name', () async {
    expect(await platform.getCurrentForegroundApp(), 'com.test.app');
  });

  test('getAppUsageToday returns milliseconds', () async {
    expect(await platform.getAppUsageToday('com.test.app'), 3600000);
  });

  test('getAllAppsUsageToday returns map', () async {
    final result = await platform.getAllAppsUsageToday();
    expect(result, isA<Map<String, int>>());
    expect(result['com.test.app'], 3600000);
  });

  test('hasUsageAccessPermission returns true', () async {
    expect(await platform.hasUsageAccessPermission(), true);
  });
}
