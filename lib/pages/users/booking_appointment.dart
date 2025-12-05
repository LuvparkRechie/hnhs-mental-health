import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hnhsmind_care/service/appointment_service.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../provider/auth_provider.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  _BookAppointmentScreenState createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  List<Appointment> allBookedAppointments = [];
  bool isLoading = true;

  // Available days and time slots
  final List<String> availableDays = ['Tuesday', 'Thursday', 'Friday'];
  final List<TimeSlot> availableTimeSlots = [
    TimeSlot(start: 8, end: 9, label: '8:00 AM - 9:00 AM'),
    TimeSlot(start: 9, end: 10, label: '9:00 AM - 10:00 AM'),
    TimeSlot(start: 13, end: 14, label: '1:00 PM - 2:00 PM'),
    TimeSlot(start: 14, end: 16, label: '3:00 PM - 4:00 PM'),
  ];

  // Filter variables
  String _selectedFilter = 'All';
  DateTime? _selectedDate;
  final List<String> _filterOptions = [
    'All',
    'PENDING',
    'CONFIRMED',
    'COMPLETED',
    'DECLINED',
  ];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      isLoading = true;
    });

    // Use the new JOIN method
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
              onPressed: () => _showBookingDialog(currentUser),
            ),
          SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          _buildFilterSection(),

          // Date Summary (only show when date is selected)
          if (_selectedDate != null) _buildDateSummary(),

          // Appointments List
          Expanded(
            child: isLoading
                ? _buildLoadingState()
                : filteredAppointments.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _refreshAppointments,
                    child: ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: filteredAppointments.length,
                      itemBuilder: (context, index) {
                        return _buildAppointmentCard(
                          filteredAppointments[index],
                          currentUser,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSummary() {
    final totalAppointments = allBookedAppointments
        .where(
          (appointment) => _isSameDay(appointment.schedule, _selectedDate!),
        )
        .length;

    final bookedSlots = allBookedAppointments
        .where(
          (appointment) => _isSameDay(appointment.schedule, _selectedDate!),
        )
        .map((appointment) => _getTimeSlotLabel(appointment.schedule))
        .toSet();

    final availableSlots = availableTimeSlots.length - bookedSlots.length;

    return Container(
      padding: EdgeInsets.all(16),
      color: AppTheme.surfaceColor.withOpacity(0.8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'Total',
            totalAppointments.toString(),
            AppTheme.primaryRed,
          ),
          _buildSummaryItem(
            'Booked',
            bookedSlots.length.toString(),
            Colors.orange,
          ),
          _buildSummaryItem(
            'Available',
            availableSlots.toString(),
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryRed),
          SizedBox(height: 16),
          Text(
            'Loading appointments...',
            style: GoogleFonts.inter(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: AppTheme.surfaceColor,
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Status Filter Chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _filterOptions.map((filter) {
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = selected ? filter : 'All';
                      });
                    },
                    selectedColor: AppTheme.primaryRed,
                    checkmarkColor: Colors.white,
                    labelStyle: GoogleFonts.inter(
                      color: _selectedFilter == filter
                          ? Colors.white
                          : AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 12),

          // Date Filter
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.lightRed),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.calendar,
                        color: AppTheme.primaryRed,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedDate == null
                              ? 'Filter by schedule date'
                              : 'Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate!)}',
                          style: GoogleFonts.inter(
                            color: _selectedDate == null
                                ? AppTheme.textSecondary
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (_selectedDate != null)
                        IconButton(
                          icon: Icon(
                            Iconsax.close_circle,
                            color: AppTheme.primaryRed,
                            size: 18,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedDate = null;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Iconsax.calendar_search, color: Colors.white),
                  onPressed: _pickDate,
                ),
              ),
            ],
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
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
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
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            SizedBox(height: 12),

            // Schedule Date & Time
            _buildInfoRow(
              Iconsax.calendar_1,
              'Schedule: ${DateFormat('EEEE, MMM dd, yyyy • hh:mm a').format(appointment.schedule)}',
            ),
            SizedBox(height: 8),

            // Booking Date & Time
            _buildInfoRow(
              Iconsax.clock,
              'Booked: ${DateFormat('MMM dd, yyyy • hh:mm a').format(appointment.bookingTime)}',
            ),
            SizedBox(height: 8),

            // Time Slot
            _buildInfoRow(
              Iconsax.clock,
              'Time Slot: ${_getTimeSlotLabel(appointment.schedule)}',
            ),

            // Notes
            if (appointment.notes != null && appointment.notes!.isNotEmpty)
              Column(
                children: [
                  SizedBox(height: 8),
                  _buildInfoRow(Iconsax.note, 'Notes: ${appointment.notes}'),
                ],
              ),

            // Action Buttons
            if (canCancel && appointment.status == 'PENDING')
              Column(
                children: [
                  SizedBox(height: 12),
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
        SizedBox(width: 8),
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
          SizedBox(height: 16),
          Text(
            'No appointments found',
            style: GoogleFonts.poppins(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
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

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppTheme.primaryRed,
            colorScheme: ColorScheme.light(primary: AppTheme.primaryRed),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _showBookingDialog(User currentUser) {
    showDialog(
      context: context,
      builder: (context) => BookingDialog(
        availableDays: availableDays,
        availableTimeSlots: availableTimeSlots,
        bookedAppointments: allBookedAppointments,
        currentUser: currentUser,
        onAppointmentBooked: _refreshAppointments,
      ),
    );
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
          content: Text('Appointment cancelled successfully'),
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

class BookingDialog extends StatefulWidget {
  final List<String> availableDays;
  final List<TimeSlot> availableTimeSlots;
  final List<Appointment> bookedAppointments;
  final User currentUser;
  final VoidCallback onAppointmentBooked;

  const BookingDialog({
    super.key,
    required this.availableDays,
    required this.availableTimeSlots,
    required this.bookedAppointments,
    required this.currentUser,
    required this.onAppointmentBooked,
  });

  @override
  _BookingDialogState createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  DateTime? _selectedDate;
  TimeSlot? _selectedTimeSlot;
  final TextEditingController _notesController = TextEditingController();
  bool isBooking = false;
  bool isCheckingDuplicate = false;
  bool hasDuplicateBooking = false;
  Appointment? existingAppointment;

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _isTimeSlotBooked(TimeSlot slot) {
    if (_selectedDate == null) return false;

    final now = DateTime.now();

    // Check if the selected date is today and the time slot has passed
    final isToday = _isSameDay(_selectedDate!, now);
    if (isToday) {
      final slotStartTime = DateTime(
        now.year,
        now.month,
        now.day,
        slot.start,
        0,
        0,
      );

      // If current time is after the slot start time, disable it
      if (now.isAfter(slotStartTime)) {
        return true; // Slot has passed, treat as "booked" (unavailable)
      }
    }

    return widget.bookedAppointments.any((appointment) {
      final isSameDay =
          _selectedDate!.year == appointment.schedule.year &&
          _selectedDate!.month == appointment.schedule.month &&
          _selectedDate!.day == appointment.schedule.day;

      final isSameTimeSlot = appointment.schedule.hour == slot.start;

      return isSameDay && isSameTimeSlot;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Book New Appointment',
        style: GoogleFonts.poppins(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Date',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                border: Border.all(color: AppTheme.lightRed),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.calendar, color: AppTheme.primaryRed),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedDate == null
                              ? 'Choose a date (Tue, Thu, Fri only)'
                              : DateFormat(
                                  'EEEE, MMM dd, yyyy',
                                ).format(_selectedDate!),
                          style: GoogleFonts.inter(
                            color: _selectedDate == null
                                ? AppTheme.textSecondary
                                : AppTheme.textPrimary,
                          ),
                        ),
                        if (_selectedDate != null &&
                            _isSameDay(_selectedDate!, DateTime.now())) ...[
                          SizedBox(height: 4),
                          Text(
                            'Booking for today - only future time slots are available',
                            style: GoogleFonts.inter(
                              color: Colors.orange,
                              fontSize: 11,
                            ),
                          ),
                        ],
                        if (hasDuplicateBooking && existingAppointment != null)
                          Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'You already have a ${existingAppointment!.status.toLowerCase()} appointment at ${_formatTimeForDisplay(existingAppointment!.schedule)}',
                              style: GoogleFonts.inter(
                                color: AppTheme.dangerColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isCheckingDuplicate)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppTheme.primaryRed),
                      ),
                    )
                  else if (hasDuplicateBooking)
                    Icon(
                      Iconsax.info_circle,
                      color: AppTheme.dangerColor,
                      size: 20,
                    )
                  else if (_selectedDate != null)
                    Icon(Iconsax.tick_circle, color: Colors.green, size: 20)
                  else
                    IconButton(
                      icon: Icon(
                        Iconsax.calendar_edit,
                        color: AppTheme.primaryRed,
                      ),
                      onPressed: _selectDate,
                    ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Duplicate booking warning
            if (hasDuplicateBooking)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lightRed.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.dangerColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.info_circle,
                      color: AppTheme.dangerColor,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You can only book one appointment per day. Please choose a different date.',
                        style: GoogleFonts.inter(
                          color: AppTheme.dangerColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (hasDuplicateBooking) SizedBox(height: 12),

            Text(
              'Available Time Slots',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            if (_selectedDate != null && !hasDuplicateBooking)
              _buildTimeSlotsGrid(),
            if (_selectedDate == null)
              Text(
                'Please select a date first',
                style: GoogleFonts.inter(color: AppTheme.textSecondary),
              ),
            if (_selectedDate != null && hasDuplicateBooking)
              Text(
                'Clear the duplicate booking to select time slots',
                style: GoogleFonts.inter(color: AppTheme.textSecondary),
              ),

            SizedBox(height: 20),
            Text(
              'Additional Notes (Optional)',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              enabled: !hasDuplicateBooking,
              decoration: InputDecoration(
                hintText: 'Any specific concerns or notes...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.lightRed),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryRed),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isBooking ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(color: AppTheme.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: isBooking || hasDuplicateBooking
              ? null
              : (_canProceedWithBooking() ? _bookAppointment : null),
          style: ElevatedButton.styleFrom(
            backgroundColor: hasDuplicateBooking
                ? Colors.grey
                : AppTheme.primaryRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isBooking
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(
                  hasDuplicateBooking
                      ? 'Date Already Booked'
                      : 'Book Appointment',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotsGrid() {
    final availableSlots = widget.availableTimeSlots.where((slot) {
      return !_isTimeSlotBooked(slot);
    }).toList();

    final unavailableSlots = widget.availableTimeSlots.where((slot) {
      return _isTimeSlotBooked(slot);
    }).toList();

    // Separate unavailable slots into booked slots and time-passed slots
    final bookedSlots = unavailableSlots.where((slot) {
      if (_selectedDate == null) return false;
      return widget.bookedAppointments.any((appointment) {
        final isSameDay =
            _selectedDate!.year == appointment.schedule.year &&
            _selectedDate!.month == appointment.schedule.month &&
            _selectedDate!.day == appointment.schedule.day;
        final isSameTimeSlot = appointment.schedule.hour == slot.start;
        return isSameDay && isSameTimeSlot;
      });
    }).toList();

    final timePassedSlots = unavailableSlots.where((slot) {
      if (_selectedDate == null) return false;

      final now = DateTime.now();
      final isToday = _isSameDay(_selectedDate!, now);

      if (isToday) {
        final slotStartTime = DateTime(
          now.year,
          now.month,
          now.day,
          slot.start,
          0,
          0,
        );
        return now.isAfter(slotStartTime);
      }
      return false;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableSlots.map((slot) {
            return ChoiceChip(
              label: Text(slot.label),
              selected: _selectedTimeSlot == slot,
              onSelected: (selected) {
                setState(() {
                  _selectedTimeSlot = selected ? slot : null;
                });
              },
              selectedColor: AppTheme.primaryRed,
              labelStyle: GoogleFonts.inter(
                color: _selectedTimeSlot == slot
                    ? Colors.white
                    : AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            );
          }).toList(),
        ),

        if (unavailableSlots.isNotEmpty) ...[
          SizedBox(height: 16),
          Text(
            'Unavailable Slots:',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 8),

          // Show booked slots
          if (bookedSlots.isNotEmpty) ...[
            Text(
              'Already Booked:',
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
            SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: bookedSlots.map((slot) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.lightRed.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.lightRed),
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

          // Show time-passed slots
          if (timePassedSlots.isNotEmpty) ...[
            SizedBox(height: bookedSlots.isNotEmpty ? 8 : 0),
            Text(
              'Time Has Passed:',
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
            SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: timePassedSlots.map((slot) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Text(
                    slot.label,
                    style: GoogleFonts.inter(
                      color: Colors.grey,
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
      ],
    );
  }

  bool _canProceedWithBooking() {
    if (_selectedDate == null ||
        _selectedTimeSlot == null ||
        hasDuplicateBooking) {
      return false;
    }

    // Additional check: don't allow booking if the time slot has passed for today
    final now = DateTime.now();
    final isToday = _isSameDay(_selectedDate!, now);

    if (isToday) {
      final slotStartTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTimeSlot!.start,
        0,
        0,
      );

      if (now.isAfter(slotStartTime)) {
        return false; // Slot has passed, can't book
      }
    }

    return true;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
      selectableDayPredicate: (DateTime day) {
        final dayName = DateFormat('EEEE').format(day);
        return widget.availableDays.contains(dayName);
      },
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppTheme.primaryRed,
            colorScheme: ColorScheme.light(primary: AppTheme.primaryRed),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeSlot = null;
        hasDuplicateBooking = false;
        existingAppointment = null;
        isCheckingDuplicate = true;
      });

      // Check for duplicate booking
      await _checkForDuplicateBooking();
    }
  }

  Future<void> _checkForDuplicateBooking() async {
    if (_selectedDate == null) return;

    final duplicateCheck = await AppointmentService.checkDuplicateBooking(
      userId: widget.currentUser.id,
      date: _selectedDate!,
    );

    setState(() {
      isCheckingDuplicate = false;
    });

    if (duplicateCheck['success'] == true &&
        duplicateCheck['hasDuplicate'] == true) {
      setState(() {
        hasDuplicateBooking = true;
        existingAppointment = duplicateCheck['existingAppointment'] != null
            ? Appointment(
                id: duplicateCheck['existingAppointment']['id'].toString(),
                userName: widget.currentUser.username,
                schedule: DateFormat('yyyy-MM-dd HH:mm:ss').parse(
                  '${duplicateCheck['existingAppointment']['appointment_date']} '
                  '${duplicateCheck['existingAppointment']['appointment_time']}',
                ),
                bookingTime: DateTime.parse(
                  duplicateCheck['existingAppointment']['created_at'],
                ).toLocal(), // Convert to local time
                status: duplicateCheck['existingAppointment']['status'],
                userId: widget.currentUser.id,
                notes: duplicateCheck['existingAppointment']['notes'],
              )
            : null;
      });
    } else {
      setState(() {
        hasDuplicateBooking = false;
        existingAppointment = null;
      });
    }
  }

  String _formatTimeForDisplay(DateTime schedule) {
    return DateFormat('hh:mm a').format(schedule);
  }

  Future<void> _bookAppointment() async {
    if (!_canProceedWithBooking()) return;

    setState(() {
      isBooking = true;
    });

    final response = await AppointmentService.bookAppointment(
      userId: widget.currentUser.id,
      date: _selectedDate!,
      time: TimeOfDay(hour: _selectedTimeSlot!.start, minute: 0),
      notes: _notesController.text.trim(),
    );

    setState(() {
      isBooking = false;
    });

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment booked successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onAppointmentBooked();
      Navigator.pop(context);
    } else {
      String errorMessage = response['message'] ?? 'Failed to book appointment';

      // Handle duplicate booking error specifically
      if (response['error'] == 'duplicate_booking') {
        setState(() {
          hasDuplicateBooking = true;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }
}

class TimeSlot {
  final int start;
  final int end;
  final String label;

  TimeSlot({required this.start, required this.end, required this.label});
}

class Appointment {
  final String id;
  final String userName;
  final DateTime schedule;
  final DateTime bookingTime;
  final String status;
  final String userId;
  final String? notes;

  Appointment({
    required this.id,
    required this.userName,
    required this.schedule,
    required this.bookingTime,
    required this.status,
    required this.userId,
    this.notes,
  });
}
