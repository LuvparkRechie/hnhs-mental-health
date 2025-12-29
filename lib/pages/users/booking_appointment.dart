import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hnhsmind_care/pages/users/appointment_screen.dart';
import 'package:hnhsmind_care/service/appointment_service.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_theme.dart';
import '../../provider/auth_provider.dart';
import '../../service/appointment.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  _BookAppointmentScreenState createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  List<Appointment> allBookedAppointments = [];
  bool isLoading = true;

  // Filter variables
  String _selectedFilter = 'All';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      isLoading = true;
    });

    final response = await AppointmentService.getAllAppointmentsWithUsers();

    if (response['success'] == true) {
      final List<dynamic> data = response['data'];
      setState(() {
        allBookedAppointments = data.map((item) {
          return Appointment(
            id: item['id'].toString(),
            userId: item['user_id'].toString(),
            userName: item['username'],
            schedule: AppointmentService.parseAppointmentDateTime(
              item['appointment_date'].toString(),
              item['appointment_time'].toString(),
            ),
            bookingTime: DateTime.parse(item['appointment_date']),
            status: item['status'],
            notes: item['notes'],
          );
        }).toList();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load appointments: ${response['message']}'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }

  Future<void> _refreshAppointments() async {
    await _loadAppointments();
  }

  void _navigateToBookingScreen(User currentUser) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(
          bookedAppointments: allBookedAppointments,
          currentUser: currentUser,
          onAppointmentBooked: _refreshAppointments,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;

    // Filter appointments based on selected filter and date
    final filteredAppointments = allBookedAppointments.where((appointment) {
      final matchesStatus =
          _selectedFilter == 'All' || appointment.status == _selectedFilter;
      final matchesDate =
          _selectedDate == null ||
          _isSameDay(appointment.schedule, _selectedDate!);
      return matchesStatus && matchesDate;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Booked Appointments',
          style: GoogleFonts.poppins(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left, color: AppTheme.primaryRed),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Iconsax.refresh, color: AppTheme.primaryRed),
            onPressed: _refreshAppointments,
          ),
          if (currentUser != null)
            IconButton(
              icon: Icon(Iconsax.calendar_add, color: AppTheme.primaryRed),
              onPressed: () => _navigateToBookingScreen(currentUser),
            ),
          const SizedBox(width: 10),
        ],
      ),
      body: isLoading
          ? _buildLoadingState()
          : filteredAppointments.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _refreshAppointments,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredAppointments.length,
                itemBuilder: (context, index) {
                  return _buildAppointmentCard(
                    filteredAppointments[index],
                    currentUser,
                  );
                },
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryRed),
          const SizedBox(height: 16),
          Text(
            'Loading appointments...',
            style: GoogleFonts.inter(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment, User? currentUser) {
    Color statusColor = _getStatusColor(appointment.status);
    bool canCancel =
        currentUser != null && (currentUser.id == appointment.userId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Name and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  appointment.userName,
                  style: GoogleFonts.poppins(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    appointment.status,
                    style: GoogleFonts.inter(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Schedule Date & Time
            _buildInfoRow(
              Iconsax.calendar_1,
              'Schedule: ${DateFormat('EEEE, MMM dd, yyyy • hh:mm a').format(appointment.schedule)}',
            ),
            const SizedBox(height: 8),

            // Booking Date & Time
            _buildInfoRow(
              Iconsax.clock,
              'Booked: ${DateFormat('MMM dd, yyyy • hh:mm a').format(appointment.bookingTime)}',
            ),
            const SizedBox(height: 8),

            // Time Slot
            _buildInfoRow(
              Iconsax.clock,
              'Time Slot: ${_getTimeSlotLabel(appointment.schedule)}',
            ),

            // Notes
            if (appointment.notes != null && appointment.notes!.isNotEmpty)
              Column(
                children: [
                  const SizedBox(height: 8),
                  _buildInfoRow(Iconsax.note, 'Notes: ${appointment.notes}'),
                ],
              ),

            // Action Buttons
            if (canCancel && appointment.status == 'PENDING')
              Column(
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _cancelAppointment(appointment.id),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.dangerColor,
                            side: BorderSide(color: AppTheme.dangerColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel Appointment',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryRed, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.calendar_remove, size: 80, color: AppTheme.lightRed),
          const SizedBox(height: 16),
          Text(
            'No appointments found',
            style: GoogleFonts.poppins(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedDate == null
                ? 'Try booking a new appointment'
                : 'No appointments found for selected date',
            style: GoogleFonts.inter(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    if (currentUser == null) return;

    final response = await AppointmentService.cancelAppointment(
      appointmentId,
      currentUser.id,
    );

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Appointment cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _refreshAppointments();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel appointment: ${response['message']}'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'CONFIRMED':
        return AppTheme.accentColor;
      case 'COMPLETED':
        return Colors.green;
      case 'DECLINED':
        return AppTheme.dangerColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _getTimeSlotLabel(DateTime schedule) {
    final hour = schedule.hour;
    if (hour == 8) return '8:00 AM - 9:00 AM';
    if (hour == 9) return '9:00 AM - 10:00 AM';
    if (hour == 13) return '1:00 PM - 2:00 PM';
    if (hour == 14) return '3:00 PM - 4:00 PM';
    return 'Unknown';
  }
}
