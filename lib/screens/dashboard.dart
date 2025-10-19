import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:progress_bar/progress_bar.dart';
import 'package:app_limiter/common/app.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  void initState() {
    super.initState();
    loadApps();
  }

  void loadApps() async {
    List<AppInfo> installedApps = await getInstalledApps();
    for (var app in installedApps) {
      print('App: ${app.name}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard"),
        actionsIconTheme: IconThemeData(),
      ),
    );
  }
}
