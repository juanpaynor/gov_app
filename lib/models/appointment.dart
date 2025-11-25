class Appointment {
  final String id;
  final String userId;
  final String departmentId;
  final String ticketNumber;
  final String fullName;
  final String contactNumber;
  final String purpose;
  final DateTime appointmentDate;
  final String timeSlotStart;
  final String timeSlotEnd;
  final AppointmentStatus status;
  final DateTime createdAt;
  final DateTime? checkedInAt;
  final DateTime? calledAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? departmentNotes;
  final String? cancellationReason;
  final int? serviceDurationMinutes;

  // Populated from joins (not in database)
  final String? departmentName;
  final String? departmentIcon;

  Appointment({
    required this.id,
    required this.userId,
    required this.departmentId,
    required this.ticketNumber,
    required this.fullName,
    required this.contactNumber,
    required this.purpose,
    required this.appointmentDate,
    required this.timeSlotStart,
    required this.timeSlotEnd,
    required this.status,
    required this.createdAt,
    this.checkedInAt,
    this.calledAt,
    this.completedAt,
    this.cancelledAt,
    this.departmentNotes,
    this.cancellationReason,
    this.serviceDurationMinutes,
    this.departmentName,
    this.departmentIcon,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      departmentId: json['department_id'] as String,
      ticketNumber: json['ticket_number'] as String,
      fullName: json['full_name'] as String,
      contactNumber: json['contact_number'] as String,
      purpose: json['purpose'] as String,
      appointmentDate: DateTime.parse(json['appointment_date'] as String),
      timeSlotStart: json['time_slot_start'] as String,
      timeSlotEnd: json['time_slot_end'] as String,
      status: AppointmentStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      checkedInAt: json['checked_in_at'] != null
          ? DateTime.parse(json['checked_in_at'] as String)
          : null,
      calledAt: json['called_at'] != null
          ? DateTime.parse(json['called_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      departmentNotes: json['department_notes'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      serviceDurationMinutes: json['service_duration_minutes'] as int?,
      departmentName: json['department_name'] as String?,
      departmentIcon: json['department_icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'department_id': departmentId,
      'ticket_number': ticketNumber,
      'full_name': fullName,
      'contact_number': contactNumber,
      'purpose': purpose,
      'appointment_date': appointmentDate.toIso8601String().split('T')[0],
      'time_slot_start': timeSlotStart,
      'time_slot_end': timeSlotEnd,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'checked_in_at': checkedInAt?.toIso8601String(),
      'called_at': calledAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'department_notes': departmentNotes,
      'cancellation_reason': cancellationReason,
      'service_duration_minutes': serviceDurationMinutes,
    };
  }

  bool get isPending => status == AppointmentStatus.pending;
  bool get isActive => status == AppointmentStatus.pending && 
                       appointmentDate.day == DateTime.now().day;
  bool get isUpcoming => status == AppointmentStatus.pending && 
                         appointmentDate.isAfter(DateTime.now());
  bool get canCancel => status == AppointmentStatus.pending;
  bool get isCompleted => status == AppointmentStatus.completed;
  bool get isCancelled => status == AppointmentStatus.cancelled;
  bool get isMissed => status == AppointmentStatus.missed;

  String get formattedDate {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[appointmentDate.month - 1]} ${appointmentDate.day}, ${appointmentDate.year}';
  }

  String get formattedTimeSlot {
    return '$timeSlotStart - $timeSlotEnd';
  }
}

enum AppointmentStatus {
  pending('pending'),
  checkedIn('checked_in'),
  inProgress('in_progress'),
  completed('completed'),
  cancelled('cancelled'),
  missed('missed');

  final String value;
  const AppointmentStatus(this.value);

  static AppointmentStatus fromString(String value) {
    return AppointmentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => AppointmentStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case AppointmentStatus.pending:
        return 'Pending';
      case AppointmentStatus.checkedIn:
        return 'Checked In';
      case AppointmentStatus.inProgress:
        return 'In Progress';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.missed:
        return 'No Show';
    }
  }
}
