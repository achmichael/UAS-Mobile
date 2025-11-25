import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:app_limiter/core/common/limit_utils.dart';
import 'package:app_limiter/services/usage_stats_service.dart';
import 'package:app_limiter_plugin/app_limiter_plugin.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:installed_apps/installed_apps.dart';

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

  print('[AppMonitor] ========== SERVICE STARTED ==========');

  final usageStatsService = UsageStatsService();
  final overlayPlugin = AppLimiterPlugin();
  
  // Check overlay permission at service start
  try {
    final hasOverlayPermission = await overlayPlugin.hasOverlayPermission();
    print('[AppMonitor] Overlay permission status: $hasOverlayPermission');
    
    if (!hasOverlayPermission) {
      print('[AppMonitor] ⚠️ WARNING: Overlay permission not granted!');
      print('[AppMonitor] Please grant overlay permission in app settings');
    } else {
      print('[AppMonitor] ✅ Overlay permission granted');
    }
  } catch (e) {
    print('[AppMonitor] ❌ Error checking overlay permission: $e');
  }
  
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'App Limiter Running',
      content: 'Monitoring usage...',
    );
    
    // Set notification with icon
    service.setAsForegroundService();
  }

  service.on('stop').listen((event) => service.stopSelf());

  final Set<String> blockedApps = {};
  
  print('[AppMonitor] Starting monitoring loop...');

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

      // IMPORTANT: Don't block the App Limiter app itself!
      if (foregroundApp == 'com.example.app_limiter') {
        print('[AppMonitor] ⚠️ Skipping - cannot block App Limiter itself!');
        // Remove from blocked list if it was added by mistake
        if (blockedApps.contains(foregroundApp)) {
          blockedApps.remove(foregroundApp);
          try {
            await overlayPlugin.hideOverlay();
          } catch (e) {
            print('[AppMonitor] Error hiding overlay: $e');
          }
        }
        return;
      }

      final limit = findLimitMinutesForApp(
        limitsByKey,
        packageName: foregroundApp,
      );

      print('limit app: $limit');

      if (limit == null) return;

      final todayMinutes = await usageStatsService.getAppUsageToday(foregroundApp);

      print('todayMinutes: $todayMinutes');
      print('[AppMonitor] Comparison: $todayMinutes >= $limit = ${todayMinutes >= limit}');
      
      if (todayMinutes >= limit) {
        print('⚠️ App limit reached for duration $foregroundApp');
        print('Already blocked apps: $blockedApps');
        print('Is $foregroundApp already blocked? ${blockedApps.contains(foregroundApp)}');
        
        // Get app name for display
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
          print('🔒 Blocking app: $foregroundApp');
          print('Blocked apps after adding: $blockedApps');
          
          
          try {
            print('📱 Calling showCustomOverlay for: $displayAppName ($foregroundApp)');
            await overlayPlugin.showCustomOverlay(displayAppName, packageName: foregroundApp);
            print('✅ showCustomOverlay completed successfully');
          } catch (e) {
            print('❌ [AppMonitor] Error showing overlay: $e');
            print('Stack trace: ${StackTrace.current}');
          }
          
          // Invoke event to notify main app
          try {
            print('📢 Invoking appLimitReachedEvent');
            service.invoke(appLimitReachedEvent, {
              'appName': foregroundApp,
              'appDisplayName': displayAppName,
              'limitMinutes': limit,
              'usageMinutes': todayMinutes,
            });
            print('✅ Event invoked successfully');
          } catch (e) {
            print('❌ Error invoking event: $e');
          }
        } else {
          // App is already blocked but still in foreground - ensure overlay is showing
          print('ℹ️ $foregroundApp already blocked, ensuring overlay is visible...');
          try {
            // Re-show overlay to ensure it's still visible
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
          print('[AppMonitor] App unblocked: $foregroundApp');
        }
      }
    } catch (e) {
      print('[AppMonitor] Error in monitoring loop: $e');
    }
  });
}

Future<Map<String, int>> _fetchLimits() async {
  return await fetchNormalizedLimits();
}