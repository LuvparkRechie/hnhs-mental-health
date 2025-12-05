// lib/provider/app_data_provider.dart
import 'package:flutter/foundation.dart';
import 'package:hnhsmind_care/api_key/api_key.dart';
import 'package:provider/provider.dart';

import '../provider/auth_provider.dart';

class HighRiskChat {
  final String id;
  final String userId;
  final DateTime timestamp;
  final String userMessage;
  final String aiResponse;
  final double riskScore;
  final bool requiresImmediateAttention;
  final bool isResolved;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  HighRiskChat({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.userMessage,
    required this.aiResponse,
    required this.riskScore,
    required this.requiresImmediateAttention,
    this.isResolved = false,
    this.resolvedAt,
    this.resolvedBy,
  });
}

class MoodEntry {
  final String id;
  final DateTime date;
  final String mood;
  final int intensity;
  final String note;
  final String? relatedTo;
  final List<String> tags;

  MoodEntry({
    required this.id,
    required this.date,
    required this.mood,
    required this.intensity,
    required this.note,
    this.relatedTo,
    this.tags = const [],
  });
}

class Appointment {
  final String id;
  final String userName;
  final DateTime schedule;
  final DateTime bookingTime;
  final String status;
  final String type;
  final String? notes;

  Appointment({
    required this.id,
    required this.userName,
    required this.schedule,
    required this.bookingTime,
    required this.status,
    this.type = 'General',
    this.notes,
  });
}

class AppDataProvider with ChangeNotifier {
  // Only store high-risk chats for admin review
  final List<HighRiskChat> _highRiskChats = [];
  final List<MoodEntry> _moodEntries = [];
  final List<Appointment> _appointments = [];

  // Track current session for mood reflection (no chat storage)
  String? _currentSessionId;
  DateTime? _sessionStartTime;
  int _messageCount = 0;

  // Getters
  List<HighRiskChat> get highRiskChats => _highRiskChats;
  List<MoodEntry> get moodEntries => _moodEntries;
  List<Appointment> get appointments => _appointments;
  String? get currentSessionId => _currentSessionId;
  int get messageCount => _messageCount;

  // Get unresolved high-risk chats for admin
  List<HighRiskChat> get unresolvedHighRiskChats {
    return _highRiskChats.where((chat) => !chat.isResolved).toList();
  }

  // Get today's mood entries
  List<MoodEntry> get todayMoodEntries {
    final today = DateTime.now();
    return _moodEntries
        .where((entry) => _isSameDay(entry.date, today))
        .toList();
  }

  // Start a new chat session (only track metrics, not content)
  void startChatSession() {
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _sessionStartTime = DateTime.now();
    _messageCount = 0;

    if (kDebugMode) {
      print('🆕 Chat session started: $_currentSessionId');
    }
    notifyListeners();
  }

  // Track message count for session analytics
  void incrementMessageCount() {
    _messageCount++;
    notifyListeners();
  }

  // Store high-risk chat when suicide risk detected
  void addHighRiskChat({
    required String userId,
    required String userMessage,
    required String aiResponse,
    required double riskScore,
    required bool requiresImmediateAttention,
  }) {
    final highRiskChat = HighRiskChat(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      timestamp: DateTime.now(),
      userMessage: userMessage,
      aiResponse: aiResponse,
      riskScore: riskScore,
      requiresImmediateAttention: requiresImmediateAttention,
    );

    _highRiskChats.add(highRiskChat);

    if (kDebugMode) {
      print('🚨 High-risk chat stored for admin review');
      print('   Risk Score: $riskScore');
      print('   User: $userId');
      print('   Requires Attention: $requiresImmediateAttention');
    }

    notifyListeners();
  }

  // End chat session and prepare for mood reflection
  void endChatSession() {
    if (_currentSessionId != null && kDebugMode) {
      final duration = DateTime.now().difference(_sessionStartTime!);
      print('✅ Chat session ended: $_currentSessionId');
      print(
        '📊 Session stats: $_messageCount messages, ${duration.inMinutes} minutes',
      );
    }

    _currentSessionId = null;
    _sessionStartTime = null;
    _messageCount = 0;
    notifyListeners();
  }

