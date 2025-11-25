import 'package:app_limiter/core/common/fetcher.dart';
import 'package:app_limiter/core/common/token_manager.dart';


Future<Map<String, Map<String, dynamic>>> fetchLimitsMap() async {
  try {
    final response = await Fetcher.get(
      '/limits',
      headers: await _buildAuthHeaders(),
    );

    final List<dynamic> entries;
    if (response is List) {
      entries = response;
    } else if (response is Map<String, dynamic>) {
      if (response['data'] is List) {
        entries = List<dynamic>.from(response['data']);
      } else if (response['limits'] is List) {
        entries = List<dynamic>.from(response['limits']);
      } else {
        entries = <dynamic>[];
      }
    } else {
      entries = <dynamic>[];
    }

    final normalized = <String, Map<String, dynamic>>{};

    for (final entry in entries) {
      if (entry is! Map) continue;
      final mapEntry = Map<String, dynamic>.from(
        entry.map((key, value) => MapEntry(key.toString(), value)),
      );

      // Extract app object from response
      final appData = mapEntry['app'] ?? mapEntry['appId'];
      final appMap = appData is Map ? Map<String, dynamic>.from(appData) : null;

      // Get package name from app object
      String? packageName;
      String? displayName;
      
      if (appMap != null) {
        packageName = _extractString(appMap, const [
          'package',
          'packageName',
        ]);
        
        displayName = _extractString(appMap, const [
          'name',
          'displayName',
          'appName',
        ]);
      }

      // Fallback to old structure for backward compatibility
      packageName ??= _extractString(mapEntry, const [
        'package',
        'packageName',
        'appPackage',
        'appName',
      ]);

      displayName ??= _extractString(mapEntry, const [
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

      final id = _extractString(mapEntry, const ['_id', 'id']);

      if (minutes == null) {
        continue;
      }

      final limitData = {
        'minutes': minutes,
        'id': id,
      };

      void addKey(String? key) {
        if (key == null || key.isEmpty) return;
        normalized[key] = limitData;
        normalized[key.toLowerCase()] = limitData;
      }

      addKey(packageName);
      addKey(displayName);
    }

    return normalized;
  } catch (_) {
    return <String, Map<String, dynamic>>{};
  }
}

Future<Map<String, int>> fetchNormalizedLimits() async {
  final limitsMap = await fetchLimitsMap();
  return limitsMap.map((key, value) => MapEntry(key, value['minutes'] as int));
}


/// Resolve the configured limit (in minutes) for the given identifiers.
/// Returns null if no limit is configured.
int? findLimitMinutesForApp(
  Map<String, int> normalizedLimits, {
  String? packageName,
  String? displayName,
}) {
  final candidates = <String>{};

  void addCandidate(String? value) {
    if (value == null || value.isEmpty) return;
    candidates.add(value);
    candidates.add(value.toLowerCase());
  }

  addCandidate(packageName);
  addCandidate(displayName);

  for (final key in candidates) {
    final limit = normalizedLimits[key];
    if (limit != null) {
      return limit;
    }
  }

  return null;
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

Future<Map<String, String>> _buildAuthHeaders() async {
  final manager = TokenManager.instance;
  final accessToken = await manager.getStoredAccessToken();
  if (accessToken != null && accessToken.isNotEmpty) {
    return <String, String>{'Authorization': 'Bearer $accessToken'};
  }

  final refreshToken = await manager.getRefreshToken();
  if (refreshToken != null && refreshToken.isNotEmpty) {
    return <String, String>{'Authorization': 'Bearer $refreshToken'};
  }

  return <String, String>{};
}
