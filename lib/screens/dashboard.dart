import 'package:app_limiter/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:progress_bar/progress_bar.dart';
import 'package:app_limiter/core/common/app.dart';
import 'package:app_limiter/components/appbar.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  void initState() {
    super.initState();
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
    );
  }
}
