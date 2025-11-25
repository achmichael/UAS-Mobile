import 'package:flutter/material.dart';
import 'package:app_limiter/services/overlay_service.dart';

/// Screen untuk check dan request permissions yang diperlukan
/// untuk fitur overlay dan accessibility service
class PermissionsCheckScreen extends StatefulWidget {
  const PermissionsCheckScreen({Key? key}) : super(key: key);

  @override
  State<PermissionsCheckScreen> createState() => _PermissionsCheckScreenState();
}

class _PermissionsCheckScreenState extends State<PermissionsCheckScreen> {
  final _overlayService = OverlayService();
  
  bool _hasOverlayPermission = false;
  bool _hasAccessibilityPermission = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isChecking = true);
    
    try {
      final hasOverlay = await _overlayService.hasOverlayPermission();
      final hasAccessibility = await _overlayService.hasAccessibilityPermission();
      
      setState(() {
        _hasOverlayPermission = hasOverlay;
        _hasAccessibilityPermission = hasAccessibility;
        _isChecking = false;
      });
    } catch (e) {
      print('Error checking permissions: $e');
      setState(() => _isChecking = false);
    }
  }

  Future<void> _requestOverlayPermission() async {
    await _overlayService.requestOverlayPermission();
    
    // Wait a bit for user to grant permission
    await Future.delayed(const Duration(seconds: 2));
    await _checkPermissions();
  }

  Future<void> _requestAccessibilityPermission() async {
    await _overlayService.requestAccessibilityPermission();
    
    // Wait a bit for user to enable service
    await Future.delayed(const Duration(seconds: 2));
    await _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions Check'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkPermissions,
            tooltip: 'Refresh permissions',
          ),
        ],
      ),
      body: _isChecking
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildInfoCard(),
                const SizedBox(height: 16),
                _buildPermissionCard(
                  title: 'Overlay Permission',
                  description: 'Required to show blocking overlay when app limit is reached',
                  isGranted: _hasOverlayPermission,
                  onRequest: _requestOverlayPermission,
                  icon: Icons.apps,
                ),
                const SizedBox(height: 16),
                _buildPermissionCard(
                  title: 'Accessibility Service',
                  description: 'Required to remove blocked apps from Recent Apps when Cancel is pressed',
                  isGranted: _hasAccessibilityPermission,
                  onRequest: _requestAccessibilityPermission,
                  icon: Icons.accessibility_new,
                  helpText: 'Go to Settings > Accessibility > App Limiter and toggle ON',
                ),
                const SizedBox(height: 24),
                if (_hasOverlayPermission && _hasAccessibilityPermission)
                  _buildSuccessCard()
                else
                  _buildWarningCard(),
              ],
            ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'App Limiter requires two permissions to function properly',
                style: TextStyle(
                  color: Colors.blue.shade900,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onRequest,
    required IconData icon,
    String? helpText,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusBadge(isGranted),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
            if (helpText != null && !isGranted) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.help_outline, size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        helpText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (!isGranted) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRequest,
                  icon: const Icon(Icons.settings),
                  label: const Text('Grant Permission'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isGranted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isGranted ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGranted ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isGranted ? Colors.green.shade700 : Colors.red.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            isGranted ? 'Granted' : 'Not Granted',
            style: TextStyle(
              color: isGranted ? Colors.green.shade900 : Colors.red.shade900,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 48),
            const SizedBox(height: 8),
            Text(
              'All Permissions Granted!',
              style: TextStyle(
                color: Colors.green.shade900,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'App Limiter is ready to block apps when limits are reached',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningCard() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade700, size: 48),
            const SizedBox(height: 8),
            Text(
              'Missing Permissions',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Please grant all permissions above for app blocking to work properly',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
