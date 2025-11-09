// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing


import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:app_limiter_plugin/app_limiter_plugin.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('hasOverlayPermission test', (WidgetTester tester) async {
    final AppLimiterPlugin plugin = AppLimiterPlugin();
    final bool hasPermission = await plugin.hasOverlayPermission();
    // Should return a boolean value
    expect(hasPermission, isA<bool>());
  });

  testWidgets('hasUsageAccessPermission test', (WidgetTester tester) async {
    final AppLimiterPlugin plugin = AppLimiterPlugin();
    final bool hasPermission = await plugin.hasUsageAccessPermission();
    // Should return a boolean value
    expect(hasPermission, isA<bool>());
  });

  testWidgets('getAllAppsUsageToday test', (WidgetTester tester) async {
    final AppLimiterPlugin plugin = AppLimiterPlugin();
    final Map<String, int> usage = await plugin.getAllAppsUsageToday();
    // Should return a map
    expect(usage, isA<Map<String, int>>());
  });
}
