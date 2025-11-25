class DepartmentSettings {
  final String id;
  final String departmentId;
  final bool canReceiveAppointments;
  final int dailyAppointmentLimit;
  final bool allowSameDay;
  final int minDaysAdvance;
  final int maxDaysAdvance;
  final bool requireQrCheckin;
  final String operatingStart;
  final String operatingEnd;
  final String lunchBreakStart;
  final String lunchBreakEnd;
  final DateTime createdAt;
  final DateTime updatedAt;

  DepartmentSettings({
    required this.id,
    required this.departmentId,
    required this.canReceiveAppointments,
    required this.dailyAppointmentLimit,
    required this.allowSameDay,
    required this.minDaysAdvance,
    required this.maxDaysAdvance,
    required this.requireQrCheckin,
    required this.operatingStart,
    required this.operatingEnd,
    required this.lunchBreakStart,
    required this.lunchBreakEnd,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DepartmentSettings.fromJson(Map<String, dynamic> json) {
    return DepartmentSettings(
      id: json['id'] as String,
      departmentId: json['department_id'] as String,
      canReceiveAppointments: json['can_receive_appointments'] as bool,
      dailyAppointmentLimit: json['daily_appointment_limit'] as int? ?? 50,
      allowSameDay: json['allow_same_day'] as bool,
      minDaysAdvance: json['min_days_advance'] as int,
      maxDaysAdvance: json['max_days_advance'] as int,
      requireQrCheckin: json['require_qr_checkin'] as bool,
      operatingStart: json['operating_start'] as String,
      operatingEnd: json['operating_end'] as String,
      lunchBreakStart: json['lunch_break_start'] as String,
      lunchBreakEnd: json['lunch_break_end'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'department_id': departmentId,
      'can_receive_appointments': canReceiveAppointments,
      'daily_appointment_limit': dailyAppointmentLimit,
      'allow_same_day': allowSameDay,
      'min_days_advance': minDaysAdvance,
      'max_days_advance': maxDaysAdvance,
      'require_qr_checkin': requireQrCheckin,
      'operating_start': operatingStart,
      'operating_end': operatingEnd,
      'lunch_break_start': lunchBreakStart,
      'lunch_break_end': lunchBreakEnd,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  DateTime get earliestBookingDate {
    if (allowSameDay) return DateTime.now();
    return DateTime.now().add(Duration(days: minDaysAdvance));
  }

  DateTime get latestBookingDate {
    return DateTime.now().add(Duration(days: maxDaysAdvance));
  }

  bool canBookDate(DateTime date) {
    final today = DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    
    if (dateOnly.isBefore(todayOnly)) return false;
    
    final daysDiff = dateOnly.difference(todayOnly).inDays;
    
    if (!allowSameDay && daysDiff < minDaysAdvance) return false;
    if (daysDiff > maxDaysAdvance) return false;
    
    return true;
  }
}
