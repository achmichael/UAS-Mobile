import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:app_limiter/core/common/fetcher.dart';
import 'package:app_limiter/services/usage_stats_service.dart';
import 'package:app_limiter/services/overlay_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Main Background Service for App Monitoring
/// This service runs continuously in the background to monitor app usage
/// and enforce time limits even when the Flutter UI is closed
class AppMonitorService {
  static const String _notificationChannelId = 'app_limiter_notifications';
  static const int _checkInterval = 1000; // Check every 1 second
  
  /// Initialize and configure the background service
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();
    
    // Setup notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _notificationChannelId,
      'App Limiter Service',
      description: 'Monitors app usage and enforces time limits',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Configure the service
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: _notificationChannelId,
        initialNotificationTitle: 'App Limiter',
        initialNotificationContent: 'Monitoring app usage...',
        foregroundServiceNotificationId: 888,
        autoStartOnBoot: true,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    // Start the service
    service.startService();
  }

  /// iOS background handler
  @pragma('vm:entry-point')
  static bool onIosBackground(ServiceInstance service) {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  /// Main service entry point
  /// This function runs in a separate isolate and continuously monitors apps
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Initialize required services
    final usageStatsService = UsageStatsService();
    final overlayService = OverlayService();
    
    // Keep track of blocked apps to avoid repeated overlays
    final Set<String> currentlyBlockedApps = {};
    
    // Main monitoring loop - runs continuously
    Timer.periodic(const Duration(milliseconds: _checkInterval), (timer) async {
      try {
        if (service is AndroidServiceInstance) {
          if (await service.isForegroundService()) {
            // Update notification to show service is active
            service.setForegroundNotificationInfo(
              title: "App Limiter Active",
              content: "Monitoring ${currentlyBlockedApps.length} blocked app(s)",
            );
          }
        }

        // Step 1: Fetch limited apps from the server
        final limitedApps = await _fetchLimitedApps();
        
        if (limitedApps.isEmpty) {
          // No apps to monitor, clear blocked apps
          currentlyBlockedApps.clear();
          return;
        }

        // Step 2: Get the current foreground app
        final foregroundApp = await usageStatsService.getCurrentForegroundApp();
        
        if (foregroundApp == null || foregroundApp.isEmpty) {
          return;
        }

        // Step 3: Check if foreground app is in limited apps list
        final limitedApp = limitedApps.firstWhere(
          (app) => app['appName'] == foregroundApp,
          orElse: () => {},
        );

        if (limitedApp.isEmpty) {
          // Current app is not limited, remove from blocked list if present
          currentlyBlockedApps.remove(foregroundApp);
          return;
        }

        // Step 4: Get today's usage for this app
        final todayUsageMinutes = await usageStatsService.getAppUsageToday(foregroundApp);
        final limitMinutes = limitedApp['limitMinutes'] as int;

        // Step 5: Check if usage exceeds limit
        if (todayUsageMinutes >= limitMinutes) {
          // App has exceeded its limit
          if (!currentlyBlockedApps.contains(foregroundApp)) {
            // First time blocking this app in this session
            print('[AppMonitor] Blocking app: $foregroundApp (${todayUsageMinutes}min / ${limitMinutes}min)');
            
            // Show the blocking overlay
            await overlayService.showCustomOverlay(foregroundApp);
            
            // Add to blocked apps set
            currentlyBlockedApps.add(foregroundApp);
            
            // Send notification
            _sendNotification(
              'App Blocked',
              'You have reached your daily limit for $foregroundApp',
            );
          }
          // If already blocked, the overlay should still be showing
        } else {
          // App is within limits, remove from blocked list
          currentlyBlockedApps.remove(foregroundApp);
        }

      } catch (e) {
        print('[AppMonitor] Error in monitoring loop: $e');
        // Continue running even if there's an error
      }
    });
  }

  /// Fetch limited apps from the server
  /// Returns list of {appName: String, limitMinutes: int}
  static Future<List<Map<String, dynamic>>> _fetchLimitedApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        print('[AppMonitor] No auth token found');
        return [];
      }

      final response = await http.get(
        Uri.parse('${Fetcher.baseUrl}/limits'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Handle different response formats
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else if (data is Map && data['limits'] != null) {
          return List<Map<String, dynamic>>.from(data['limits']);
        }
        
        return [];
      } else {
        print('[AppMonitor] Failed to fetch limits: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[AppMonitor] Error fetching limited apps: $e');
      return [];
    }
  }

  /// Send a notification to the user
  static Future<void> _sendNotification(String title, String body) async {
    try {
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        _notificationChannelId,
        'App Limiter',
        channelDescription: 'App usage limit notifications',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'ticker',
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        platformChannelSpecifics,
      );
    } catch (e) {
      print('[AppMonitor] Error sending notification: $e');
    }
  }

  /// Stop the background service
  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }

  /// Check if service is running
  static Future<bool> isServiceRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }
}