  // Mark high-risk chat as resolved
  void resolveHighRiskChat(String chatId, String resolvedBy) {
    final chatIndex = _highRiskChats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      final chat = _highRiskChats[chatIndex];
      _highRiskChats[chatIndex] = HighRiskChat(
        id: chat.id,
        userId: chat.userId,
        timestamp: chat.timestamp,
        userMessage: chat.userMessage,
        aiResponse: chat.aiResponse,
        riskScore: chat.riskScore,
        requiresImmediateAttention: chat.requiresImmediateAttention,
        isResolved: true,
        resolvedAt: DateTime.now(),
        resolvedBy: resolvedBy,
      );

      if (kDebugMode) {
        print('✅ High-risk chat resolved: $chatId by $resolvedBy');
      }
      notifyListeners();
    }
  }

  Future<void> addMoodEntry(MoodEntry entry, context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    try {
      _moodEntries.add(entry);

      final api = ApiPhp(
        tableName: 'mood_entries', // Your table name
        parameters: {
          'user_id': currentUser!.id, // You need to get actual user ID
          'mood': entry.mood,
          'intensity': entry.intensity,
          'note': entry.note,
          'related_to': entry.relatedTo ?? '',
          'tags': entry.tags.join(','),
          'created_date': entry.date.toIso8601String(),
        },
      );

      final response = await api.insertMood();

      // Handle response
      if ((response['success'] == true || response['status'] == 'success')) {
      } else {}

      notifyListeners();
    } catch (e) {
      notifyListeners();
    }
  }

  // Add appointment
  void addAppointment(Appointment appointment) {
    _appointments.add(appointment);

    if (kDebugMode) {
      print(
        '📅 Appointment added: ${appointment.userName} - ${appointment.status}',
      );
    }
    notifyListeners();
  }

  // Get upcoming appointments
  List<Appointment> getUpcomingAppointments() {
    final now = DateTime.now();
    return _appointments
        .where(
          (appointment) =>
              appointment.schedule.isAfter(now) &&
              appointment.status != 'Cancelled' &&
              appointment.status != 'Completed',
        )
        .toList()
      ..sort((a, b) => a.schedule.compareTo(b.schedule));
  }

  // Update appointment status
  void updateAppointmentStatus(String appointmentId, String newStatus) {
    final appointmentIndex = _appointments.indexWhere(
      (a) => a.id == appointmentId,
    );
    if (appointmentIndex != -1) {
      final appointment = _appointments[appointmentIndex];
      _appointments[appointmentIndex] = Appointment(
        id: appointment.id,
        userName: appointment.userName,
        schedule: appointment.schedule,
        bookingTime: appointment.bookingTime,
        status: newStatus,
        type: appointment.type,
        notes: appointment.notes,
      );
      notifyListeners();
    }
  }

  // Get high-risk chat statistics for admin dashboard
  Map<String, dynamic> getHighRiskStats() {
    final total = _highRiskChats.length;
    final resolved = _highRiskChats.where((chat) => chat.isResolved).length;
    final urgent = _highRiskChats
        .where((chat) => chat.requiresImmediateAttention)
        .length;

    return {
      'total_high_risk_chats': total,
      'resolved_chats': resolved,
      'unresolved_chats': total - resolved,
      'urgent_cases': urgent,
      'resolution_rate': total > 0 ? (resolved / total) * 100 : 0,
    };
  }

  // Clear current session (for cleanup)
  void clearCurrentSession() {
    _currentSessionId = null;
    _sessionStartTime = null;
    _messageCount = 0;
    notifyListeners();
  }

  // Helper method to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Initialize with sample data
  void initializeSampleData() {
    // Sample high-risk chats for admin testing
    _highRiskChats.addAll([
      HighRiskChat(
        id: '1',
        userId: 'user123',
        timestamp: DateTime.now().subtract(Duration(hours: 2)),
        userMessage: 'I just cant take it anymore. Everything feels hopeless.',
        aiResponse:
            'I hear how much pain youre in. Your feelings are valid and important. Please know that there are people who want to help you through this.',
        riskScore: 0.85,
        requiresImmediateAttention: true,
      ),
    ]);

    // Sample mood entries
    _moodEntries.addAll([
      MoodEntry(
        id: '1',
        date: DateTime.now().subtract(Duration(hours: 3)),
        mood: 'Peaceful',
        intensity: 8,
        note: 'After a helpful conversation',
        tags: ['reflection', 'progress'],
      ),
    ]);

    // Sample appointments
    _appointments.addAll([
      Appointment(
        id: '1',
        userName: 'Alex Johnson',
        schedule: DateTime.now().add(Duration(days: 2)),
        bookingTime: DateTime.now().subtract(Duration(days: 1)),
        status: 'Scheduled',
        type: 'Therapy Session',
      ),
    ]);

    if (kDebugMode) {
      print('📊 AppDataProvider initialized');
      print('   - ${_highRiskChats.length} high-risk chats');
      print('   - ${_moodEntries.length} mood entries');
      print('   - ${_appointments.length} appointments');
    }
  }
}
