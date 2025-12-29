// Shared model for Appointment and TimeSlot
class Appointment {
  final String id;
  final String userName;
  final DateTime schedule;
  final DateTime bookingTime;
  final String status;
  final String? userId;
  final String? notes;

  const Appointment({
    required this.id,
    required this.userName,
    required this.schedule,
    required this.bookingTime,
    required this.status,
    this.userId,
    this.notes,
  });

  // Factory constructor for creating Appointment from JSON
  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      userName: json['username'] ?? 'Unknown',
      schedule: DateTime.parse(
        '${json['appointment_date']} ${json['appointment_time']}',
      ),
      bookingTime: DateTime.parse(json['created_at']),
      status: json['status'],
      notes: json['notes'],
    );
  }
}
