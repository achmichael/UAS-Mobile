import 'package:flutter/material.dart';
import 'package:app_limiter/core/constants/app_colors.dart';
import 'package:app_limiter/core/common/navigation_helper.dart';
import 'package:app_limiter/core/common/app.dart';
import 'package:app_limiter/core/common/fetcher.dart';
import 'package:app_limiter/types/entities.dart';
import 'package:app_limiter/components/limit_modal.dart';

class LimitsScreen extends StatefulWidget {
  const LimitsScreen({super.key});

  @override
  State<LimitsScreen> createState() => _LimitsScreenState();
}

class _LimitsScreenState extends State<LimitsScreen> {
  int _currentIndex = 1;
  List<AppUsageWithIcon> _apps = [];
  Map<String, bool> _appLimits = {};
  Map<String, int> _appLimitMinutes = {}; // Store limit minutes for each app or label
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final apps = await getAppUsagesWithIcons();
      final existingLimits = await _fetchExistingLimits();

      final updatedLimits = <String, bool>{};
      final updatedLimitMinutes = <String, int>{};

      for (final app in apps) {
        final limitMinutes = _findLimitMinutesForApp(existingLimits, app);
        final hasLimit = limitMinutes != null;

        updatedLimits[app.packageName] = hasLimit;
        if (limitMinutes != null) {
          _registerAppLimitKeys(app, limitMinutes, target: updatedLimitMinutes);
        }
      }

