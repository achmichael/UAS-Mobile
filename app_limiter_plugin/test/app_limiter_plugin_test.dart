import 'package:flutter_test/flutter_test.dart';
import 'package:app_limiter_plugin/app_limiter_plugin.dart';
import 'package:app_limiter_plugin/app_limiter_plugin_platform_interface.dart';
import 'package:app_limiter_plugin/app_limiter_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAppLimiterPluginPlatform
    with MockPlatformInterfaceMixin
    implements AppLimiterPluginPlatform {

  @override
  Future<void> showCustomOverlay(String appName) => Future.value();

  @override
  Future<void> hideOverlay() => Future.value();

  @override
  Future<bool> hasOverlayPermission() => Future.value(true);

  @override
  Future<void> requestOverlayPermission() => Future.value();

  @override
  Future<String?> getCurrentForegroundApp() => Future.value('com.test.app');

  @override
  Future<int> getAppUsageToday(String packageName) => Future.value(3600000);

  @override
  Future<Map<String, int>> getAllAppsUsageToday() => Future.value({'com.test.app': 3600000});

  @override
  Future<bool> hasUsageAccessPermission() => Future.value(true);

  @override
  Future<void> openUsageAccessSettings() => Future.value();
}

void main() {
  final AppLimiterPluginPlatform initialPlatform = AppLimiterPluginPlatform.instance;

  test('$MethodChannelAppLimiterPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAppLimiterPlugin>());
  });

  test('hasOverlayPermission returns true', () async {
    AppLimiterPlugin appLimiterPlugin = AppLimiterPlugin();
    MockAppLimiterPluginPlatform fakePlatform = MockAppLimiterPluginPlatform();
    AppLimiterPluginPlatform.instance = fakePlatform;

    expect(await appLimiterPlugin.hasOverlayPermission(), true);
  });

  test('getCurrentForegroundApp returns package name', () async {
    AppLimiterPlugin appLimiterPlugin = AppLimiterPlugin();
    MockAppLimiterPluginPlatform fakePlatform = MockAppLimiterPluginPlatform();
    AppLimiterPluginPlatform.instance = fakePlatform;

    expect(await appLimiterPlugin.getCurrentForegroundApp(), 'com.test.app');
  });

  test('getAppUsageToday returns milliseconds', () async {
    AppLimiterPlugin appLimiterPlugin = AppLimiterPlugin();
    MockAppLimiterPluginPlatform fakePlatform = MockAppLimiterPluginPlatform();
    AppLimiterPluginPlatform.instance = fakePlatform;

    expect(await appLimiterPlugin.getAppUsageToday('com.test.app'), 3600000);
  });
}
