import 'package:app_limiter/core/constants/app_colors.dart';
import 'package:app_usage/app_usage.dart';
import 'package:flutter/material.dart';
import 'package:app_limiter/types/entities.dart';
import 'package:installed_apps/app_info.dart';
import 'package:progress_bar/progress_bar.dart';
import 'package:app_limiter/core/common/app.dart';
import 'package:app_limiter/components/appbar.dart';
import 'package:app_limiter/core/common/app_usage.dart';
import 'package:app_limiter/core/common/screen_time.dart';
import 'package:app_limiter/components/list_item.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List<AppUsageWithIcon> apps = [];
  @override
  void initState() {
    super.initState();
    _loadAppUsage();
    (() async {
      await requestScreenTimePermission();
    })();
  }

  Future<void> _loadAppUsage() async {
    final installedApps = await getAppUsagesWithIcons();
    setState(() {
      apps = installedApps;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: CustomAppBar(
        title: 'Dashboard',
        onSettingsPressed: () {
          print('Settings di klik');
        },
      ),
      body: Center(child: ListItem(items: apps)),
    );
  }
}
