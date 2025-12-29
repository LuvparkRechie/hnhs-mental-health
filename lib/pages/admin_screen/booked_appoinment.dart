import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hnhsmind_care/app_theme.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

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

  // Add these for date filter
  DateTime? _selectedFilterDate;
  final TextEditingController _dateFilterController = TextEditingController();

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
      print("response all appointment $response");
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
    List<dynamic> filtered = allAppointments;

    // Filter by date if selected
    if (_selectedFilterDate != null) {
      filtered = filtered.where((appt) {
        final appointmentDate = DateTime.parse(appt['appointment_date']);
        return appointmentDate.year == _selectedFilterDate!.year &&
            appointmentDate.month == _selectedFilterDate!.month &&
            appointmentDate.day == _selectedFilterDate!.day;
      }).toList();
    }

    // Sort appointments: PENDING first, then by time
    filtered.sort((a, b) {
      final statusA = a['status'] ?? '';
      final statusB = b['status'] ?? '';
      final timeA = a['appointment_time'] ?? '';
      final timeB = b['appointment_time'] ?? '';

      // PENDING appointments come first
      if (statusA == 'PENDING' && statusB != 'PENDING') return -1;
      if (statusA != 'PENDING' && statusB == 'PENDING') return 1;

      // Then sort by time
      return timeA.compareTo(timeB);
    });

    setState(() {
      filteredAppointments = filtered;
    });
  }

  Future<void> _selectFilterDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedFilterDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppTheme.primaryRed,
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryRed,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedFilterDate) {
      setState(() {
        _selectedFilterDate = picked;
        _dateFilterController.text = DateFormat('MMM dd, yyyy').format(picked);
      });
      _filterAppointments();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedFilterDate = null;
      _dateFilterController.clear();
    });
    _filterAppointments();
  }

  void _showSnackbar(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.dangerColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.lightRed),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Appointments",
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Manage all appointments",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLoading)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.lightRed,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${filteredAppointments.length}",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkRed,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Date Filter Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.lightRed),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Filter by Date",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectFilterDate(context),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.lightRed,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Iconsax.calendar_1,
                                        size: 20,
                                        color: AppTheme.primaryRed,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _selectedFilterDate == null
                                              ? "Select date"
                                              : DateFormat(
                                                  'EEEE, MMM dd, yyyy',
                                                ).format(_selectedFilterDate!),
                                          style: GoogleFonts.inter(
                                            color: _selectedFilterDate == null
                                                ? AppTheme.textSecondary
                                                : AppTheme.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (_selectedFilterDate != null) ...[
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: _clearDateFilter,
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryRed,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Appointments List
            Expanded(
              child: isLoading
                  ? _buildLoadingState()
                  : filteredAppointments.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredAppointments.length,
                      itemBuilder: (context, index) {
                        return _buildAppointmentCard(
                          filteredAppointments[index],
                          index,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryRed, strokeWidth: 2),
          const SizedBox(height: 20),
          Text(
            'Loading appointments...',
            style: GoogleFonts.inter(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.lightRed,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _selectedFilterDate == null
                    ? Icons.event_note
                    : Icons.search_off,
                size: 48,
                color: AppTheme.darkRed,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _selectedFilterDate == null
                  ? 'No appointments yet'
                  : 'No appointments on selected date',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedFilterDate == null
                  ? 'Appointments will appear here once booked'
                  : 'Try selecting a different date',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_selectedFilterDate != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _clearDateFilter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
                child: Text(
                  'Clear date filter',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment, int index) {
    final status = appointment['status'] ?? 'PENDING';
    final expiresAt = appointment['expires_at'];
    final isExpired =
        expiresAt != null &&
        DateTime.now().isAfter(DateTime.parse(expiresAt)) &&
        status == 'PENDING';

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Ribbon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isExpired ? 'EXPIRED' : status,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatTime(appointment['appointment_time']),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryRed,
                  ),
                ),
              ],
            ),
          ),

          // Appointment Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _formatDisplayDate(
                        DateTime.parse(appointment['appointment_date']),
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Student Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.lightRed,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        color: AppTheme.darkRed,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment['username'] ?? 'Unknown User',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            appointment['email'] ?? 'No email',
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Notes
                if (appointment['notes'] != "null" &&
                    appointment['notes'].isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notes',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          appointment['notes'],
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Expiry Warning
                if (isExpired) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This booking has expired',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Actions
                const SizedBox(height: 20),
                _buildActionButtons(appointment, status, isExpired),
              ],
            ),
          ),
        ],
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
        child: ElevatedButton(
          onPressed: () => _removeExpiredAppointment(appointment),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.dangerColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Remove Expired',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Accept',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _declineAppointment(appointment),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.dangerColor,
                  side: const BorderSide(color: AppTheme.dangerColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Decline',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Mark as Done',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showRescheduleDialog(appointment),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.warningColor,
                  side: const BorderSide(color: AppTheme.warningColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Reschedule',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Mark Done',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showRescheduleDialog(appointment),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.warningColor,
                  side: const BorderSide(color: AppTheme.warningColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Reschedule',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
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
              side: const BorderSide(color: AppTheme.warningColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Reschedule',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        );
    }
  }

  // Helper Methods using your AppTheme colors
  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return AppTheme.warningColor; // Amber
      case 'CONFIRMED':
        return AppTheme.accentColor; // Green
      case 'RESCHEDULED':
        return AppTheme.primaryRed; // Red
      case 'COMPLETED':
        return Colors.green; // Darker green
      case 'CANCELLED':
        return AppTheme.dangerColor; // Red
      case 'DECLINED':
        return Colors.grey; // Grey
      case 'EXPIRED':
        return AppTheme.dangerColor; // Red
      default:
        return AppTheme.textSecondary; // Grey
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

  String _formatDisplayDate(DateTime date) {
    return DateFormat('EEEE, MMM dd, yyyy').format(date);
  }

  // RESCHEDULE DIALOG METHODS (RESTORED)
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

  // RESCHEDULE HELPER METHODS (RESTORED)
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
}

class TimeSlot {
  final int start;
  final int end;
  final String label;

  TimeSlot({required this.start, required this.end, required this.label});
}
