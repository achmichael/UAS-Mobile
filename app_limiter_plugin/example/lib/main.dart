import 'package:flutter/material.dart';
import 'package:app_limiter_plugin/app_limiter_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appLimiterPlugin = AppLimiterPlugin();
  
  String _foregroundApp = 'Unknown';
  bool _hasOverlayPermission = false;
  bool _hasUsagePermission = false;
  Map<String, int> _allUsage = {};

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final overlayPermission = await _appLimiterPlugin.hasOverlayPermission();
    final usagePermission = await _appLimiterPlugin.hasUsageAccessPermission();
    
    setState(() {
      _hasOverlayPermission = overlayPermission;
      _hasUsagePermission = usagePermission;
    });
  }

  Future<void> _getCurrentApp() async {
    final app = await _appLimiterPlugin.getCurrentForegroundApp();
    setState(() {
      _foregroundApp = app ?? 'Unable to detect';
    });
  }

  Future<void> _getAllUsage() async {
    final usage = await _appLimiterPlugin.getAllAppsUsageToday();
    setState(() {
      _allUsage = usage;
    });
  }

  Future<void> _showOverlay() async {
    await _appLimiterPlugin.showCustomOverlay('Test App');
  }

  Future<void> _hideOverlay() async {
    await _appLimiterPlugin.hideOverlay();
  }

  Future<void> _requestOverlayPermission() async {
    await _appLimiterPlugin.requestOverlayPermission();
    await Future.delayed(const Duration(seconds: 1));
    await _checkPermissions();
  }

  Future<void> _requestUsagePermission() async {
    await _appLimiterPlugin.openUsageAccessSettings();
    await Future.delayed(const Duration(seconds: 1));
    await _checkPermissions();
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours}h ${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('App Limiter Plugin Example'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Permissions Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            _hasOverlayPermission ? Icons.check_circle : Icons.cancel,
                            color: _hasOverlayPermission ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          const Text('Overlay Permission'),
                          const Spacer(),
                          if (!_hasOverlayPermission)
                            ElevatedButton(
                              onPressed: _requestOverlayPermission,
                              child: const Text('Request'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            _hasUsagePermission ? Icons.check_circle : Icons.cancel,
                            color: _hasUsagePermission ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          const Text('Usage Access Permission'),
                          const Spacer(),
                          if (!_hasUsagePermission)
                            ElevatedButton(
                              onPressed: _requestUsagePermission,
                              child: const Text('Request'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overlay Controls',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _hasOverlayPermission ? _showOverlay : null,
                              child: const Text('Show Overlay'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _hideOverlay,
                              child: const Text('Hide Overlay'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Foreground App Detection',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Current: $_foregroundApp'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _hasUsagePermission ? _getCurrentApp : null,
                        child: const Text('Get Current App'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Usage Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _hasUsagePermission ? _getAllUsage : null,
                        child: const Text('Get All App Usage'),
                      ),
                      const SizedBox(height: 8),
                      if (_allUsage.isNotEmpty) ...[
                        const Text(
                          'Top 10 Apps:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...() {
                          final sortedEntries = _allUsage.entries.toList()
                            ..sort((a, b) => b.value.compareTo(a.value));
                          return sortedEntries
                              .take(10)
                              .map((entry) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            entry.key.split('.').last,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(_formatDuration(entry.value)),
                                      ],
                                    ),
                                  ))
                              .toList();
                        }(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
