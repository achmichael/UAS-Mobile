import 'package:flutter/material.dart';
import 'package:app_limiter/services/app_monitor_service.dart';
import 'package:app_limiter/services/usage_stats_service.dart';
import 'package:app_limiter/services/overlay_service.dart';
import 'package:app_limiter/helpers/permissions_helper.dart';

/// Example integration showing how to use the background service
/// in your Dashboard or Settings screen
class ServiceControlWidget extends StatefulWidget {
  const ServiceControlWidget({super.key});

  @override
  State<ServiceControlWidget> createState() => _ServiceControlWidgetState();
}

class _ServiceControlWidgetState extends State<ServiceControlWidget> {
  bool _isServiceRunning = false;
  bool _hasUsageAccess = false;
  bool _hasOverlayPermission = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
    
    // Check permissions when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionsHelper.checkAndRequestPermissions(context);
    });
  }

  Future<void> _checkStatus() async {
    final isRunning = await AppMonitorService.isServiceRunning();
    final hasUsage = await UsageStatsService().hasUsageAccessPermission();
    final hasOverlay = await OverlayService().hasOverlayPermission();

    setState(() {
      _isServiceRunning = isRunning;
      _hasUsageAccess = hasUsage;
      _hasOverlayPermission = hasOverlay;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Background Service Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Service Status
            _StatusRow(
              icon: Icons.settings_applications,
              label: 'Background Service',
              isActive: _isServiceRunning,
              onTap: null, // Auto-started, can't manually toggle
            ),
            const Divider(),

            // Usage Access Permission
            _StatusRow(
              icon: Icons.access_time,
              label: 'Usage Access',
              isActive: _hasUsageAccess,
              onTap: () async {
                await UsageStatsService().openUsageAccessSettings();
                await Future.delayed(const Duration(seconds: 1));
                _checkStatus();
              },
            ),
            const Divider(),

            // Overlay Permission
            _StatusRow(
              icon: Icons.layers,
              label: 'Display Overlay',
              isActive: _hasOverlayPermission,
              onTap: () async {
                await OverlayService().requestOverlayPermission();
                await Future.delayed(const Duration(seconds: 1));
                _checkStatus();
              },
            ),

            const SizedBox(height: 16),

            // Info text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All permissions must be enabled for app limiting to work properly.',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),

            // Refresh button
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _checkStatus,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Status'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _StatusRow({
    required this.icon,
    required this.label,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: isActive ? Colors.green : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.green.shade100 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? Colors.green.shade800 : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ],
        ),
      ),
    );
  }
}

/// Example: How to add this widget to your Dashboard
/// 
/// In your dashboard.dart or profile.dart:
/// 
/// ```dart
/// import 'package:app_limiter/examples/service_control_widget.dart';
/// 
/// // In your build method:
/// Column(
///   children: [
///     // ... your existing widgets
///     const ServiceControlWidget(),
///     // ... more widgets
///   ],
/// )
/// ```
