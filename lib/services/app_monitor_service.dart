import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:app_limiter/core/common/limit_utils.dart';
import 'package:app_limiter/core/common/app.dart';
import 'package:app_limiter/services/usage_stats_service.dart';
import 'package:app_limiter_plugin/app_limiter_plugin.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:app_limiter/core/common/fetcher.dart';

const String appLimiterNotificationChannelId = 'app_limiter_notifications';
const String appLimitReachedEvent = 'app_limit_reached';
const String appUnblockedEvent = 'app_unblocked';
const _notificationId = 888;

@pragma('vm:entry-point')
Future<void> initializeService() async {
  try {
    final status = await Permission.notification.request();
    print('[AppMonitor] Notification permission status: $status');
  } catch (e) {
    print('[AppMonitor] Error requesting notification permission: $e');
    // Continue even if permission request fails
  }

  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      autoStartOnBoot: true,
      notificationChannelId: appLimiterNotificationChannelId,
      foregroundServiceNotificationId: _notificationId,
      initialNotificationTitle: 'App Limiter',
      initialNotificationContent: 'Service is running',
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


  final usageStatsService = UsageStatsService();
  final overlayPlugin = AppLimiterPlugin();
  
  try {
    final hasOverlayPermission = await overlayPlugin.hasOverlayPermission();    
    if (!hasOverlayPermission) {
    } else {
      print('[AppMonitor] ✅ Overlay permission granted');
    }
  } catch (e) {
  }
  
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'App Limiter Running',
      content: 'Monitoring usage...',
    );
    
    service.setAsForegroundService();
  }

  service.on('stop').listen((event) => service.stopSelf());

  final Set<String> blockedApps = {};
  String? lastForegroundApp;
  
  print('[AppMonitor] Starting monitoring loop...');

  Timer.periodic(const Duration(seconds: 1), (timer) async {
    try {
      final limitsByKey = await _fetchLimits();

      final foregroundApp = await usageStatsService.getCurrentForegroundApp();

      if (foregroundApp != lastForegroundApp) {
        if (lastForegroundApp != null && lastForegroundApp!.isNotEmpty) {
          _endUsage(lastForegroundApp!);
        }

        if (foregroundApp != null && foregroundApp.isNotEmpty) {
          _startUsage(foregroundApp);
        }

        lastForegroundApp = foregroundApp;
      }

      if (limitsByKey.isEmpty) {
        blockedApps.clear();
        return;
      }

      if (foregroundApp == null || foregroundApp.isEmpty) return;

      if (foregroundApp == 'com.example.app_limiter') {
        if (blockedApps.contains(foregroundApp)) {
          blockedApps.remove(foregroundApp);
          try {
            await overlayPlugin.hideOverlay();
          } catch (e) {
          }
        }
        return;
      }

      final limit = findLimitMinutesForApp(
        limitsByKey,
        packageName: foregroundApp,
      );


      if (limit == null) return;

      final todayMinutes = await usageStatsService.getAppUsageToday(foregroundApp);

      
      if (todayMinutes >= limit) {
        String displayAppName = foregroundApp;
        try {
          final appInfo = await InstalledApps.getAppInfo(foregroundApp);
          if (appInfo != null) {
             displayAppName = appInfo.name;
          }
        } catch (e) {
          print('[AppMonitor] Error getting app name for $foregroundApp: $e');
        }
        
        if (!blockedApps.contains(foregroundApp)) {
          blockedApps.add(foregroundApp);
          
          // Block app in backend
          try {
            final appData = await getAppByPackage(foregroundApp);
            if (appData != null && appData['_id'] != null) {
              await blockAppInBackend(appData['_id']);
            }
          } catch (e) {
            print('❌ Error blocking app in backend: $e');
          }
          
          try {
            await overlayPlugin.showCustomOverlay(displayAppName, packageName: foregroundApp);
          } catch (e) {
            print('Stack trace: ${StackTrace.current}');
          }
          
          // Invoke event to notify main app
          try {
            service.invoke(appLimitReachedEvent, {
              'appName': foregroundApp,
              'appDisplayName': displayAppName,
              'limitMinutes': limit,
              'usageMinutes': todayMinutes,
            });
          } catch (e) {
            print('❌ Error invoking event: $e');
          }
        } else {
          try {
            await overlayPlugin.showCustomOverlay(displayAppName, packageName: foregroundApp);
          } catch (e) {
            print('❌ Error re-showing overlay: $e');
          }
        }
      } else {
        if (blockedApps.contains(foregroundApp)) {
          blockedApps.remove(foregroundApp);
          
          // Hide overlay using plugin
          try {
            await overlayPlugin.hideOverlay();
          } catch (e) {
            print('[AppMonitor] Error hiding overlay: $e');
          }
          
          service.invoke(appUnblockedEvent, {
            'appName': foregroundApp,
          });
        }
      }
    } catch (e) {
    }
  });
}

Future<Map<String, int>> _fetchLimits() async {
  return await fetchNormalizedLimits();
}

Future<void> _startUsage(String packageName) async {
  try {
    await Fetcher.post('/usage/start', {'package': packageName});
  } catch (e) {
  }
}

Future<void> _endUsage(String packageName) async {
  try {
    await Fetcher.post('/usage/end', {'package': packageName});
  } catch (e) {
  }
}