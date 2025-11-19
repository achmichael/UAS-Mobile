import 'package:app_limiter/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:app_limiter/types/entities.dart';
import 'package:app_limiter/core/common/app.dart';
import 'package:app_limiter/components/appbar.dart';
import 'package:app_limiter/core/common/screen_time.dart';
import 'package:app_limiter/components/list_item.dart';
import 'package:app_limiter/components/screen_time_bar.dart';
import 'package:app_limiter/core/common/navigation_helper.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List<AppUsageWithIcon> apps = [];
  Duration screenTime = Duration.zero;
  int _currentIndex = 0;

  
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
    print('installedApps: $installedApps');
    setState(() {
      apps = installedApps;
    });
  }

  void _onTabTapped(int index) {
    if (index == 0) {
      if (_currentIndex != 0) {
        setState(() {
          _currentIndex = 0;
        });
      }
    } else if (index == 1) {
      context.navigateToNamed('/limits');
    } else if (index == 2) {
      context.navigateToNamed('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: CustomAppBar(
        title: 'Dashboard',
        onSettingsPressed: () {},
        backgroundColor: AppColors.darkNavy,
      ),
      body: Column(
        children: [
          ScreenTimeBar(screenTime: screenTime),
          Expanded(child: ListItem(items: apps)),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.navyTone.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.muted,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              items: const [
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4.0),
                    child: Icon(Icons.home_outlined),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 4.0),
                    child: Icon(Icons.home),
                  ),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4.0),
                    child: Icon(Icons.timer_outlined),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 4.0),
                    child: Icon(Icons.timer),
                  ),
                  label: 'Limits',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4.0),
                    child: Icon(Icons.person_outline),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 4.0),
                    child: Icon(Icons.person),
                  ),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
