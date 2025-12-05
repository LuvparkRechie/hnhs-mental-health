import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../api_key/api_key.dart';
import '../pages/models/conversation_models.dart';
import '../suicide_detection_service.dart';

class ChatProvider with ChangeNotifier {
  final SuicideDetectionService detectionService;

  final List<Conversation> _conversations = [];
  bool _isLoading = false;
  String? _error;
  bool _hasHighRiskAlert = false;

  ChatProvider({required this.detectionService});

  List<Conversation> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasHighRiskAlert => _hasHighRiskAlert;

  Future<void> sendMessage(String message, String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userConversation = Conversation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        message: message,
        timestamp: DateTime.now(),
        isUser: true,
      );
      _conversations.add(userConversation);
      notifyListeners();

      final riskAnalysis = detectionService.analyzeMessage(message);
      final double riskScore = riskAnalysis['riskScore'] ?? 0.0;
      final bool requiresAttention =
          riskAnalysis['requiresImmediateAttention'] == true;

      final bool isAlreadyInSupportMode = isInSupportMode;

      await Future.delayed(Duration(seconds: 1));

      String aiResponse;
      if (riskAnalysis['supportiveResponse'] != null) {
        aiResponse = riskAnalysis['supportiveResponse']!;
        if (kDebugMode) {
          print('   Using SUPPORTIVE response from detection service');
        }
      } else {
        aiResponse = _generateAIResponse(message, _conversations);
        if (kDebugMode) {
          print('   Using NORMAL AI response');
        }
      }

      final aiConversation = Conversation(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        message: aiResponse,
        timestamp: DateTime.now(),
        isUser: false,
        suicideRiskScore: riskScore,
        flaggedForReview: requiresAttention,
      );
      _conversations.add(aiConversation);

      // ALERT LOGIC
      if (requiresAttention && !isAlreadyInSupportMode) {
        await _saveToAdminAlerts(userConversation);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  dynamic _handleConcatenatedJson(String response) {
    try {
      final jsonParts = response.split('}{');
      dynamic lastValidResponse = {
        'success': false,
        'message': 'No valid JSON found',
      };

      for (var part in jsonParts) {
        try {
          var jsonStr = part;
          if (!jsonStr.startsWith('{')) jsonStr = '{$jsonStr';
          if (!jsonStr.endsWith('}')) jsonStr = '$jsonStr}';

          final parsed = json.decode(jsonStr);
          lastValidResponse = parsed;

          if (parsed['data'] != null || parsed['success'] == true) {
            return parsed;
          }
        } catch (e) {
          continue;
        }
      }

      return lastValidResponse;
    } catch (e) {
      return {'success': false, 'message': 'JSON parsing error: $e'};
    }
  }

  String _generateAIResponse(
    String userMessage,
    List<Conversation> conversationHistory,
  ) {
    final lowerMessage = userMessage.toLowerCase();

    final userMessages = conversationHistory.where((c) => c.isUser).length;
    final isFirstMessage = userMessages <= 1;

    if (isFirstMessage) {
      if (lowerMessage.contains('hello') ||
          lowerMessage.contains('hi') ||
          lowerMessage.contains('hey')) {
        return "Hello! I'm HNHS MindCare AI, and I'm genuinely here to listen and support you. It takes courage to reach out, and I want you to know that this is a safe space where you can share anything that's on your mind. How has your day been so far? Sometimes starting with the small things can help us understand the bigger picture of how we're feeling.";
      }
    }

    return "Thank you for sharing that with me. I'm listening carefully to what you're expressing...";
  }

  Future<void> clearConversations(String userId) async {
    _conversations.clear();
    _hasHighRiskAlert = false;
    notifyListeners();
  }

  Future<void> _saveToAdminAlerts(Conversation userMessage) async {
    try {
      final api = ApiPhp(
        tableName: 'admin_alerts',
        parameters: {
          'user_id': userMessage.userId,
          'user_message': userMessage.message,
          'description': "This user need immediate attention",
          'created_date': DateTime.now().toIso8601String(),
        },
      );

      final response = await api.insertAdminAlert();
      // Handle concatenated JSON if needed
      dynamic processedResponse = response;
      if (response is String && response.toString().contains('}{')) {
        processedResponse = _handleConcatenatedJson(response.toString());
      }

      if (processedResponse['success'] != true &&
          processedResponse['status'] != 'success') {
        if (kDebugMode) {
          print('Failed to save admin alert: ${processedResponse['message']}');
        }
      } else {
        _hasHighRiskAlert = true;
      }
    } catch (e) {
      _hasHighRiskAlert = true;
    }

    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  bool get isInSupportMode {
    return _conversations.any(
      (conv) => conv.suicideRiskScore != null && conv.suicideRiskScore! > 0.3,
    );
  }

  // Mark alert as resolved
  Future<void> resolveAlert(String alertId) async {
    try {
      final api = ApiPhp(
        tableName: 'admin_alerts',
        parameters: {'resolved': 1},
        whereClause: {'id': alertId},
      );

      final response = await api.update();

      // Handle concatenated JSON if needed
      dynamic processedResponse = response;
      if (response is String && response.toString().contains('}{')) {
        processedResponse = _handleConcatenatedJson(response.toString());
      }

      if (processedResponse['success'] != true &&
          processedResponse['status'] != 'success') {
        if (kDebugMode) {
          print('Failed to resolve alert: ${processedResponse['message']}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error resolving alert: $e');
      }
    }

    // Always update UI
    _hasHighRiskAlert = false;
    notifyListeners();
  }

  // Get unresolved alerts for admin
  Future<List<Map<String, dynamic>>> getUnresolvedAlerts() async {
    try {
      final api = ApiPhp(
        tableName: 'admin_alerts',
        whereClause: {'resolved': 0},
      );

      final response = await api.select();

      // Handle concatenated JSON
      dynamic processedResponse = response;
      if (response is String && response.toString().contains('}{')) {
        processedResponse = _handleConcatenatedJson(response.toString());
      }

      if (processedResponse['success'] == true ||
          processedResponse['status'] == 'success') {
        final data = processedResponse['data'];
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting unresolved alerts: $e');
      }
      return [];
    }
  }

  // Check for any network/database errors
  bool get hasNetworkError {
    return _error?.contains('network') == true ||
        _error?.contains('Internet') == true ||
        _error?.contains('timeout') == true;
  }

  // Retry last operation
  Future<void> retryLastOperation() async {
    _error = null;
    notifyListeners();
  }
}
