import 'package:flutter/material.dart';
import 'package:hnhsmind_care/api_key/api_key.dart';
import 'package:intl/intl.dart';

class AppointmentService {
  // Check if user already has an appointment on the same date
  static Future<Map<String, dynamic>> checkDuplicateBooking({
    required String userId,
    required DateTime date,
  }) async {
    try {
      final api = ApiPhp(
        tableName: 'appointments',
        whereClause: {'user_id': userId, 'appointment_date': _formatDate(date)},
      );

      final response = await api.select();

      if (response['success'] == true && response['data'] is List) {
        final List appointments = response['data'];
        final hasExistingAppointment = appointments.isNotEmpty;

        return {
          'success': true,
          'hasDuplicate': hasExistingAppointment,
          'existingAppointment': hasExistingAppointment
              ? appointments.first
              : null,
        };
      }

      return {'success': false, 'hasDuplicate': false};
    } catch (e) {
      return {'success': false, 'hasDuplicate': false, 'message': 'Error: $e'};
    }
  }

  // Book new appointment with duplicate check and expiration
  static Future<Map<String, dynamic>> bookAppointment({
    required String userId,
    required DateTime date,
    required TimeOfDay time,
    String? notes,
  }) async {
    try {
      // First check for duplicate booking
      final duplicateCheck = await checkDuplicateBooking(
        userId: userId,
        date: date,
      );

      if (duplicateCheck['hasDuplicate'] == true) {
        return {
          'success': false,
          'message':
              'You already have an appointment booked for ${formatDisplayDate(date)}. Please choose a different date.',
          'error': 'duplicate_booking',
        };
      }

      final api = ApiPhp(
        tableName: 'appointments',
        parameters: {
          'user_id': userId,
          'appointment_date': _formatDate(date),
          'appointment_time': _formatTime(time),
          'notes': notes ?? '',
          'status': 'PENDING',
          'expires_at': DateTime.now()
              .add(Duration(minutes: 30))
              .toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      final response = await api.insert();

      // Handle unique constraint violation from database
      if (response['success'] == false &&
          response['message']?.toString().toLowerCase().contains('duplicate') ==
              true) {
        return {
          'success': false,
          'message':
              'You already have an appointment booked for ${formatDisplayDate(date)}. Please choose a different date.',
          'error': 'duplicate_booking',
        };
      }

      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
        'error': 'unknown_error',
      };
    }
  }

  // Confirm/accept appointment with expiration check
  static Future<Map<String, dynamic>> confirmAppointment(
    String appointmentId,
  ) async {
    try {
      // First check if appointment is still valid
      final validityCheck = await _checkAppointmentValidity(appointmentId);
      if (!validityCheck['isValid']) {
        return {
          'success': false,
          'message': validityCheck['message'],
          'error': 'appointment_expired',
        };
      }

      final api = ApiPhp(
        tableName: 'appointments',
        parameters: {
          'status': 'CONFIRMED',
          'expires_at': null, // Remove expiration once confirmed
        },
        whereClause: {'id': appointmentId},
      );

      final response = await api.update();
      return response;
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Check if appointment is still valid (not expired)
  static Future<Map<String, dynamic>> _checkAppointmentValidity(
    String appointmentId,
  ) async {
    try {
      final api = ApiPhp(
        tableName: 'appointments',
        whereClause: {'id': appointmentId},
      );

      final response = await api.select();

      if (response['success'] == true &&
          response['data'] is List &&
          response['data'].isNotEmpty) {
        final appointment = response['data'][0];
        final status = appointment['status'];
        final expiresAt = appointment['expires_at'];

        // If already confirmed, it's valid
        if (status == 'CONFIRMED') {
          return {'isValid': true, 'message': 'Appointment is confirmed'};
        }

        // Check if expired
        if (expiresAt != null) {
          final expiryTime = DateTime.parse(expiresAt);
          final now = DateTime.now();

          if (now.isAfter(expiryTime)) {
            // Auto-cancel expired appointment
            await _autoCancelExpiredAppointment(appointmentId);
            return {
              'isValid': false,
              'message':
                  'This appointment booking has expired. Please book a new appointment.',
            };
          }
        }

        return {'isValid': true, 'message': 'Appointment is valid'};
      }

      return {'isValid': false, 'message': 'Appointment not found'};
    } catch (e) {
      return {'isValid': false, 'message': 'Error checking appointment: $e'};
    }
  }

  // Auto-cancel expired appointments
  static Future<void> _autoCancelExpiredAppointment(
    String appointmentId,
  ) async {
    try {
      final api = ApiPhp(
        tableName: 'appointments',
        parameters: {'status': 'EXPIRED'},
        whereClause: {'id': appointmentId},
      );
      await api.update();
    } catch (e) {
      print('Error auto-cancelling appointment: $e');
    }
  }

  // Get user appointments with expiration check
  static Future<Map<String, dynamic>> getUserAppointments(String userId) async {
    try {
      final api = ApiPhp(
        tableName: 'appointments',
        whereClause: {'user_id': userId},
        orderBy: 'appointment_date DESC, appointment_time DESC',
      );

      final response = await api.select();

      // Check and update expired appointments
      if (response['success'] == true && response['data'] is List) {
        final List<dynamic> appointments = response['data'];
        for (var appointment in appointments) {
          if (appointment['status'] == 'PENDING' &&
              appointment['expires_at'] != null) {
            final expiryTime = DateTime.parse(appointment['expires_at']);
            if (DateTime.now().isAfter(expiryTime)) {
              await _autoCancelExpiredAppointment(appointment['id'].toString());
            }
          }
        }
      }

      return response;
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get appointment with expiration info
  static Future<Map<String, dynamic>> getAppointmentWithExpiry(
    String appointmentId,
  ) async {
    try {
      final api = ApiPhp(
        tableName: 'appointments',
        whereClause: {'id': appointmentId},
      );

      final response = await api.select();

      if (response['success'] == true &&
          response['data'] is List &&
          response['data'].isNotEmpty) {
        final appointment = response['data'][0];
        final expiresAt = appointment['expires_at'];
        DateTime? expiryTime;
        Duration? timeRemaining;
        bool isExpired = false;

        if (expiresAt != null && appointment['status'] == 'PENDING') {
          expiryTime = DateTime.parse(expiresAt);
          timeRemaining = expiryTime.difference(DateTime.now());
          isExpired = timeRemaining.isNegative;

          // Auto-expire if needed
          if (isExpired) {
            await _autoCancelExpiredAppointment(appointmentId);
          }
        }

        return {
          'success': true,
          'data': appointment,
          'expiry_info': {
            'expires_at': expiryTime,
            'time_remaining': timeRemaining,
            'is_expired': isExpired,
            'minutes_remaining': isExpired
                ? 0
                : (timeRemaining?.inMinutes ?? 0),
          },
        };
      }

      return response;
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get all appointments with expiration cleanup
  static Future<Map<String, dynamic>> getAllAppointments() async {
    try {
      final api = ApiPhp(tableName: 'appointments');

      final response = await api.select();

      // Clean up expired appointments
      if (response['success'] == true && response['data'] is List) {
        final List<dynamic> appointments = response['data'];
        for (var appointment in appointments) {
          if (appointment['status'] == 'PENDING' &&
              appointment['expires_at'] != null) {
            final expiryTime = DateTime.parse(appointment['expires_at']);
            if (DateTime.now().isAfter(expiryTime)) {
              await _autoCancelExpiredAppointment(appointment['id'].toString());
            }
          }
        }
      }

      return response;
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get all appointments with user data using JOIN (with expiration cleanup)
  static Future<Map<String, dynamic>> getAllAppointmentsWithUsers() async {
    try {
      final api = ApiPhp(tableName: 'appointments');

      final Map<String, dynamic> joinConfig = {
        'join': 'LEFT JOIN users ON appointments.user_id = users.id',
        'columns': '''
          appointments.*, 
          users.email,
          users.mobile_no,
          users.username
        ''',
        'where':
            "appointments.status NOT IN ('completed', 'expired','declined')",
        'orderBy':
            'appointments.appointment_date DESC, appointments.appointment_time DESC',
      };

      final response = await api.selectWithJoin(joinConfig);

      if (response['success'] == true && response['data'] is List) {
        final List<dynamic> appointments = response['data'];
        for (var appointment in appointments) {
          if (appointment['status'] == 'PENDING' &&
              appointment['expires_at'] != null) {
            final expiryTime = DateTime.parse(appointment['expires_at']);
            if (DateTime.now().isAfter(expiryTime)) {
              await _autoCancelExpiredAppointment(appointment['id'].toString());
            }
          }
        }
      }

      return response;
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Update appointment status (with expiration handling)
  static Future<Map<String, dynamic>> updateAppointmentStatus(
    String appointmentId,
    String status,
  ) async {
    try {
      Map<String, dynamic> parameters = {'status': status};

      // Remove expiration if confirming
      if (status == 'CONFIRMED') {
        parameters['expires_at'] = null;
      }

      // Set expiration if changing back to pending
      if (status == 'PENDING') {
        parameters['expires_at'] = DateTime.now()
            .add(Duration(minutes: 30))
            .toIso8601String();
      }

      final api = ApiPhp(
        tableName: 'appointments',
        parameters: parameters,
        whereClause: {'id': appointmentId},
      );

      final response = await api.update();
      return response;
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Your existing methods remain the same...
  static Future<Map<String, dynamic>> getUserAppointmentsForDate({
    required String userId,
    required DateTime date,
  }) async {
    try {
      final api = ApiPhp(
        tableName: 'appointments',
        whereClause: {'user_id': userId, 'appointment_date': _formatDate(date)},
      );

      final response = await api.select();
      return response;
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAppointmentsByDate(
    DateTime date,
  ) async {
    try {
      final api = ApiPhp(
        tableName: 'appointments',
        whereClause: {'appointment_date': _formatDate(date)},
      );

      final response = await api.select();
      return response;
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> cancelAppointment(
    String appointmentId,
    String userId,
  ) async {
    try {
      final api = ApiPhp(
        tableName: 'appointments',
        whereClause: {'id': appointmentId, 'user_id': userId},
      );

      final response = await api.delete();
      return response;
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUserAppointmentsWithDetails(
    String userId,
  ) async {
    try {
      final api = ApiPhp(tableName: 'appointments');

      final Map<String, dynamic> joinConfig = {
        'join': 'LEFT JOIN users ON appointments.user_id = users.id',
        'columns': '''
          appointments.*, 
          users.email,
          users.mobile_no,
          users.username
        ''',
        'where': 'appointments.user_id = ?',
        'where_params': [userId],
        'orderBy': 'appointments.appointment_date DESC',
      };

      final response = await api.selectWithJoin(joinConfig);
      return response;
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAppointmentsByDateWithUsers(
    DateTime date,
  ) async {
    try {
      final api = ApiPhp(tableName: 'appointments');

      final Map<String, dynamic> joinConfig = {
        'join': 'LEFT JOIN users ON appointments.user_id = users.id',
        'columns': '''
          appointments.*, 
          users.email,
          users.mobile_no,
          users.username
        ''',
        'where': 'appointments.appointment_date = ?',
        'where_params': [_formatDateForDatabase(date)],
        'orderBy': 'appointments.appointment_time ASC',
      };

      final response = await api.selectWithJoin(joinConfig);
      return response;
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Helper methods - FIXED TIMEZONE ISSUE
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String formatDisplayDate(DateTime date) {
    return DateFormat('EEEE, MMM dd, yyyy').format(date);
  }

  static String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  static String _formatDateForDatabase(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static DateTime parseAppointmentDateTime(String dateStr, String timeStr) {
    try {
      String time = timeStr;
      if (time.isEmpty || time == 'null') {
        time = '00:00:00';
      }

      final timeParts = time.split(':');
      if (timeParts.length >= 2) {
        time =
            '${timeParts[0].padLeft(2, '0')}:${timeParts[1].padLeft(2, '0')}:00';
      }

      final dateTimeString = '$dateStr $time';
      return DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateTimeString);
    } catch (e) {
      return DateTime.now();
    }
  }

  static DateTime parseDatabaseTimestamp(String timestamp) {
    try {
      return DateTime.parse(timestamp).toLocal();
    } catch (e) {
      return DateTime.now();
    }
  }

  static DateTime getBookingDisplayDate(
    String appointmentDate,
    String createdAt,
  ) {
    try {
      return DateTime.parse(appointmentDate);
    } catch (e) {
      return parseDatabaseTimestamp(createdAt);
    }
  }

  // Reschedule appointment with validation
  static Future<Map<String, dynamic>> rescheduleAppointment({
    required String appointmentId,
    required DateTime newDate,
    required TimeOfDay newTime,
    String? reason,
  }) async {
    try {
      // First get the current appointment details
      final apiGet = ApiPhp(
        tableName: 'appointments',
        whereClause: {'id': appointmentId},
      );

      final currentResponse = await apiGet.select();

      if (currentResponse['success'] != true ||
          currentResponse['data'] is! List ||
          currentResponse['data'].isEmpty) {
        return {
          'success': false,
          'message': 'Appointment not found',
          'error': 'not_found',
        };
      }

      final appointment = currentResponse['data'][0];
      final userId = appointment['user_id'].toString();
      final currentStatus = appointment['status'];
      final oldDate = appointment['appointment_date'];
      final oldTime = appointment['appointment_time'];

      // Check if appointment can be rescheduled
      if (currentStatus == 'COMPLETED' ||
          currentStatus == 'EXPIRED' ||
          currentStatus == 'CANCELLED') {
        return {
          'success': false,
          'message': 'Cannot reschedule a $currentStatus appointment',
          'error': 'invalid_status',
        };
      }

      // Check for duplicate booking for the user on new date
      final duplicateCheck = await checkDuplicateBooking(
        userId: userId,
        date: newDate,
      );

      if (duplicateCheck['hasDuplicate'] == true) {
        final existingAppointment = duplicateCheck['existingAppointment'];
        if (existingAppointment != null &&
            existingAppointment['id'].toString() != appointmentId) {
          return {
            'success': false,
            'message':
                'User already has an appointment on ${AppointmentService.formatDisplayDate(newDate)}',
            'error': 'duplicate_booking',
          };
        }
      }

      // Prepare update parameters - using only existing columns
      final Map<String, dynamic> updateParams = {
        'appointment_date': _formatDate(newDate),
        'appointment_time': _formatTime(newTime),
        'status': 'RESCHEDULED',
        'notes': '$reason', 'updated_at': DateTime.now().toIso8601String(),
        'expires_at': null, // Remove expiration for rescheduled appointments
      };

      // Update appointment with new date/time
      final apiUpdate = ApiPhp(
        tableName: 'appointments',
        parameters: updateParams,
        whereClause: {'id': appointmentId},
      );

      final response = await apiUpdate.update();

      if (response['success'] == true) {
        return {
          'success': true,
          'message': 'Appointment rescheduled successfully',
          'data': {
            'old_date': oldDate,
            'old_time': oldTime,
            'new_date': _formatDate(newDate),
            'new_time': _formatTime(newTime),
            'previous_status': currentStatus,
            'new_status': 'RESCHEDULED',
          },
        };
      }

      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'Error rescheduling appointment: $e',
        'error': 'unknown_error',
      };
    }
  }

  // Helper method to format time for display in notes
  static String _formatTimeForDisplay(String time) {
    try {
      final timeFormat = DateFormat('HH:mm:ss');
      final dateTime = timeFormat.parse(time);
      return DateFormat('h:mm a').format(dateTime);
    } catch (e) {
      return time;
    }
  }
}
