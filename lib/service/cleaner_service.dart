import 'dart:async';

import 'package:hnhsmind_care/api_key/api_key.dart';

class AppointmentCleanerService {
  Timer? _timer;

  void start({int intervalSeconds = 20}) {
    // Run immediately
    _deleteExpiredAppointments();

    // Then run every [intervalSeconds]
    _timer = Timer.periodic(Duration(seconds: intervalSeconds), (_) {
      _deleteExpiredAppointments();
    });
  }

  void stop() {
    _timer?.cancel();
  }

  Future<void> _deleteExpiredAppointments() async {
    try {
      final api = ApiPhp(
        tableName: 'appointments',
        whereClause: {
          'custom':
              "CONVERT_TZ(NOW(), @@session.time_zone, '+08:00') >= expires_at",
        },
      );

      final response = await api.delete();

      if (response['status'] == 'success') {
        print(
          '[AppointmentCleaner] Expired appointments deleted successfully.',
        );
      } else {
        print('[AppointmentCleaner] Delete failed: ${response['message']}');
      }
    } catch (e) {
      print('[AppointmentCleaner] Error: $e');
    }
  }
}
