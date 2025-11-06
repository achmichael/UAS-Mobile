import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:app_limiter/core/common/token_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:http/http.dart' as http;
import 'package:app_limiter/services/usage_stats_service.dart';
import 'package:app_limiter/core/common/fetcher.dart';
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
      final limitedApps = await _fetchLimits();
      if (limitedApps.isEmpty) {
        blockedApps.clear();
        return;
      }

      final foregroundApp = await usageStatsService.getCurrentForegroundApp();
      print('foregroundApp: $foregroundApp');
      if (foregroundApp == null || foregroundApp.isEmpty) return;

      final match = limitedApps.firstWhere(
        (a) => a['appName'] == foregroundApp,
        orElse: () => {},
      );

      print('match: $match');
      if (match.isEmpty) return;

      final todayMinutes = await usageStatsService.getAppUsageToday(foregroundApp);
      final limit = match['limitMinutes'];

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

Future<List<Map<String, dynamic>>> _fetchLimits() async {
  try {
    final prefs = TokenManager.instance;
    final token = await prefs.getRefreshToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('${Fetcher.baseUrl}/limits'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);
    if (data is List) return List<Map<String, dynamic>>.from(data);
    if (data is Map && data['data'] != null) return List<Map<String, dynamic>>.from(data['data']);
    if (data is Map && data['limits'] != null) return List<Map<String, dynamic>>.from(data['limits']);

    return [];
  } catch (_) {
    return [];
  }
}
