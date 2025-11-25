class TimeSlot {
  final String id;
  final String departmentId;
  final String slotStart;
  final String slotEnd;
  final int maxAppointments;
  final List<int> dayOfWeek;
  final bool isActive;
  final DateTime createdAt;

  // Computed fields (not in database)
  final int? bookedCount;
  final int? availableSpots;

  TimeSlot({
    required this.id,
    required this.departmentId,
    required this.slotStart,
    required this.slotEnd,
    required this.maxAppointments,
    required this.dayOfWeek,
    required this.isActive,
    required this.createdAt,
    this.bookedCount,
    this.availableSpots,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'] as String,
      departmentId: json['department_id'] as String,
      slotStart: json['slot_start'] as String,
      slotEnd: json['slot_end'] as String,
      maxAppointments: json['max_appointments'] as int,
      dayOfWeek: (json['day_of_week'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [1, 2, 3, 4, 5],
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      bookedCount: json['booked_count'] as int?,
      availableSpots: json['available_spots'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'department_id': departmentId,
      'slot_start': slotStart,
      'slot_end': slotEnd,
      'max_appointments': maxAppointments,
      'day_of_week': dayOfWeek,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedTimeRange {
    return '$slotStart - $slotEnd';
  }

  bool get isFull => (availableSpots ?? maxAppointments) <= 0;
  
  bool get hasLimitedSpots {
    if (availableSpots == null) return false;
    final percentage = availableSpots! / maxAppointments;
    return percentage > 0 && percentage <= 0.5;
  }

  bool get hasGoodAvailability {
    if (availableSpots == null) return true;
    final percentage = availableSpots! / maxAppointments;
    return percentage > 0.5;
  }

  String get availabilityText {
    if (availableSpots == null) {
      return '$maxAppointments spots';
    }
    if (isFull) return 'Fully Booked';
    return '$availableSpots spots left';
  }

  SlotAvailability get availability {
    if (isFull) return SlotAvailability.full;
    if (hasLimitedSpots) return SlotAvailability.limited;
    return SlotAvailability.available;
  }
}

enum SlotAvailability {
  available,
  limited,
  full;

  String get displayName {
    switch (this) {
      case SlotAvailability.available:
        return 'Available';
      case SlotAvailability.limited:
        return 'Limited';
      case SlotAvailability.full:
        return 'Full';
    }
  }
}
