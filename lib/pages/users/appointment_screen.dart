import 'package:auto_size_text_plus/auto_size_text_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hnhsmind_care/provider/auth_provider.dart';
import 'package:hnhsmind_care/service/appointment.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../app_theme.dart';
import '../../service/appointment_service.dart';
import '../admin_screen/booked_appoinment.dart';

class BookingScreen extends StatefulWidget {
  final List<Appointment> bookedAppointments;
  final User currentUser;
  final VoidCallback onAppointmentBooked;

  const BookingScreen({
    super.key,
    required this.bookedAppointments,
    required this.currentUser,
    required this.onAppointmentBooked,
  });

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _selectedDate;
  TimeSlot? _selectedTimeSlot;
  final TextEditingController _notesController = TextEditingController();
  bool isBooking = false;
  bool isCheckingDuplicate = false;
  bool hasDuplicateBooking = false;
  Appointment? existingAppointment;

  // Available days and time slots
  final List<String> availableDays = ['Tuesday', 'Thursday', 'Friday'];
  final List<TimeSlot> availableTimeSlots = [
    TimeSlot(start: 8, end: 9, label: '8:00 AM - 9:00 AM'),
    TimeSlot(start: 9, end: 10, label: '9:00 AM - 10:00 AM'),
    TimeSlot(start: 13, end: 14, label: '1:00 PM - 2:00 PM'),
    TimeSlot(start: 14, end: 16, label: '3:00 PM - 4:00 PM'),
  ];

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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Book Appointment',
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
          if (isBooking)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppTheme.primaryRed),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateSelector(),
            const SizedBox(height: 20),
            _buildTimeSlotsSection(),
            const SizedBox(height: 20),
            _buildNotesSection(),
            const SizedBox(height: 30),
            _buildBookButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            border: Border.all(color: AppTheme.lightRed),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Iconsax.calendar, color: AppTheme.primaryRed),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedDate == null
                          ? 'Choose a date (Tue, Thu, Fri, Sat only)'
                          : DateFormat(
                              'EEEE, MMM dd, yyyy',
                            ).format(_selectedDate!),
                      style: GoogleFonts.inter(
                        color: _selectedDate == null
                            ? AppTheme.textSecondary
                            : AppTheme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    if (_selectedDate != null &&
                        _isSameDay(_selectedDate!, DateTime.now())) ...[
                      const SizedBox(height: 4),
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
                        padding: const EdgeInsets.only(top: 4),
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
                Icon(Iconsax.info_circle, color: AppTheme.dangerColor, size: 20)
              else if (_selectedDate != null)
                Icon(Iconsax.tick_circle, color: Colors.green, size: 20)
              else
                IconButton(
                  icon: Icon(Iconsax.calendar_edit, color: AppTheme.primaryRed),
                  onPressed: _selectDate,
                ),
            ],
          ),
        ),
        // Duplicate booking warning
        if (hasDuplicateBooking)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
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
                const SizedBox(width: 8),
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
      ],
    );
  }

  Widget _buildTimeSlotsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Time Slots',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
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
      ],
    );
  }

  Widget _buildTimeSlotsGrid() {
    final availableSlots = availableTimeSlots.where((slot) {
      return !_isTimeSlotBooked(slot);
    }).toList();

    final unavailableSlots = availableTimeSlots.where((slot) {
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
          const SizedBox(height: 16),
          Text(
            'Unavailable Slots:',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),

          // Show booked slots
          if (bookedSlots.isNotEmpty) ...[
            Text(
              'Already Booked:',
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: bookedSlots.map((slot) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: timePassedSlots.map((slot) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Notes (Optional)',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
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
    );
  }

  Widget _buildBookButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isBooking || hasDuplicateBooking || !_canProceedWithBooking()
            ? null
            : _bookAppointment,
        style: ElevatedButton.styleFrom(
          backgroundColor: hasDuplicateBooking || !_canProceedWithBooking()
              ? Colors.grey
              : AppTheme.primaryRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
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
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
      ),
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

  DateTime _getNextAllowedDate(DateTime from) {
    DateTime date = from;

    while (true) {
      final dayName = DateFormat('EEEE').format(date);
      if (availableDays.contains(dayName)) {
        return date;
      }
      date = date.add(const Duration(days: 1));
    }
  }

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();

    // ✅ Ensure initialDate satisfies selectableDayPredicate
    final DateTime validInitialDate = _selectedDate ?? _getNextAllowedDate(now);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: validInitialDate, // 🔥 FIX
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      selectableDayPredicate: (DateTime day) {
        final dayName = DateFormat('EEEE').format(day);
        return availableDays.contains(dayName);
      },
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppTheme.primaryRed,
            colorScheme: ColorScheme.light(primary: AppTheme.primaryRed),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
      _selectedTimeSlot = null;
      hasDuplicateBooking = false;
      existingAppointment = null;
      isCheckingDuplicate = true;
    });

    await _checkForDuplicateBooking();
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
      showReminder();
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

  void showReminder() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap a button
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: Row(
              children: [
                Icon(Icons.timer_outlined, color: Colors.orange),
                SizedBox(width: 10),
                Expanded(
                  child: AutoSizeText(
                    'Appointment Reminder',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your appointment will expire in 30 minutes!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 10),

                Divider(),
                SizedBox(height: 5),

                Text(
                  'Please arrive on time to avoid cancellation.',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onAppointmentBooked();
                  Navigator.pop(context);
                },
                child: Text(
                  'OK, I\'ll be there',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
