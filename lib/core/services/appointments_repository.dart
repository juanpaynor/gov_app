import 'supabase_service.dart';
import '../../models/appointment.dart';
import '../../models/time_slot.dart';
import '../../models/department_settings.dart';

class AppointmentsRepository {
  final _supabase = supabase;

  // Get departments that accept appointments
  Future<List<Map<String, dynamic>>> getDepartmentsAcceptingAppointments() async {
    try {
      final response = await _supabase
          .from('departments')
          .select('''
            id,
            name,
            description,
            icon,
            is_active,
            department_settings!inner(can_receive_appointments)
          ''')
          .eq('is_active', true)
          .eq('department_settings.can_receive_appointments', true);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('Error fetching departments: $e');
      rethrow;
    }
  }

  // Get department settings
  Future<DepartmentSettings?> getDepartmentSettings(String departmentId) async {
    try {
      final response = await _supabase
          .from('department_settings')
          .select()
          .eq('department_id', departmentId)
          .maybeSingle();

      if (response == null) return null;
      return DepartmentSettings.fromJson(response);
    } catch (e) {
      print('Error fetching department settings: $e');
      rethrow;
    }
  }

  // Get available time slots for a specific date
  Future<List<TimeSlot>> getAvailableTimeSlots(
    String departmentId,
    DateTime date,
  ) async {
    try {
      final dayOfWeek = date.weekday; // 1=Monday, 7=Sunday
      final dateStr = date.toIso8601String().split('T')[0];

      // Get active time slots for this department and day of week
      final slotsResponse = await _supabase
          .from('department_time_slots')
          .select()
          .eq('department_id', departmentId)
          .eq('is_active', true)
          .contains('day_of_week', [dayOfWeek]);

      final slots = (slotsResponse as List)
          .map((json) => TimeSlot.fromJson(json))
          .toList();

      // Get booked appointments for this date
      final appointmentsResponse = await _supabase
          .from('appointments')
          .select('time_slot_start, time_slot_end')
          .eq('department_id', departmentId)
          .eq('appointment_date', dateStr)
          .inFilter('status', ['pending', 'checked_in', 'in_progress']);

      // Count bookings per slot
      final Map<String, int> bookingCounts = {};
      for (final appt in appointmentsResponse as List) {
        final key = '${appt['time_slot_start']}-${appt['time_slot_end']}';
        bookingCounts[key] = (bookingCounts[key] ?? 0) + 1;
      }

      // Add availability info to slots
      final slotsWithAvailability = slots.map((slot) {
        final key = '${slot.slotStart}-${slot.slotEnd}';
        final booked = bookingCounts[key] ?? 0;
        final available = slot.maxAppointments - booked;

        return TimeSlot(
          id: slot.id,
          departmentId: slot.departmentId,
          slotStart: slot.slotStart,
          slotEnd: slot.slotEnd,
          maxAppointments: slot.maxAppointments,
          dayOfWeek: slot.dayOfWeek,
          isActive: slot.isActive,
          createdAt: slot.createdAt,
          bookedCount: booked,
          availableSpots: available,
        );
      }).toList();

      // Sort by time
      slotsWithAvailability.sort((a, b) => a.slotStart.compareTo(b.slotStart));

      return slotsWithAvailability;
    } catch (e) {
      print('Error fetching time slots: $e');
      rethrow;
    }
  }

  // Get daily appointment count
  Future<int> getDailyAppointmentCount(
    String departmentId,
    DateTime date,
  ) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('appointments')
          .select('id')
          .eq('department_id', departmentId)
          .eq('appointment_date', dateStr)
          .inFilter('status', ['pending', 'checked_in', 'in_progress']);

