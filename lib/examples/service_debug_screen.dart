import 'package:flutter/material.dart';
import 'package:app_limiter/services/app_monitor_service.dart';
import 'package:app_limiter/services/usage_stats_service.dart';
import 'package:app_limiter/services/overlay_service.dart';

/// Debug/Testing screen for the background service
/// Use this to verify everything is working correctly
class ServiceDebugScreen extends StatefulWidget {
  const ServiceDebugScreen({super.key});

  @override
  State<ServiceDebugScreen> createState() => _ServiceDebugScreenState();
}

class _ServiceDebugScreenState extends State<ServiceDebugScreen> {
  final UsageStatsService _usageStatsService = UsageStatsService();
  final OverlayService _overlayService = OverlayService();
  
  String _currentApp = 'Not detected';
  Map<String, int> _allUsage = {};
  bool _isServiceRunning = false;
  bool _hasUsageAccess = false;
  bool _hasOverlay = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() => _isLoading = true);

    try {
      // Check service status
      final isRunning = await AppMonitorService.isServiceRunning();
      
      // Check permissions
      final hasUsage = await _usageStatsService.hasUsageAccessPermission();
      final hasOverlay = await _overlayService.hasOverlayPermission();
      
      setState(() {
        _isServiceRunning = isRunning;
        _hasUsageAccess = hasUsage;
        _hasOverlay = hasOverlay;
      });

      // Get current app if permission granted
      if (hasUsage) {
        final currentApp = await _usageStatsService.getCurrentForegroundApp();
        final allUsage = await _usageStatsService.getAllAppsUsageToday();
        
        setState(() {
          _currentApp = currentApp ?? 'Unable to detect';
          _allUsage = allUsage;
        });
      }
    } catch (e) {
      print('Error running diagnostics: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Diagnostics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runDiagnostics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Service Status Section
                _buildSection(
                  title: 'Service Status',
                  children: [
                    _buildStatusTile(
                      'Background Service',
                      _isServiceRunning,
                      'Service is ${_isServiceRunning ? 'running' : 'not running'}',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Permissions Section
                _buildSection(
                  title: 'Permissions',
                  children: [
                    _buildStatusTile(
                      'Usage Access',
                      _hasUsageAccess,
                      'Required to monitor app usage',
                      onTap: () => _usageStatsService.openUsageAccessSettings(),
                    ),
                    _buildStatusTile(
                      'Display Overlay',
                      _hasOverlay,
                      'Required to show blocking screen',
                      onTap: () => _overlayService.requestOverlayPermission(),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Current App Section
                _buildSection(
                  title: 'Current Detection',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.phone_android),
                      title: const Text('Foreground App'),
                      subtitle: Text(_currentApp),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Today's Usage Section
                _buildSection(
                  title: 'Today\'s Usage (Top 10)',
                  children: [
                    if (_allUsage.isEmpty)
                      const ListTile(
                        title: Text('No usage data available'),
                        subtitle: Text('Grant usage access permission to see data'),
                      )
                    else
                      ...(_allUsage.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value)))
                          .take(10)
                          .map((entry) => ListTile(
                                leading: const Icon(Icons.apps),
                                title: Text(_getAppNameFromPackage(entry.key)),
                                subtitle: Text(entry.key),
                                trailing: Text('${entry.value} min'),
                              ))
                          .toList(),
                  ],
                ),

                const SizedBox(height: 16),

                // Test Actions Section
                _buildSection(
                  title: 'Test Actions',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.block),
                      title: const Text('Test Overlay'),
                      subtitle: const Text('Show overlay for 3 seconds'),
                      onTap: () => _testOverlay(),
                    ),
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text('View Logs'),
                      subtitle: const Text('Use adb logcat | grep AppMonitor'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // System Info
                _buildSection(
                  title: 'System Info',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.android),
                      title: const Text('Platform'),
                      subtitle: Text(Theme.of(context).platform.toString()),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatusTile(String title, bool isActive, String subtitle, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(
        isActive ? Icons.check_circle : Icons.cancel,
        color: isActive ? Colors.green : Colors.red,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: onTap != null ? const Icon(Icons.settings) : null,
      onTap: onTap,
    );
  }

  Future<void> _testOverlay() async {
    try {
      await _overlayService.showCustomOverlay('com.example.test.app');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Overlay shown! It will hide in 3 seconds...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Hide after 3 seconds
      await Future.delayed(const Duration(seconds: 3));
      await _overlayService.hideOverlay();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error showing overlay: $e')),
        );
      }
    }
  }

  String _getAppNameFromPackage(String packageName) {
    // Simple package name to readable name conversion
    final parts = packageName.split('.');
    if (parts.isNotEmpty) {
      return parts.last[0].toUpperCase() + parts.last.substring(1);
    }
    return packageName;
  }
}

/// How to access this screen:
/// 
/// Add a debug button in your profile or settings:
/// 
/// ```dart
/// ElevatedButton(
///   onPressed: () {
///     Navigator.push(
///       context,
///       MaterialPageRoute(
///         builder: (context) => const ServiceDebugScreen(),
///       ),
///     );
///   },
///   child: const Text('Service Diagnostics'),
/// )
/// ```
