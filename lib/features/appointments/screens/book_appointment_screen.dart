import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/gradient_button.dart';
import '../../../core/services/appointments_repository.dart';
import '../../../models/time_slot.dart';
import '../../../models/department_settings.dart';

/// Book appointment screen - schedule a new appointment
class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _purposeController = TextEditingController();
  final _repository = AppointmentsRepository();

  String? _selectedDepartmentId;
  String? _selectedDepartmentName;
  DateTime? _selectedDate;
  TimeSlot? _selectedTimeSlot;
  DepartmentSettings? _departmentSettings;

  List<Map<String, dynamic>> _departments = [];
  List<TimeSlot> _timeSlots = [];
  bool _isLoading = true;
  bool _isLoadingSlots = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    try {
      final departments = await _repository
          .getDepartmentsAcceptingAppointments();
      setState(() {
        _departments = departments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading departments: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      // TODO: Load user profile and pre-fill name and contact
      // For now, leave empty for user to fill
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _loadTimeSlots() async {
    if (_selectedDepartmentId == null || _selectedDate == null) return;

    setState(() => _isLoadingSlots = true);

    try {
      // Check if date is closed
      final isClosed = await _repository.isDateClosed(
        _selectedDepartmentId!,
        _selectedDate!,
      );

      if (isClosed) {
        setState(() => _isLoadingSlots = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This department is closed on the selected date'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      // Get time slots
      final slots = await _repository.getAvailableTimeSlots(
        _selectedDepartmentId!,
        _selectedDate!,
      );

      setState(() {
        _timeSlots = slots;
        _selectedTimeSlot = null; // Reset selection
        _isLoadingSlots = false;
      });
    } catch (e) {
      setState(() => _isLoadingSlots = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading time slots: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    if (_selectedDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a department first'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Load department settings if not loaded
    if (_departmentSettings == null) {
      final settings = await _repository.getDepartmentSettings(
        _selectedDepartmentId!,
      );
      setState(() => _departmentSettings = settings);
    }

    if (_departmentSettings == null) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _departmentSettings!.earliestBookingDate,
      firstDate: _departmentSettings!.earliestBookingDate,
      lastDate: _departmentSettings!.latestBookingDate,
      selectableDayPredicate: (date) {
        return _departmentSettings!.canBookDate(date);
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.capizBlue),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _loadTimeSlots();
    }
  }

  Future<void> _submitAppointment() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_selectedDepartmentId == null ||
        _selectedDate == null ||
        _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select department, date, and time slot'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final appointment = await _repository.bookAppointment(
        departmentId: _selectedDepartmentId!,
        fullName: _nameController.text.trim(),
        contactNumber: _contactController.text.trim(),
        purpose: _purposeController.text.trim(),
        appointmentDate: _selectedDate!,
        timeSlot: _selectedTimeSlot!,
      );

      setState(() => _isSubmitting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Appointment booked! Ticket: ${appointment.ticketNumber}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true); // Return true to indicate success
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error booking appointment: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedTextColor = theme.textTheme.bodyMedium?.color?.withOpacity(0.7);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(title: const Text('Book Appointment')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(title: const Text('Book Appointment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Schedule your visit', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Book an appointment to avoid long queues and ensure prompt service.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: mutedTextColor,
              ),
            ),

            const SizedBox(height: 24),

            // Department selection
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Office/Department',
                hintText: 'Select office to visit',
              ),
              value: _selectedDepartmentId,
              items: _departments.map((dept) {
                return DropdownMenuItem(
                  value: dept['id'] as String,
                  child: Text(dept['name'] as String),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDepartmentId = value;
                  _selectedDepartmentName =
                      _departments.firstWhere((d) => d['id'] == value)['name']
                          as String;
                  _selectedDate = null;
                  _selectedTimeSlot = null;
                  _timeSlots = [];
                  _departmentSettings = null;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a department';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Contact field
            TextFormField(
              controller: _contactController,
              decoration: const InputDecoration(
                labelText: 'Contact Number',
                hintText: '09XX XXX XXXX',
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your contact number';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Purpose field
            TextFormField(
              controller: _purposeController,
              decoration: const InputDecoration(
                labelText: 'Purpose of Visit',
                hintText: 'What do you need assistance with?',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please describe the purpose of your visit';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Date selection
            OutlinedButton.icon(
              onPressed: _selectDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _selectedDate == null
                    ? 'Select Date'
                    : DateFormat('MMMM dd, yyyy').format(_selectedDate!),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 16),

            // Time slot selection
            if (_selectedDate != null) ...[
              const SizedBox(height: 16),
              Text(
                'Available Time Slots',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              if (_isLoadingSlots)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_timeSlots.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No available slots',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Please select a different date',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _timeSlots.map((slot) {
                    final isSelected = _selectedTimeSlot?.id == slot.id;
                    final isFull = slot.isFull;

                    return ChoiceChip(
                      label: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(slot.formattedTimeRange),
                          const SizedBox(height: 2),
                          Text(
                            slot.availabilityText,
                            style: TextStyle(
                              fontSize: 10,
                              color: isFull
                                  ? AppColors.error
                                  : slot.hasLimitedSpots
                                  ? AppColors.warning
                                  : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: isFull
                          ? null
                          : (selected) {
                              setState(() {
                                _selectedTimeSlot = selected ? slot : null;
                              });
                            },
                      backgroundColor: AppColors.backgroundWhite,
                      selectedColor: AppColors.capizGold.withOpacity(0.2),
                      disabledColor: AppColors.gray100,
                      side: BorderSide(
                        color: isFull
                            ? AppColors.gray300
                            : isSelected
                            ? AppColors.capizGold
                            : AppColors.gray300,
                      ),
                    );
                  }).toList(),
                ),
            ],

            const SizedBox(height: 32),

            // Submit button
            GradientButton(
              onPressed: _isSubmitting ? null : _submitAppointment,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Book Appointment'),
            ),
          ],
        ),
      ),
    );
  }
}
