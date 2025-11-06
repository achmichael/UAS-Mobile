import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:app_limiter/core/common/limit_utils.dart';
import 'package:app_limiter/services/usage_stats_service.dart';
import 'package:permission_handler/permission_handler.dart';

const String appLimiterNotificationChannelId = 'app_limiter_notifications';
const String appLimitReachedEvent = 'app_limit_reached';
const String appUnblockedEvent = 'app_unblocked';
const _notificationId = 888;

@pragma('vm:entry-point')
Future<void> initializeService() async {
  await Permission.notification.request();

  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      autoStartOnBoot: true,
      notificationChannelId: appLimiterNotificationChannelId,
      foregroundServiceNotificationId: _notificationId,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  print('onstart started');

  final usageStatsService = UsageStatsService();
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'App Limiter Running',
      content: 'Monitoring usage...',
    );
  }

  service.on('stop').listen((event) => service.stopSelf());

  final Set<String> blockedApps = {};

  Timer.periodic(const Duration(seconds: 1), (timer) async {
    try {
      final limitsByKey = await _fetchLimits();
      print('limitsByKey: $limitsByKey');
      if (limitsByKey.isEmpty) {
        blockedApps.clear();
        return;
      }

      final foregroundApp = await usageStatsService.getCurrentForegroundApp();
      print('foregroundApp: $foregroundApp');
      if (foregroundApp == null || foregroundApp.isEmpty) return;

      final limit = findLimitMinutesForApp(
        limitsByKey,
        packageName: foregroundApp,
      );

      print('limit app: $limit');

      if (limit == null) return;

      final todayMinutes = await usageStatsService.getAppUsageToday(foregroundApp);

      print('todayMinutes: $todayMinutes');
      if (todayMinutes >= limit) {
        if (!blockedApps.contains(foregroundApp)) {
          blockedApps.add(foregroundApp);          
          service.invoke(appLimitReachedEvent, {
            'appName': foregroundApp,
            'limitMinutes': limit,
            'usageMinutes': todayMinutes,
          });
        }
      } else {
        if (blockedApps.contains(foregroundApp)) {
          blockedApps.remove(foregroundApp);
          service.invoke(appUnblockedEvent, {
            'appName': foregroundApp,
          });
          print('[AppMonitor] App unblocked: $foregroundApp');
        }
      }
    } catch (_) {}
  });
}

Future<Map<String, int>> _fetchLimits() async {
  return await fetchNormalizedLimits();
}
