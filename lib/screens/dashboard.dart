import 'package:app_limiter/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:app_limiter/types/entities.dart';
import 'package:app_limiter/core/common/app.dart';
import 'package:app_limiter/core/common/fetcher.dart';
import 'package:app_limiter/components/appbar.dart';
import 'package:app_limiter/core/common/screen_time.dart';
import 'package:app_limiter/components/list_item.dart';
import 'package:app_limiter/components/screen_time_bar.dart';
import 'package:app_limiter/components/permission_alert.dart';

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
    _checkPermissions();
    _loadScreenTime();
  }

  Future<void> _loadScreenTime() async {
    await requestScreenTimePermission();
    if (!mounted) return;
    final result = await getScreenTimeToday();
    if (!mounted) return;
    setState(() {
      screenTime = result;
    });
  }

  Future<void> _checkPermissions() async {
    // Wait a bit for the UI to be ready
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    
    // Check and request permissions using new dialog
    await checkAndRequestAllPermissions(context);
  }

  Future<void> _loadAppUsage() async {
    final installedApps = await getAppUsagesWithIcons();
    print('installedApps: $installedApps');
    
    // Create apps in backend asynchronously (don't wait for completion)
    _syncAppsToBackend(installedApps);
    
    if (!mounted) return;
    setState(() {
      apps = installedApps;
    });
  }
  
  // Sync apps to backend using bulk create endpoint
  Future<void> _syncAppsToBackend(List<AppUsageWithIcon> apps) async {
    if (apps.isEmpty) return;
    
    try {
      // Prepare apps array for bulk request
      final appsData = apps.map((app) => {
        'name': app.appName,
        'package': app.packageName,
        'icon': '', // Empty string for icon
      }).toList();
      
      // Send bulk create request
      await Fetcher.post('/apps/bulk', {
        'apps': appsData,
      });
      
      print('✅ Successfully synced ${apps.length} apps to backend');
    } catch (e) {
      print('❌ Error syncing apps to backend: $e');
      // Silently fail, don't disrupt user experience
    }
  }

  void _onTabTapped(int index) {
    if (index == 0) {
      if (_currentIndex != 0) {
        setState(() {
          _currentIndex = 0;
        });
      }
    } else if (index == 1) {
      Navigator.pushNamed(context, '/limits');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/profile');
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
          // ScreenTimeBar(screenTime: screenTime),
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
