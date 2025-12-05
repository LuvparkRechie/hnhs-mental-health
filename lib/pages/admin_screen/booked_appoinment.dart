import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:hnhsmind_care/app_theme.dart';

import '../../service/appointment_service.dart';

class BookedAppointment extends StatefulWidget {
  const BookedAppointment({super.key});

  @override
  State<BookedAppointment> createState() => _BookedAppointmentState();
}

class _BookedAppointmentState extends State<BookedAppointment> {
  List<dynamic> allAppointments = [];
  List<dynamic> filteredAppointments = [];
  bool isLoading = true;
  String selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String _selectedTab = 'PENDING'; // Default to PENDING tab

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final response = await AppointmentService.getAllAppointmentsWithUsers();

      if (mounted) {
        if (response['success'] == true) {
          final allAppts = List.from(response['data'] ?? []);
          setState(() {
            allAppointments = allAppts;
            _filterAppointments();
          });
        } else {
          setState(() {
            allAppointments = [];
            filteredAppointments = [];
          });
          _showSnackbar(
            response['message'] ?? 'Failed to load appointments',
            true,
          );
        }
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          allAppointments = [];
          filteredAppointments = [];
        });
        _showSnackbar('Error loading appointments', true);
      }
    }
  }

  void _filterAppointments() {
    setState(() {
      filteredAppointments =
          allAppointments.where((appointment) {
            final matchesDate = appointment['appointment_date'] == selectedDate;
            final matchesStatus = appointment['status'] == _selectedTab;

            return matchesDate && matchesStatus;
          }).toList()..sort((a, b) {
            final timeA = a['appointment_time'] ?? '';
            final timeB = b['appointment_time'] ?? '';
            return timeA.compareTo(timeB);
          });
    });
  }

  void _showSnackbar(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.dangerColor : AppTheme.accentColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Column(
        children: [
          // Simple Tab Buttons
          _buildTabButtons(),

          // Appointments List
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryRed,
                    ),
                  )
                : filteredAppointments.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: filteredAppointments.length,
                    itemBuilder: (context, index) {
                      return _buildAppointmentCard(filteredAppointments[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButtons() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _buildTabButton('PENDING', 'Pending')),
          SizedBox(width: 12),
          Expanded(child: _buildTabButton('CONFIRMED', 'Confirmed')),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab, String label) {
    final isSelected = _selectedTab == tab;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedTab = tab;
          _filterAppointments();
        });
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : AppTheme.textPrimary,
        backgroundColor: isSelected
            ? AppTheme.primaryRed
            : AppTheme.surfaceColor,
        padding: EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: isSelected ? 2 : 0,
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedTab == 'PENDING'
                ? Icons.pending_actions
                : Icons.event_available,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            _selectedTab == 'PENDING'
                ? 'No pending appointments'
                : 'No confirmed appointments',
            style: GoogleFonts.poppins(
              color: AppTheme.textPrimary,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _selectedTab == 'PENDING'
                ? 'Pending appointments will appear here'
                : 'Confirmed appointments will appear here',
            style: GoogleFonts.inter(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final status = appointment['status'] ?? 'PENDING';
    final expiresAt = appointment['expires_at'];
    final isExpired =
        expiresAt != null &&
        DateTime.now().isAfter(DateTime.parse(expiresAt)) &&
        status == 'PENDING';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(status, isExpired),
                Text(
                  _formatTime(appointment['appointment_time']),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryRed,
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Student Info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.lightRed,
                  child: Icon(
                    Icons.person,
                    color: AppTheme.primaryRed,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment['username'] ?? 'Unknown User',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        appointment['email'] ?? 'No email',
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Notes
            if (appointment['notes'] != null &&
                appointment['notes'].isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                appointment['notes'],
                style: GoogleFonts.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                ),
              ),
            ],

            // Expiry Warning
            if (isExpired) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.lightRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, size: 16, color: AppTheme.dangerColor),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Booking expired',
                        style: GoogleFonts.inter(
                          color: AppTheme.dangerColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Actions
            SizedBox(height: 16),
            _buildActionButtons(appointment, status, isExpired),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isExpired) {
    Color statusColor = _getStatusColor(status);
    String displayStatus = isExpired ? 'EXPIRED' : status;

    if (isExpired) {
      statusColor = AppTheme.dangerColor;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor),
      ),
      child: Text(
        displayStatus,
        style: GoogleFonts.inter(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    Map<String, dynamic> appointment,
    String status,
    bool isExpired,
  ) {
    if (isExpired) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => _removeExpiredAppointment(appointment),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.dangerColor,
            side: BorderSide(color: AppTheme.dangerColor),
          ),
          child: Text('Remove Expired'),
        ),
      );
    }

    switch (status) {
      case 'PENDING':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _acceptAppointment(appointment),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                ),
                child: Text('Accept'),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _declineAppointment(appointment),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.dangerColor,
                  side: BorderSide(color: AppTheme.dangerColor),
                ),
                child: Text('Decline'),
              ),
            ),
          ],
        );

      case 'CONFIRMED':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _markAsDone(appointment),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                ),
                child: Text('Mark Done'),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showRescheduleDialog(appointment),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.warningColor,
                  side: BorderSide(color: AppTheme.warningColor),
                ),
                child: Text('Reschedule'),
              ),
            ),
          ],
        );

      case 'RESCHEDULED':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _markAsDone(appointment),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                ),
                child: Text('Mark Done'),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showRescheduleDialog(appointment),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.warningColor,
                  side: BorderSide(color: AppTheme.warningColor),
                ),
                child: Text('Reschedule'),
              ),
            ),
          ],
        );

      default:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _showRescheduleDialog(appointment),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.warningColor,
              side: BorderSide(color: AppTheme.warningColor),
            ),
            child: Text('Reschedule'),
          ),
        );
    }
  }

  // Helper Methods
  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return AppTheme.warningColor;
      case 'CONFIRMED':
        return AppTheme.accentColor;
      case 'RESCHEDULED':
        return AppTheme.primaryRed;
      case 'COMPLETED':
        return AppTheme.textSecondary;
      case 'CANCELLED':
        return AppTheme.dangerColor;
      case 'EXPIRED':
        return AppTheme.dangerColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatTime(String time) {
    try {
      final timeFormat = DateFormat('HH:mm:ss');
      final dateTime = timeFormat.parse(time);
      return DateFormat('h:mm a').format(dateTime);
    } catch (e) {
      return time;
    }
  }

  // Action Methods
  Future<void> _acceptAppointment(Map<String, dynamic> appointment) async {
    final appointmentId = appointment['id'].toString();
    final response = await AppointmentService.confirmAppointment(appointmentId);

    if (response['success'] == true) {
      _showSnackbar('Appointment accepted', false);
      _loadAppointments();
    } else {
      _showSnackbar(response['message'] ?? 'Failed to accept', true);
    }
  }

  Future<void> _declineAppointment(Map<String, dynamic> appointment) async {
    final appointmentId = appointment['id'].toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Decline Appointment'),
        content: Text('Are you sure you want to decline this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
            ),
            onPressed: () async {
              Navigator.pop(context);
              final response = await AppointmentService.updateAppointmentStatus(
                appointmentId,
                'DECLINED',
              );

              if (response['success'] == true) {
                _showSnackbar('Appointment declined', false);
                _loadAppointments();
              } else {
                _showSnackbar(response['message'] ?? 'Failed to decline', true);
              }
            },
            child: Text('Decline'),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsDone(Map<String, dynamic> appointment) async {
    final appointmentId = appointment['id'].toString();
    final response = await AppointmentService.updateAppointmentStatus(
      appointmentId,
      'COMPLETED',
    );

    if (response['success'] == true) {
      _showSnackbar('Appointment completed', false);
      _loadAppointments();
    } else {
      _showSnackbar(response['message'] ?? 'Failed to complete', true);
    }
  }

  Future<void> _removeExpiredAppointment(
    Map<String, dynamic> appointment,
  ) async {
    final appointmentId = appointment['id'].toString();
    final response = await AppointmentService.updateAppointmentStatus(
      appointmentId,
      'CANCELLED',
    );

    if (response['success'] == true) {
      _showSnackbar('Expired appointment removed', false);
      _loadAppointments();
    } else {
      _showSnackbar('Failed to remove', true);
    }
  }

  void _showRescheduleDialog(Map<String, dynamic> appointment) {
    DateTime selectedDate = DateTime.now().add(Duration(days: 1));
    TimeSlot? selectedTimeSlot;
    final TextEditingController reasonController = TextEditingController();
    bool isRescheduling = false;

    final List<String> availableDays = ['Tuesday', 'Thursday', 'Friday'];
    final List<TimeSlot> availableTimeSlots = [
      TimeSlot(start: 8, end: 9, label: '8:00 AM - 9:00 AM'),
      TimeSlot(start: 9, end: 10, label: '9:00 AM - 10:00 AM'),
      TimeSlot(start: 13, end: 14, label: '1:00 PM - 2:00 PM'),
      TimeSlot(start: 14, end: 16, label: '3:00 PM - 4:00 PM'),
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Reschedule Appointment',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.lightRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Appointment:',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_formatDisplayDate(DateTime.parse(appointment['appointment_date']))} at ${_formatTime(appointment['appointment_time'])}',
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Status: ${appointment['status']}',
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                Text(
                  'New Date:',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.textSecondary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                        selectableDayPredicate: (DateTime day) {
                          final dayName = DateFormat('EEEE').format(day);
                          return availableDays.contains(dayName);
                        },
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.light().copyWith(
                              primaryColor: AppTheme.primaryRed,
                              colorScheme: ColorScheme.light(
                                primary: AppTheme.primaryRed,
                              ),
                              buttonTheme: ButtonThemeData(
                                textTheme: ButtonTextTheme.primary,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() {
                          selectedDate = picked;
                          selectedTimeSlot = null;
                        });
                      }
                    },
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.calendar_1,
                          size: 20,
                          color: AppTheme.primaryRed,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            DateFormat(
                              'EEEE, MMM dd, yyyy',
                            ).format(selectedDate),
                            style: GoogleFonts.inter(),
                          ),
                        ),
                        Icon(
                          Iconsax.arrow_down_1,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                Text(
                  'Available Time Slots:',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                _buildTimeSlotsGrid(
                  availableTimeSlots: availableTimeSlots,
                  selectedDate: selectedDate,
                  selectedTimeSlot: selectedTimeSlot,
                  onTimeSlotSelected: (slot) {
                    setState(() {
                      selectedTimeSlot = slot;
                    });
                  },
                  currentAppointmentId: appointment['id'].toString(),
                ),
                SizedBox(height: 16),

                Text(
                  'Reason for Rescheduling (Optional):',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter reason for rescheduling...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.textSecondary),
                    ),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isRescheduling ? null : () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isRescheduling
                  ? null
                  : () async {
                      if (selectedTimeSlot == null) {
                        _showSnackbar('Please select a time slot', true);
                        return;
                      }

                      final now = DateTime.now();
                      final selectedDateTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTimeSlot!.start,
                        0,
                      );

                      if (selectedDateTime.isBefore(now)) {
                        _showSnackbar(
                          'Cannot schedule appointment in the past',
                          true,
                        );
                        return;
                      }

                      setState(() => isRescheduling = true);

                      final appointmentId = appointment['id'].toString();
                      final response =
                          await AppointmentService.rescheduleAppointment(
                            appointmentId: appointmentId,
                            newDate: selectedDate,
                            newTime: TimeOfDay(
                              hour: selectedTimeSlot!.start,
                              minute: 0,
                            ),
                            reason: reasonController.text.isNotEmpty
                                ? reasonController.text
                                : null,
                          );

                      if (mounted) {
                        setState(() => isRescheduling = false);

                        if (response['success'] == true) {
                          Navigator.pop(context);
                          _showSnackbar(
                            'Appointment rescheduled successfully!',
                            false,
                          );
                          _loadAppointments();
                        } else {
                          _showSnackbar(
                            response['message'] ?? 'Failed to reschedule',
                            true,
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedTimeSlot == null
                    ? Colors.grey
                    : AppTheme.warningColor,
              ),
              child: isRescheduling
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('Reschedule'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotsGrid({
    required List<TimeSlot> availableTimeSlots,
    required DateTime selectedDate,
    required TimeSlot? selectedTimeSlot,
    required Function(TimeSlot) onTimeSlotSelected,
    required String currentAppointmentId,
  }) {
    final availableSlots = availableTimeSlots.where((slot) {
      return !_isTimeSlotBookedForReschedule(
        slot: slot,
        selectedDate: selectedDate,
        currentAppointmentId: currentAppointmentId,
      );
    }).toList();

    final bookedSlots = availableTimeSlots.where((slot) {
      return _isTimeSlotBookedForReschedule(
        slot: slot,
        selectedDate: selectedDate,
        currentAppointmentId: currentAppointmentId,
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (availableSlots.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableSlots.map((slot) {
              return ChoiceChip(
                label: Text(slot.label),
                selected: selectedTimeSlot == slot,
                onSelected: (selected) {
                  onTimeSlotSelected(slot);
                },
                selectedColor: AppTheme.primaryRed,
                labelStyle: GoogleFonts.inter(
                  color: selectedTimeSlot == slot
                      ? Colors.white
                      : AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList(),
          ),

        if (availableSlots.isEmpty)
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.lightRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'No available time slots for selected date',
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),

        if (bookedSlots.isNotEmpty) ...[
          SizedBox(height: 12),
          Text(
            'Unavailable Slots:',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: bookedSlots.map((slot) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.lightRed,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  slot.label,
                  style: GoogleFonts.inter(
                    color: AppTheme.dangerColor,
                    fontSize: 12,
                    decoration: TextDecoration.lineThrough,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  bool _isTimeSlotBookedForReschedule({
    required TimeSlot slot,
    required DateTime selectedDate,
    required String currentAppointmentId,
  }) {
    return allAppointments.any((appointment) {
      final appointmentId = appointment['id'].toString();
      final appointmentDate = DateTime.parse(appointment['appointment_date']);

      if (appointmentId == currentAppointmentId) return false;

      final isSameDay =
          selectedDate.year == appointmentDate.year &&
          selectedDate.month == appointmentDate.month &&
          selectedDate.day == appointmentDate.day;

      if (!isSameDay) return false;

      final appointmentTime = appointment['appointment_time'];
      try {
        final timeParts = appointmentTime.split(':');
        if (timeParts.isNotEmpty) {
          final hour = int.parse(timeParts[0]);
          return hour == slot.start;
        }
      } catch (e) {
        return false;
      }

      return false;
    });
  }

  String _formatDisplayDate(DateTime date) {
    return DateFormat('EEEE, MMM dd, yyyy').format(date);
  }
}

class TimeSlot {
  final int start;
  final int end;
  final String label;

  TimeSlot({required this.start, required this.end, required this.label});
}