      return (response as List).length;
    } catch (e) {
      print('Error counting appointments: $e');
      return 0;
    }
  }

  // Check if date is closed
  Future<bool> isDateClosed(String departmentId, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('department_closed_dates')
          .select('id')
          .eq('department_id', departmentId)
          .eq('closed_date', dateStr)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking closed date: $e');
      return false;
    }
  }

  // Book appointment
  Future<Appointment> bookAppointment({
    required String departmentId,
    required String fullName,
    required String contactNumber,
    required String purpose,
    required DateTime appointmentDate,
    required TimeSlot timeSlot,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final dateStr = appointmentDate.toIso8601String().split('T')[0];

      // Call RPC function to generate ticket number
      final ticketNumber = await _supabase.rpc(
        'generate_ticket_number',
        params: {
          'dept_id': departmentId,
          'appt_date': dateStr,
        },
      );

      // Insert appointment
      final response = await _supabase
          .from('appointments')
          .insert({
            'user_id': userId,
            'department_id': departmentId,
            'ticket_number': ticketNumber,
            'full_name': fullName,
            'contact_number': contactNumber,
            'purpose': purpose,
            'appointment_date': dateStr,
            'time_slot_start': timeSlot.slotStart,
            'time_slot_end': timeSlot.slotEnd,
            'status': 'pending',
          })
          .select()
          .single();

      return Appointment.fromJson(response);
    } catch (e) {
      print('Error booking appointment: $e');
      rethrow;
    }
  }

  // Get user's appointments
  Future<List<Appointment>> getUserAppointments({String? status}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final builder = _supabase
          .from('appointments')
          .select('''
            *,
            departments!inner(
              name,
              icon
            )
          ''')
          .eq('user_id', userId);

      final filteredBuilder = status != null ? builder.eq('status', status) : builder;

      final response = await filteredBuilder
          .order('appointment_date', ascending: false)
          .order('time_slot_start', ascending: false);

      return (response as List).map((json) {
        final dept = json['departments'] as Map<String, dynamic>;
        return Appointment.fromJson({
          ...json,
          'department_name': dept['name'],
          'department_icon': dept['icon'],
        });
      }).toList();
    } catch (e) {
      print('Error fetching appointments: $e');
      rethrow;
    }
  }

  // Get upcoming appointments (pending status, future dates)
  Future<List<Appointment>> getUpcomingAppointments() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final today = DateTime.now().toIso8601String().split('T')[0];

      final response = await _supabase
          .from('appointments')
          .select('''
            *,
            departments!inner(
              name,
              icon
            )
          ''')
          .eq('user_id', userId)
          .eq('status', 'pending')
          .gte('appointment_date', today)
          .order('appointment_date', ascending: true)
          .order('time_slot_start', ascending: true);

      return (response as List).map((json) {
        final dept = json['departments'] as Map<String, dynamic>;
        return Appointment.fromJson({
          ...json,
          'department_name': dept['name'],
          'department_icon': dept['icon'],
        });
      }).toList();
    } catch (e) {
      print('Error fetching upcoming appointments: $e');
      rethrow;
    }
  }

  // Get ongoing appointments (today, pending/checked_in/in_progress)
  Future<List<Appointment>> getOngoingAppointments() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final today = DateTime.now().toIso8601String().split('T')[0];

      final response = await _supabase
          .from('appointments')
          .select('''
            *,
            departments!inner(
              name,
              icon
            )
          ''')
          .eq('user_id', userId)
          .eq('appointment_date', today)
          .inFilter('status', ['pending', 'checked_in', 'in_progress'])
          .order('time_slot_start', ascending: true);

      return (response as List).map((json) {
        final dept = json['departments'] as Map<String, dynamic>;
        return Appointment.fromJson({
          ...json,
          'department_name': dept['name'],
          'department_icon': dept['icon'],
        });
      }).toList();
    } catch (e) {
      print('Error fetching ongoing appointments: $e');
      rethrow;
    }
  }

  // Get appointment by ID
  Future<Appointment?> getAppointmentById(String id) async {
    try {
      final response = await _supabase
          .from('appointments')
          .select('''
            *,
            departments!inner(
              name,
              icon
            )
          ''')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      final dept = response['departments'] as Map<String, dynamic>;
      return Appointment.fromJson({
        ...response,
        'department_name': dept['name'],
        'department_icon': dept['icon'],
      });
    } catch (e) {
      print('Error fetching appointment: $e');
      rethrow;
    }
  }

  // Cancel appointment
  Future<void> cancelAppointment(String id, {String? reason}) async {
    try {
      await _supabase.from('appointments').update({
        'status': 'cancelled',
        'cancelled_at': DateTime.now().toIso8601String(),
        'cancellation_reason': reason,
      }).eq('id', id);
    } catch (e) {
      print('Error cancelling appointment: $e');
      rethrow;
    }
  }

  // Get QR code data for appointment
  String getQRCodeData(Appointment appointment) {
    // Simple format: APPT:{id}:{ticket}:{date}
    final dateStr = appointment.appointmentDate.toIso8601String().split('T')[0];
    return 'APPT:${appointment.id}:${appointment.ticketNumber}:$dateStr';
  }
}
