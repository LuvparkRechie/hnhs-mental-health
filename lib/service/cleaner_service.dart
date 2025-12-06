import 'dart:async';

import '../api_key/api_key.dart';

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
          "custom":
              "created_at < DATE_SUB(CONVERT_TZ(NOW(), @@global.time_zone, '+08:00'), INTERVAL 30 MINUTE) AND status NOT IN ('confirmed', 'rescheduled') LIMIT 500",
        },
      );
      await api.delete();
    } catch (e) {
      print("[AppointmentCleaner] Error: $e");
    }
  }
}
