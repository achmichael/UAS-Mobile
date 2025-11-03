import 'package:app_limiter/screens/dashboard.dart';
import 'package:flutter/material.dart';
import 'screens/get_started.dart';
import 'screens/login.dart';
import 'screens/register.dart';
import 'screens/limits.dart';
import 'screens/profile.dart';
import 'core/common/route_transitions.dart';
import 'services/app_monitor_service.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize and start the background monitoring service
  await AppMonitorService.initializeService();
  
  runApp(const MyApp());
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
        // Route definitions dengan custom transitions
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
