import 'package:app_limiter/screens/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/overlay_service.dart';
import 'core/common/app.dart';
import 'screens/get_started.dart';
import 'screens/login.dart';
import 'screens/register.dart';
import 'screens/limits.dart';
import 'screens/profile.dart';
import 'core/common/route_transitions.dart';
import 'services/app_monitor_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initializeBlockApp();
  final service = FlutterBackgroundService();
  final overlayService = OverlayService();
  final notifications = FlutterLocalNotificationsPlugin();
  await _setupNotificationChannel(notifications);

  service.on(appLimitReachedEvent).listen((event) async {
    final appName = _readString(event, 'appName');
    if (appName == null) return;

    final limitMinutes = _readInt(event, 'limitMinutes');
    final usageMinutes = _readInt(event, 'usageMinutes');
    print('[AppMonitor][Main] Limit reached for $appName: ${usageMinutes ?? '-'} / ${limitMinutes ?? '-'} minutes');

    await setBlockApp(appName);
    await overlayService.showCustomOverlay(appName);

    final notificationBody = limitMinutes != null
        ? '$appName has reached its $limitMinutes minute limit!'
        : '$appName has reached its usage limit!';

    await notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      'App Blocked',
      notificationBody,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          appLimiterNotificationChannelId,
          'App Limiter',
          ongoing: true,
          importance: Importance.high,
          priority: Priority.high
        ),
      ),
    );
  });

  service.on(appUnblockedEvent).listen((event) async {
    final appName = _readString(event, 'appName');
    if (appName == null) return;

    print('[AppMonitor][Main] Unblocking app: $appName');
    await unblockApp(appName);
  });
  
  await initializeService();
  
  runApp(const MyApp());
}

Future<void> _setupNotificationChannel(FlutterLocalNotificationsPlugin notifications) async {
  const channel = AndroidNotificationChannel(
    appLimiterNotificationChannelId,
    'App Limiter Service',
    description: 'Monitors and limits app usage',
    importance: Importance.low,
  );

  final androidNotifications = notifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  await androidNotifications?.createNotificationChannel(channel);
}

String? _readString(dynamic event, String key) {
  if (event is Map) {
    final value = event[key];
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }
  return null;
}

int? _readInt(dynamic event, String key) {
  if (event is Map) {
    final value = event[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
  }
  return null;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return RouteTransitions.fadeTransition(
              builder: (context) => const GetStarted(),
              settings: settings,
            );
          case '/login':
            return RouteTransitions.slideTransition(
              builder: (context) => const LoginScreen(),
              settings: settings,
            );
          case '/register':
            return RouteTransitions.slideTransition(
              builder: (context) => const CreateAccount(),
              settings: settings,
            );
          case '/dashboard':
            return RouteTransitions.bottomNavTransition(
              builder: (context) => const Dashboard(),
              settings: settings,
            );
          case '/limits':
            return RouteTransitions.bottomNavTransition(
              builder: (context) => const LimitsScreen(),
              settings: settings,
            );
          case '/profile':
            return RouteTransitions.bottomNavTransition(
              builder: (context) => const ProfileScreen(),
              settings: settings,
            );
          default:
            return RouteTransitions.fadeTransition(
              builder: (context) => const GetStarted(),
              settings: settings,
            );
        }
      },
    );
  }
}
