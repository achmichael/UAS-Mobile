import 'package:flutter/services.dart';


typedef User = ({
  String id,
  String name,
  String email,
  String password,
  DateTime createdAt,
  DateTime updatedAt,
  List<UsageLog> usageLogs,
  List<LimitRule> limitRules,
});

typedef UsageLog = ({
  String id,
  String userId,
  String appName,
  DateTime startTime,
  DateTime? endTime,
  int? durationMinutes,
  DateTime createdAt,
  DateTime updatedAt,
  Map<String, dynamic>? user, 
});

typedef LimitRule = ({
  String id,
  String userId,
  String appName,
  int limitMinutes,
  DateTime createdAt,
  DateTime updatedAt,
  Map<String, dynamic>? user,
});

typedef ApplicationInfo = ({
  String packageName,
  String appName,
  Duration usage,
  DateTime startDate,
  DateTime endDate,
});

typedef AppUsageWithIcon = ({
  String packageName,
  String appName,
  Duration usage,
  Uint8List? icon,
});