      if (!mounted) return;
      setState(() {
        _apps = apps;
        _appLimits = updatedLimits;
        _appLimitMinutes = updatedLimitMinutes;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading apps: $e')));
      }
    }
  }

  void _onTabTapped(int index) {
    if (index == 0) {
      context.navigateToNamed('/dashboard');
    } else if (index == 1) {
      if (_currentIndex != 1) {
        setState(() {
          _currentIndex = 1;
        });
      }
    } else if (index == 2) {
      context.navigateToNamed('/profile');
    }
  }

  String _getCategoryFromPackage(String packageName) {
    // Simple categorization based on package name
    if (packageName.contains('game')) return 'Games';
    if (packageName.contains('social') ||
        packageName.contains('facebook') ||
        packageName.contains('instagram') ||
        packageName.contains('twitter'))
      return 'Social';
    if (packageName.contains('video') ||
        packageName.contains('youtube') ||
        packageName.contains('netflix'))
      return 'Entertainment';
    if (packageName.contains('browser') || packageName.contains('chrome'))
      return 'Productivity';
    return 'Other';
  }

  Future<void> _handleToggleChange(AppUsageWithIcon app, bool value) async {
    if (value) {
      final initialMinutes =
          _appLimitMinutes[app.packageName] ?? _appLimitMinutes[app.appName];

      final minutes = await LimitModal.show(
        context: context,
        appName: app.appName,
        initialMinutes: initialMinutes,
        onSave: (minutes) async {
          try {
            // Token otomatis ditambahkan oleh Fetcher._defaultHeaders()
            await Fetcher.post('/limits', {
              'appName': app.packageName,
              'displayName': app.appName,
              'limitMinutes': minutes,
            });
            
            setState(() {
              _appLimits[app.packageName] = true;
              _registerAppLimitKeys(app, minutes);
            });
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Limit set for ${app.appName}: $minutes minutes'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to set limit: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }

            print(e);
            rethrow;
          }
        },
      );

      // If user canceled or failed, keep toggle OFF
      if (minutes == null) {
        setState(() {
          _appLimits[app.packageName] = false;
        });
      }
    } else {
      // Turn off limit
      setState(() {
        _appLimits[app.packageName] = false;
        _clearAppLimitKeys(app);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Limit removed for ${app.appName}'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E25),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0E25),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'App Limits',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Set Daily Limits',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                // List of apps
                Expanded(
                  child: _apps.isEmpty
                      ? Center(
                          child: Text(
                            'No apps found',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _apps.length,
                          itemBuilder: (context, index) {
                            final app = _apps[index];
                            final isEnabled =
                                _appLimits[app.packageName] ?? false;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1D3A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: app.icon != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          app.icon!,
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(
                                            0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.apps,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                title: Text(
                                  app.appName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: _buildSubtitle(app, isEnabled),
                                trailing: Switch(
                                  value: isEnabled,
                                  onChanged: (value) => _handleToggleChange(app, value),
                                  activeColor: AppColors.primary,
                                  activeTrackColor: AppColors.primary
                                      .withOpacity(0.5),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.navyTone,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
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

  Widget _buildSubtitle(AppUsageWithIcon app, bool isEnabled) {
    final category = _getCategoryFromPackage(app.packageName);
    final limitMinutes =
        _appLimitMinutes[app.packageName] ?? _appLimitMinutes[app.appName];

    if (!isEnabled || limitMinutes == null) {
      return Text(
        category,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 13,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          category,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Daily limit: $limitMinutes minute${limitMinutes == 1 ? '' : 's'}',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<Map<String, int>> _fetchExistingLimits() async {
    try {
      final response = await Fetcher.get('/limits');

      final List<dynamic> entries;
      if (response is List) {
        entries = response;
      } else if (response is Map<String, dynamic>) {
        if (response['data'] is List) {
          entries = List<dynamic>.from(response['data']);
        } else if (response['limits'] is List) {
          entries = List<dynamic>.from(response['limits']);
        } else {
          entries = [];
        }
      } else {
        entries = [];
      }

      final normalized = <String, int>{};

      for (final entry in entries) {
        if (entry is! Map) continue;
        final mapEntry = Map<String, dynamic>.from(
          entry.map(
            (key, value) => MapEntry(key.toString(), value),
          ),
        );

        final packageName = _extractString(mapEntry, const [
          'packageName',
          'package',
          'appPackage',
          'appName',
        ]);

        final displayName = _extractString(mapEntry, const [
          'displayName',
          'appLabel',
          'title',
          'appTitle',
          'name',
        ]);

        final minutes = _extractMinutes(mapEntry, const [
          'limitMinutes',
          'minutes',
          'limit',
          'durationMinutes',
          'duration',
        ]);

        if (minutes == null) {
          continue;
        }

        void addKey(String? key) {
          if (key == null || key.isEmpty) return;
          normalized[key] = minutes;
          normalized[key.toLowerCase()] = minutes;
        }

        addKey(packageName);
        addKey(displayName);
      }

      return normalized;
    } catch (e) {
      return {};
    }
  }

  int? _findLimitMinutesForApp(
    Map<String, int> normalizedLimits,
    AppUsageWithIcon app,
  ) {
    final candidates = <String>{
      app.packageName,
      app.packageName.toLowerCase(),
      app.appName,
      app.appName.toLowerCase(),
    };

    for (final key in candidates) {
      final value = normalizedLimits[key];
      if (value != null) {
        return value;
      }
    }

    return null;
  }


  void _registerAppLimitKeys(
    AppUsageWithIcon app,
    int minutes, {
    Map<String, int>? target,
  }) {
    final destination = target ?? _appLimitMinutes;
    destination[app.packageName] = minutes;
    destination[app.appName] = minutes;
    destination[app.packageName.toLowerCase()] = minutes;
    destination[app.appName.toLowerCase()] = minutes;
  }

  void _clearAppLimitKeys(AppUsageWithIcon app) {
    _appLimitMinutes.remove(app.packageName);
    _appLimitMinutes.remove(app.appName);
    _appLimitMinutes.remove(app.packageName.toLowerCase());
    _appLimitMinutes.remove(app.appName.toLowerCase());
  }

  String? _extractString(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  int? _extractMinutes(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      final minutes = _asInt(value);
      if (minutes != null) {
        return minutes;
      }
    }
    return null;
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }
}