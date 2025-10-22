import 'package:app_usage/app_usage.dart';
import 'package:flutter/foundation.dart';

class AppUsageUtils {
  static Future<List<AppUsageInfo>> getUsageData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      List<AppUsageInfo> infos = await AppUsage().getAppUsage(
        startDate,
        endDate,
      );
      infos.sort((a, b) => b.usage.compareTo(a.usage));
      return infos;
    } catch (e) {
      debugPrint('❌ Gagal mengambil data penggunaan aplikasi: $e');
      return [];
    }
  }

  static Future<List<AppUsageInfo>> getLastHourUsage() {
    final end = DateTime.now();
    final start = end.subtract(const Duration(hours: 1));
    return getUsageData(startDate: start, endDate: end);
  }

  static Future<List<AppUsageInfo>> getTodayUsage() {
    final end = DateTime.now();
    final start = DateTime(end.year, end.month, end.day);
    return getUsageData(startDate: start, endDate: end);
  }
}
