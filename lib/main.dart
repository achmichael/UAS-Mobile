import 'package:app_limiter/screens/dashboard.dart';
import 'package:flutter/material.dart';
import 'screens/get_started.dart';
import 'screens/login.dart';
import 'screens/register.dart';
import 'screens/limits.dart';
import 'screens/profile.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // hilangkan banner debug
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const GetStarted(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const CreateAccount(),
        '/dashboard': (context) => const Dashboard(),
        '/limits': (context) => const LimitsScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
