import 'package:app_limiter/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:app_limiter/types/entities.dart';
import 'package:app_limiter/core/common/app.dart';
import 'package:app_limiter/components/appbar.dart';
import 'package:app_limiter/core/common/screen_time.dart';
import 'package:app_limiter/components/list_item.dart';
import 'package:app_limiter/components/screen_time_bar.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List<AppUsageWithIcon> apps = [];
  Duration screenTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadAppUsage();
    (() async {
      await requestScreenTimePermission();
      final result = await getScreenTimeToday();
      setState(() {
        screenTime = result;
      });
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
      backgroundColor: AppColors.darkNavy,
      appBar: CustomAppBar(
        title: 'Dashboard',
        onSettingsPressed: () {

        },
        backgroundColor: AppColors.darkNavy,
      ),
      body: Center(
        child: Column(
          children: [
            ScreenTimeBar(screenTime: screenTime),
            Expanded(child: ListItem(items: apps)),
          ],
        ),
      ),
    );
  }
}
