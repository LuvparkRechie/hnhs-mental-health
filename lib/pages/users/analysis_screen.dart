import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hnhsmind_care/api_key/api_key.dart';
import 'package:hnhsmind_care/provider/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class AnalysisScreen extends StatefulWidget {
  final String analysisJson;
  final List<Map<String, dynamic>> conversation;
  final String? chatSessionId; // ADDED: New parameter for mood storage

  const AnalysisScreen({
    super.key,
    required this.analysisJson,
    required this.conversation,
    this.chatSessionId, // ADDED: New parameter for mood storage
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  Map<String, dynamic>? _analysisData;
  List<Map<String, dynamic>> _concernQuestions = [];
  bool _isGeneratingQuestions = false;
  Map<String, String?> selectedAnswers = {};
  String criticalMsg = "";
  bool isLoadingScreen = true;
  bool _hasSentAlert = false;
  bool _isSavingMood = false; // ADDED: For mood storage indicator
  bool _moodSavedSuccessfully = false; // ADDED: Track if mood was saved

  @override
  void initState() {
    super.initState();
    _parseAnalysisData();
  }

  void _parseAnalysisData() {
    try {
      final data = jsonDecode(widget.analysisJson);
      setState(() {
        _analysisData = data;
        criticalMsg =
            _analysisData?["critical_message"]?.toString().trim() ?? "";
        isLoadingScreen = false;
      });

      // ADDED: Store mood in database after parsing
      _storeMoodInDatabase();

      // Only generate questions if there's a critical message
      if (criticalMsg.isNotEmpty) {
        _generateConcernQuestions();
      }
    } catch (e) {
      setState(() {
        _analysisData = {'error': 'Failed to parse analysis'};
        isLoadingScreen = false;
      });
    }
  }

  // ADDED: Function to store mood in database
  Future<void> _storeMoodInDatabase() async {
    print("_analysisData $_analysisData");
    if (_analysisData == null) return;

    try {
      setState(() {
        _isSavingMood = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user != null) {
        // Get analysis values
        final emotion = _analysisData!['emotion']?.toString() ?? 'neutral';
        final riskLevel = _analysisData!['risk_level']?.toString() ?? 'low';
        final stressLevel = _analysisData!['stress_level']?.toString() ?? 'low';

        // Calculate intensity based on risk level and stress level
        int intensity = _calculateIntensity(riskLevel, stressLevel);

        // Generate tags based on analysis
        List<String> tags = _generateTags(emotion, riskLevel);

        // Prepare mood entry data
        final moodEntryData = {
          'user_id': user.id,
          'mood': emotion,
          'intensity': intensity.toString(),
          'note': _generateMoodNote(),
          'related_to':
              widget.chatSessionId ??
              'chat_analysis_${DateTime.now().millisecondsSinceEpoch}',
          'tags': tags.join(','),
          'created_date': DateTime.now().toString().split(".")[0],
        };

        // Save to mood_entries table
        final api = ApiPhp(
          tableName: 'mood_entries',
          parameters: moodEntryData,
        );

        final response = await api.insert();
        print("Mood entry saved: $response");

        setState(() {
          _moodSavedSuccessfully = true;
        });
      }
    } catch (e) {
      print("Error saving mood entry: $e");
      setState(() {
        _moodSavedSuccessfully = false;
      });
    } finally {
      setState(() {
        _isSavingMood = false;
      });
    }
  }

  // ADDED: Calculate intensity from risk and stress levels
  int _calculateIntensity(String riskLevel, String stressLevel) {
    int intensity = 5; // Default medium intensity

    // Adjust based on risk level
    switch (riskLevel.toLowerCase()) {
      case 'high':
        intensity = 9;
        break;
      case 'moderate':
        intensity = 7;
        break;
      case 'low':
        intensity = 3;
        break;
      default:
        intensity = 5;
    }

    // Adjust based on stress level
    switch (stressLevel.toLowerCase()) {
      case 'high':
        intensity = (intensity * 1.3).ceil();
        break;
      case 'moderate':
        intensity = (intensity * 1.1).ceil();
        break;
      case 'low':
        intensity = (intensity * 0.9).ceil();
        break;
    }

    // Ensure intensity is between 1-10
    return intensity.clamp(1, 10);
  }

  // ADDED: Generate tags for mood entry
  List<String> _generateTags(String emotion, String riskLevel) {
    List<String> tags = [];

    // Add emotion as first tag
    tags.add(emotion);

    // Add risk level
    tags.add('Risk: ${riskLevel.toUpperCase()}');

    // Add critical tag if there's a critical message
    if (criticalMsg.isNotEmpty) {
      tags.add('Critical');
      tags.add('Urgent');
    }

    // Add emotion-specific tags
    if (emotion.toLowerCase().contains('sad') ||
        emotion.toLowerCase().contains('malungkot') ||
        emotion.toLowerCase().contains('masubo')) {
      tags.add('Sadness');
      tags.add('Low Mood');
    } else if (emotion.toLowerCase().contains('angry') ||
        emotion.toLowerCase().contains('galit') ||
        emotion.toLowerCase().contains('akig')) {
      tags.add('Anger');
      tags.add('Frustration');
    } else if (emotion.toLowerCase().contains('anxious') ||
        emotion.toLowerCase().contains('nababahala') ||
        emotion.toLowerCase().contains('nabalaka')) {
      tags.add('Anxiety');
      tags.add('Worry');
    } else if (emotion.toLowerCase().contains('stress')) {
      tags.add('Stress');
      tags.add('Pressure');
    } else if (emotion.toLowerCase().contains('lonely') ||
        emotion.toLowerCase().contains('nag-iisa') ||
        emotion.toLowerCase().contains('naga-isahan')) {
      tags.add('Loneliness');
      tags.add('Isolation');
    } else if (emotion.toLowerCase().contains('happy') ||
        emotion.toLowerCase().contains('masaya') ||
        emotion.toLowerCase().contains('malipayon')) {
      tags.add('Happiness');
      tags.add('Positive');
    } else {
      tags.add('Neutral');
    }

    return tags;
  }

  // ADDED: Generate note for mood entry
  String _generateMoodNote() {
    if (criticalMsg.isNotEmpty) {
      return "Critical conversation detected: ${criticalMsg.substring(0, criticalMsg.length > 50 ? 50 : criticalMsg.length)}...";
    }

    final emotion = _analysisData?['emotion']?.toString() ?? 'neutral';
    final riskLevel = _analysisData?['risk_level']?.toString() ?? 'low';
    final stressLevel = _analysisData?['stress_level']?.toString() ?? 'low';

    return "AI analysis: $emotion emotion with $riskLevel risk and $stressLevel stress level detected from chatbot conversation";
  }

  // EXISTING CODE - NO CHANGES
  Future<void> _generateConcernQuestions() async {
    setState(() {
      _isGeneratingQuestions = true;
    });

    try {
      final emotion = _analysisData?['emotion']?.toString() ?? 'neutral';
      final riskLevel = _analysisData?['risk_level']?.toString() ?? 'low';

      final prompt =
          """
Based on this CRITICAL message, generate 5 URGENT concern questions:

CRITICAL MESSAGE: "$criticalMsg"

Detected Emotion: $emotion
Risk Level: HIGH

Generate 5 questions about immediate safety and support needs.
For EACH question, provide 4-5 answer options focused on urgency.

IMPORTANT: Return as a JSON array where each item has:
{
  "question": "The concern question",
  "options": ["Option 1", "Option 2", "Option 3", "Option 4"]
}

Focus on: Immediate safety, professional help, support network.

Return ONLY valid JSON array.
""";

      final response = await _sendToAI(prompt, temperature: 0.3);

      try {
        final List<dynamic> questionsData = jsonDecode(response);
        setState(() {
          _concernQuestions = List<Map<String, dynamic>>.from(
            questionsData.map(
              (item) => ({
                'question': item['question']?.toString() ?? '',
                'options': List<String>.from(item['options'] ?? []),
              }),
            ),
          );
        });
      } catch (e) {
        setState(() {
          _concernQuestions = _getCriticalQuestions();
        });
      }
    } catch (e) {
      setState(() {
        _concernQuestions = _getCriticalQuestions();
      });
    } finally {
      setState(() {
        _isGeneratingQuestions = false;
      });
    }
  }

  // EXISTING CODE - NO CHANGES
  List<Map<String, dynamic>> _getCriticalQuestions() {
    return [
      {
        'question': "How immediate do you feel the need for help is?",
        'options': [
          "Right now - I need immediate help",
          "Within the next few hours",
          "Today, but I can wait",
          "I'm not sure about timing",
        ],
      },
      {
        'question': "Do you feel safe right now?",
        'options': [
          "Yes, I feel safe",
          "Mostly, but a bit worried",
          "Not completely safe",
          "No, I don't feel safe at all",
        ],
      },
      {
        'question': "Have you thought about contacting a crisis helpline?",
        'options': [
          "Yes, and I'm willing to call",
          "I'm considering it",
          "No, I don't want to",
          "I don't know any helplines",
        ],
      },
      {
        'question': "What would help you feel safer right now?",
        'options': [
          "Speaking with a professional",
          "Having someone check on me",
          "Getting practical advice",
          "Just knowing help is available",
        ],
      },
      {
        'question': "Are you willing to accept help if offered?",
        'options': [
          "Yes, I want help",
          "I'm open to suggestions",
          "I'm not sure yet",
          "I prefer to handle it alone",
        ],
      },
    ];
  }

  // EXISTING CODE - NO CHANGES
  Future<void> _sendToAdminAlert() async {
    setState(() {
      _hasSentAlert = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user != null) {
        final answersSummary = _getAnswersSummary();

        final api = ApiPhp(
          tableName: 'admin_alerts',
          parameters: {
            'user_id': user.id,
            'user_message': criticalMsg,
            'description': _getAlertDescription(answersSummary),
            'concern_answers': answersSummary,
            'created_date': DateTime.now().toIso8601String(),
            'status': 'pending',
            'priority': 'critical',
            'emotion': _analysisData?['emotion'] ?? 'unknown',
            'stress_level': _analysisData?['stress_level'] ?? 'unknown',
            'risk_level': _analysisData?['risk_level'] ?? 'unknown',
          },
        );

        final response = await api.insertAdminAlert();
        print("Admin alert response: $response");

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚨 Support team has been notified'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Close after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context, true);
        });
      }
    } catch (e) {
      print("Error sending admin alert: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send alert: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // EXISTING CODE - NO CHANGES
  String _getAnswersSummary() {
    if (selectedAnswers.isEmpty) return 'No answers provided';

    return _concernQuestions
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key + 1;
          final question = entry.value;
          final answer = selectedAnswers['q$index'] ?? 'Not answered';
          return 'Q$index: ${question['question']}\nA: $answer';
        })
        .join('\n\n');
  }

  // EXISTING CODE - NO CHANGES
  String _getAlertDescription(String answersSummary) {
    final emotion = _analysisData?['emotion'] ?? 'unknown';

    return """
🚨 CRITICAL ALERT: Immediate Attention Required

Critical Message: "$criticalMsg"
Emotion: ${emotion.toUpperCase()}
Risk Level: HIGH

User has expressed critical concerns requiring immediate professional intervention.
Concern assessment has been completed.

USER RESPONSES:
$answersSummary

URGENT ACTION REQUIRED: Contact user immediately.
""";
  }

  // EXISTING CODE - NO CHANGES
  Future<String> _sendToAI(String prompt, {double temperature = 0.5}) async {
    try {
      final response = await http.post(
        Uri.parse("http://192.168.8.171:11434/api/generate"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "model": "gemma3:4b",
          "prompt": prompt,
          "stream": false,
          "options": {
            "num_predict": 300,
            "temperature": temperature,
            "top_p": 0.95,
            "repeat_penalty": 1.05,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? "[]";
      }
      return "[]";
    } catch (e) {
      return "[]";
    }
  }

  // EXISTING CODE - NO CHANGES
  void _handleAnswerSelect(String questionId, String answer) {
    setState(() {
      selectedAnswers[questionId] = answer;
    });
  }

  // EXISTING CODE - NO CHANGES
  void _submitAllAnswers() {
    if (selectedAnswers.length < _concernQuestions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all questions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _sendToAdminAlert();
  }

  // EXISTING CODE - NO CHANGES
  Color _getRiskColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  // EXISTING CODE - NO CHANGES
  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
      case 'masaya':
      case 'malipayon':
        return Colors.green;
      case 'sad':
      case 'malungkot':
      case 'masubo':
        return Colors.blue;
      case 'stressed':
      case 'stress':
        return Colors.orange;
      case 'angry':
      case 'galit':
      case 'akig':
        return Colors.red;
      case 'lonely':
      case 'nag-iisa':
      case 'naga-isahan':
        return Colors.purple;
      case 'anxious':
      case 'nababahala':
      case 'nabalaka':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // EXISTING CODE - NO CHANGES
  Color _getStressColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  // EXISTING CODE - NO CHANGES
  String _getEmotionDescription(String emotion, String riskLevel) {
    final isHighRisk = riskLevel.toLowerCase() == 'high';

    if (isHighRisk) {
      return 'High emotional intensity detected. Professional support recommended.';
    }

    switch (emotion.toLowerCase()) {
      case 'happy':
      case 'masaya':
      case 'malipayon':
        return 'Positive emotional state detected. Keep up the good mood!';
      case 'sad':
      case 'malungkot':
      case 'masubo':
        return 'Feeling down is normal. Consider talking to someone you trust.';
      case 'stressed':
      case 'stress':
        return 'Stress detected. Try relaxation techniques like deep breathing.';
      case 'angry':
      case 'galit':
      case 'akig':
        return 'Anger detected. Healthy expression is important.';
      case 'lonely':
      case 'nag-iisa':
      case 'naga-isahan':
        return 'Feeling lonely. Reach out to friends or family.';
      case 'anxious':
      case 'nababahala':
      case 'nabalaka':
        return 'Anxiety detected. Grounding exercises may help.';
      default:
        return 'Emotional state analyzed.';
    }
  }

  // EXISTING CODE - NO CHANGES
  String _getRiskDescription(String riskLevel, String criticalMsg) {
    final hasCritical = criticalMsg.isNotEmpty;

    if (hasCritical) {
      return '🚨 CRITICAL: Immediate professional attention required.';
    }

    switch (riskLevel.toLowerCase()) {
      case 'high':
        return 'High risk detected. Consider seeking support.';
      case 'moderate':
        return 'Moderate concerns. Monitor your emotional state.';
      case 'low':
        return 'Low risk. Your emotional state appears stable.';
      default:
        return 'Risk level assessed.';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingScreen) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Analyzing conversation...'),
            ],
          ),
        ),
      );
    }

    if (_analysisData == null) {
      return const Scaffold(
        body: Center(child: Text('Failed to load analysis')),
      );
    }

    final emotion = _analysisData!['emotion']?.toString() ?? 'neutral';
    final stressLevel = _analysisData!['stress_level']?.toString() ?? 'low';
    final riskLevel = _analysisData!['risk_level']?.toString() ?? 'low';
    final isHighRisk = riskLevel.toLowerCase() == 'high';
    final hasCriticalMessage = criticalMsg.isNotEmpty;
    final showQuestions = isHighRisk && hasCriticalMessage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation Analysis'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 2,
        // ADDED: Show mood saving indicator in app bar
        actions: [
          if (_isSavingMood)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Saving mood...',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFF), Color(0xFFF0F4FF)],
          ),
        ),
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Status Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: hasCriticalMessage
                            ? [Colors.red.shade50, Colors.orange.shade50]
                            : isHighRisk
                            ? [Colors.orange.shade50, Colors.yellow.shade50]
                            : [Colors.green.shade50, Colors.lightGreen.shade50],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: hasCriticalMessage
                            ? Colors.red.withOpacity(0.3)
                            : isHighRisk
                            ? Colors.orange.withOpacity(0.3)
                            : Colors.green.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          hasCriticalMessage
                              ? Icons.warning_amber
                              : isHighRisk
                              ? Icons.warning
                              : Icons.check_circle,
                          color: hasCriticalMessage
                              ? Colors.red
                              : isHighRisk
                              ? Colors.orange
                              : Colors.green,
                          size: 32,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasCriticalMessage
                                    ? '🚨 CRITICAL ALERT'
                                    : isHighRisk
                                    ? 'MODERATE CONCERN'
                                    : 'SAFE CONVERSATION',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: hasCriticalMessage
                                      ? Colors.red
                                      : isHighRisk
                                      ? Colors.orange
                                      : Colors.green,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                hasCriticalMessage
                                    ? 'Immediate attention required'
                                    : isHighRisk
                                    ? 'Some concerns detected'
                                    : 'No critical issues found',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: hasCriticalMessage
                                      ? Colors.red.shade800
                                      : isHighRisk
                                      ? Colors.orange.shade800
                                      : Colors.green.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Analysis Cards
                  Row(
                    children: [
                      _buildEmotionCard(emotion),
                      const SizedBox(width: 12),
                      _buildStressCard(stressLevel),
                      const SizedBox(width: 12),
                      _buildRiskCard(riskLevel, hasCriticalMessage),
                    ],
                  ),
                ],
              ),
            ),

            // ADDED: Mood Saved Indicator
            if (_moodSavedSuccessfully && !_isSavingMood)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                color: Colors.green.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mood analysis saved to your journal',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // Content Section
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Critical Message (if exists)
                    if (hasCriticalMessage)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber,
                                  color: Colors.red,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Critical Message Detected',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade100),
                              ),
                              child: Text(
                                '"$criticalMsg"',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Questions Section (ONLY for critical messages)
                    if (showQuestions) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Urgent Safety Assessment',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Please answer these questions so we can provide appropriate support:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 20),

                            if (_isGeneratingQuestions)
                              const Center(
                                child: Column(
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 20),
                                    Text('Generating assessment questions...'),
                                  ],
                                ),
                              )
                            else if (_concernQuestions.isEmpty)
                              const Center(
                                child: Text('No questions available'),
                              )
                            else
                              ..._concernQuestions.asMap().entries.map((entry) {
                                final index = entry.key;
                                final question = entry.value;
                                final questionText =
                                    question['question']?.toString() ?? '';
                                final options = List<String>.from(
                                  question['options'] ?? [],
                                );
                                final questionId = 'q${index + 1}';

                                return _buildQuestionCard(
                                  index,
                                  questionText,
                                  options,
                                  questionId,
                                );
                              }).toList(),
                          ],
                        ),
                      ),

                      // Submit Button (only for critical)
                      if (_concernQuestions.isNotEmpty &&
                          !_isGeneratingQuestions)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 20),
                          child: ElevatedButton(
                            onPressed: _submitAllAnswers,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: _hasSentAlert
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle, size: 20),
                                      SizedBox(width: 10),
                                      Text(
                                        'Alert Sent - Closing...',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'Submit Assessment & Notify Support',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                    ],

                    // Summary Section (for ALL cases)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Analysis Summary',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),

                          // ADDED: Mood Storage Info
                          if (_moodSavedSuccessfully)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.blue.shade100),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.emoji_emotions,
                                    color: Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Mood Saved to Journal',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                        Text(
                                          'Emotion: $emotion | Intensity: ${_calculateIntensity(riskLevel, stressLevel)}/10',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.check_circle, color: Colors.green),
                                ],
                              ),
                            ),

                          // Emotion Summary
                          ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _getEmotionColor(
                                  emotion,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.emoji_emotions,
                                color: _getEmotionColor(emotion),
                              ),
                            ),
                            title: Text(
                              'Emotional State',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            subtitle: Text(
                              emotion.toUpperCase(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _getEmotionColor(emotion),
                              ),
                            ),
                          ),

                          // Risk Summary
                          ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _getRiskColor(
                                  riskLevel,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.warning,
                                color: _getRiskColor(riskLevel),
                              ),
                            ),
                            title: Text(
                              'Risk Assessment',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  riskLevel.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _getRiskColor(riskLevel),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getRiskDescription(riskLevel, criticalMsg),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Recommendations
                          if (!showQuestions)
                            Container(
                              margin: const EdgeInsets.only(top: 20),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.shade100,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.thumb_up, color: Colors.green),
                                      SizedBox(width: 10),
                                      Text(
                                        'Recommendations',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _getEmotionDescription(emotion, riskLevel),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Close Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: showQuestions
                              ? Colors.white
                              : Colors.blueAccent,
                          foregroundColor: showQuestions
                              ? Colors.blueAccent
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: showQuestions
                                ? const BorderSide(color: Colors.blueAccent)
                                : BorderSide.none,
                          ),
                          elevation: showQuestions ? 0 : 2,
                        ),
                        child: Text(
                          showQuestions
                              ? 'Close Without Submitting'
                              : 'Close Analysis',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // EXISTING CODE - NO CHANGES
  Widget _buildEmotionCard(String emotion) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getEmotionColor(emotion).withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                Icons.emoji_emotions,
                color: _getEmotionColor(emotion),
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              emotion.toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _getEmotionColor(emotion),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Emotion',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // EXISTING CODE - NO CHANGES
  Widget _buildStressCard(String stressLevel) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getStressColor(stressLevel).withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                Icons.thermostat,
                color: _getStressColor(stressLevel),
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              stressLevel.toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _getStressColor(stressLevel),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Stress Level',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // EXISTING CODE - NO CHANGES
  Widget _buildRiskCard(String riskLevel, bool hasCritical) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getRiskColor(riskLevel).withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                hasCritical ? Icons.warning_amber : Icons.warning,
                color: _getRiskColor(riskLevel),
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              riskLevel.toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _getRiskColor(riskLevel),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Risk Level',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // EXISTING CODE - NO CHANGES
  Widget _buildQuestionCard(
    int index,
    String questionText,
    List<String> options,
    String questionId,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  questionText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Answer Options
          ...options.map((option) {
            final isSelected = selectedAnswers[questionId] == option;
            return RadioListTile<String>(
              title: Text(option),
              value: option,
              groupValue: selectedAnswers[questionId],
              onChanged: (value) => _handleAnswerSelect(questionId, value!),
              activeColor: Colors.red,
            );
          }),
        ],
      ),
    );
  }
}
