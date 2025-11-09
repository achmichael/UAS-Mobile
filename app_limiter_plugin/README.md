# app_limiter_plugin

Plugin Flutter untuk membatasi penggunaan aplikasi dengan fitur overlay blocking dan monitoring usage stats.

## Fitur

- ✅ **Overlay Blocking**: Menampilkan overlay full-screen untuk memblokir aplikasi
- ✅ **Usage Stats**: Monitoring penggunaan aplikasi real-time
- ✅ **Foreground App Detection**: Deteksi aplikasi yang sedang aktif
- ✅ **Permission Management**: Handle overlay dan usage access permissions

## Instalasi

Tambahkan dependency di `pubspec.yaml`:

```yaml
dependencies:
  app_limiter_plugin:
    path: ../app_limiter_plugin
```

## Permissions

Plugin ini memerlukan permissions berikut di `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW"/>
<uses-permission android:name="android.permission.PACKAGE_USAGE_STATS"
    tools:ignore="ProtectedPermissions" 
    xmlns:tools="http://schemas.android.com/tools"/>
```

## Penggunaan

### Import Plugin

```dart
import 'package:app_limiter_plugin/app_limiter_plugin.dart';
```

### Inisialisasi

```dart
final _appLimiterPlugin = AppLimiterPlugin();
```

### 1. Overlay Methods

#### Show Overlay
```dart
await _appLimiterPlugin.showCustomOverlay('Nama Aplikasi');
```

#### Hide Overlay
```dart
await _appLimiterPlugin.hideOverlay();
```

#### Check Overlay Permission
```dart
bool hasPermission = await _appLimiterPlugin.hasOverlayPermission();
```

#### Request Overlay Permission
```dart
await _appLimiterPlugin.requestOverlayPermission();
```

### 2. Usage Stats Methods

#### Get Current Foreground App
```dart
String? currentApp = await _appLimiterPlugin.getCurrentForegroundApp();
print('Current app: $currentApp');
```

#### Get App Usage Today
```dart
int usageMs = await _appLimiterPlugin.getAppUsageToday('com.example.app');
print('Usage: ${usageMs / 1000 / 60} minutes');
```

#### Get All Apps Usage Today
```dart
Map<String, int> allUsage = await _appLimiterPlugin.getAllAppsUsageToday();
allUsage.forEach((packageName, milliseconds) {
  print('$packageName: ${milliseconds / 1000 / 60} minutes');
});
```

#### Check Usage Access Permission
```dart
bool hasPermission = await _appLimiterPlugin.hasUsageAccessPermission();
```

#### Open Usage Access Settings
```dart
await _appLimiterPlugin.openUsageAccessSettings();
```

## Contoh Lengkap

```dart
import 'package:flutter/material.dart';
import 'package:app_limiter_plugin/app_limiter_plugin.dart';

class AppLimiterExample extends StatefulWidget {
  @override
  _AppLimiterExampleState createState() => _AppLimiterExampleState();
}

class _AppLimiterExampleState extends State<AppLimiterExample> {
  final _plugin = AppLimiterPlugin();
  
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }
  
  Future<void> _checkPermissions() async {
    bool overlayPerm = await _plugin.hasOverlayPermission();
    bool usagePerm = await _plugin.hasUsageAccessPermission();
    
    if (!overlayPerm) {
      await _plugin.requestOverlayPermission();
    }
    
    if (!usagePerm) {
      await _plugin.openUsageAccessSettings();
    }
  }
  
  Future<void> _monitorAndBlock() async {
    String? currentApp = await _plugin.getCurrentForegroundApp();
    
    if (currentApp != null) {
      int usage = await _plugin.getAppUsageToday(currentApp);
      int limitMs = 60 * 60 * 1000; // 1 hour
      
      if (usage >= limitMs) {
        await _plugin.showCustomOverlay(currentApp);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('App Limiter')),
      body: Center(
        child: ElevatedButton(
          onPressed: _monitorAndBlock,
          child: Text('Check & Block'),
        ),
      ),
    );
  }
}
```

## Platform Support

| Platform | Support |
|----------|---------|
| Android  | ✅      |
| iOS      | ❌      |
| Web      | ❌      |
| Windows  | ❌      |
| macOS    | ❌      |
| Linux    | ❌      |

## Catatan Penting

1. **Usage Stats Permission**: Memerlukan user untuk manually mengaktifkan permission di Settings
2. **Overlay Permission**: Required untuk Android 6.0+ (API level 23+)
3. **Background Service**: Untuk monitoring real-time, gunakan dengan `flutter_background_service`
4. **Battery Optimization**: Pastikan app dikecualikan dari battery optimization untuk monitoring yang reliable

## Troubleshooting

### Overlay tidak muncul
- Pastikan overlay permission sudah diberikan
- Check apakah method `showCustomOverlay()` dipanggil dari main thread
- Verifikasi di logcat untuk error messages

### Usage Stats tidak akurat
- Pastikan usage access permission sudah diberikan
- Usage stats hanya tersedia untuk Android 5.0+ (API level 21+)
- Data mungkin delayed beberapa detik

## License

MIT License - Lihat file LICENSE untuk detail

## Contributing

Pull requests welcome! Untuk perubahan major, mohon buka issue terlebih dahulu.
