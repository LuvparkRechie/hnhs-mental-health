import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'users/analysis_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // AI Service Configuration
  final String _baseUrl = "http://192.168.8.171:11434/api/generate";

  // Conversation data
  final List<Map<String, dynamic>> _messages = [
    {
      "role": "assistant",
      "content": "Hello! 👋 I'm your AI assistant. How can I help you today?",
      "timestamp": DateTime.now(),
      "isUser": false,
    },
  ];

  // Analysis data
  final String _emotionAnalysisJson = "";
  bool _isLoading = false;
  bool _showAnalysis = false;
  final bool _isAnalyzing = false;

  // Send HTTP request to AI
  Future<String> _sendToAI(
    String prompt, {
    double temperature = 0.5,
    int numPredict = 150,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "model": "gemma3:4b",
          "prompt": prompt,
          "stream": false,
          "options": {
            "num_predict": numPredict,
            "temperature": temperature,
            "top_p": 0.95,
            "repeat_penalty": 1.05,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? "No response from AI";
      } else {
        return "Server error: ${response.statusCode}";
      }
    } catch (e) {
      return "Connection error: $e";
    }
  }

  // Send message to AI
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    // Add user message
    setState(() {
      _messages.add({
        "role": "user",
        "content": message,
        "timestamp": DateTime.now(),
        "isUser": true,
      });
      _messageController.clear();
      _isLoading = true;
      _showAnalysis = false;
    });

    _scrollToBottom();

    try {
      // Prepare conversation history
      final conversationText = _messages
          .where((m) => m['content'] != null)
          .map((m) => "${m['role']}: ${m['content']}")
          .join('\n');

      final prompt =
          """
$conversationText

Respond naturally to the conversation.
Do NOT add explanations, advice, or mention you are an AI.
Keep it concise and helpful.
""";

      final response = await _sendToAI(prompt, temperature: 0.5);

      // Add AI response
      setState(() {
        _messages.add({
          "role": "assistant",
          "content": response,
          "timestamp": DateTime.now(),
          "isUser": false,
        });
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({
          "role": "assistant",
          "content":
              "Sorry, I'm having trouble responding right now. Please try again.",
          "timestamp": DateTime.now(),
          "isUser": false,
        });
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  // Analyze conversation emotion
  Future<void> _analyzeEmotion() async {
    try {
      // Get all user messages
      final userMessages = _messages
          .where((m) => m['role'] == 'user' || m['isUser'] == true)
          .where(
            (m) => m['content'] != null && m['content'].toString().isNotEmpty,
          )
          .map((m) => "- ${m['content']}")
          .join('\n');

      if (userMessages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No messages to analyze'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Analyzing conversation...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Call the AI for emotion analysis
      final prompt =
          """
            You are a STRICT emotion and risk classifier.

            Analyze ALL messages below as ONE combined input.

            CLASSIFICATION RULES (MANDATORY):
            - If ANY message includes explicit self-harm or suicide intent
              (e.g. "end my life", "kill myself", "end it all"),
              then risk_level MUST be "high".
            - If risk_level is "high", extract the EXACT message text that triggered it.
            - If no such message exists, critical_message MUST be an empty string.
            - Do NOT soften, reinterpret, or downplay.
            - Ignore conversational tone.
            - Do NOT provide advice, explanations, or empathy.
            - Return ONLY valid JSON.

            Output format:
            {
              "emotion": "sad | happy | stressed | neutral | angry | lonely | anxious",
              "stress_level": "low | moderate | high",
              "risk_level": "low | moderate | high",
              "critical_message": ""
            }

            Messages:
            $userMessages
            """;

      final response = await _sendToAI(prompt, temperature: 0);

      // Clean the response
      final cleanResponse = response
          .replaceAll('```', '')
          .replaceAll('json', '')
          .trim();

      // Navigate to the AnalysisScreen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnalysisScreen(
            analysisJson: cleanResponse,
            conversation: _messages,
          ),
        ),
      );
      if (result == true) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analysis failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // UI Components
  Widget _buildAnalysisResult() {
    try {
      final jsonData = jsonDecode(_emotionAnalysisJson);
      final emotion = jsonData['emotion']?.toString() ?? 'unknown';
      final stressLevel = jsonData['stress_level']?.toString() ?? 'unknown';
      final riskLevel = jsonData['risk_level']?.toString() ?? 'unknown';

      Color getRiskColor(String level) {
        switch (level.toLowerCase()) {
          case 'high':
            return Colors.redAccent;
          case 'moderate':
            return Colors.orange;
          default:
            return Colors.green;
        }
      }

      Color getEmotionColor(String emotion) {
        switch (emotion.toLowerCase()) {
          case 'happy':
            return Colors.green;
          case 'sad':
            return Colors.blue;
          case 'stressed':
          case 'anxious':
            return Colors.orange;
          case 'angry':
            return Colors.red;
          case 'lonely':
            return Colors.purple;
          default:
            return Colors.grey;
        }
      }

      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.insights,
                    color: Colors.blueAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Conversation Analysis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showAnalysis = false;
                    });
                  },
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Analysis Cards
            Row(
              children: [
                _buildAnalysisCard(
                  'Emotion',
                  emotion,
                  Icons.emoji_emotions,
                  getEmotionColor(emotion),
                ),
                const SizedBox(width: 12),
                _buildAnalysisCard(
                  'Stress Level',
                  stressLevel,
                  Icons.thermostat,
                  Colors.orange,
                ),
                const SizedBox(width: 12),
                _buildAnalysisCard(
                  'Risk Level',
                  riskLevel,
                  Icons.warning,
                  getRiskColor(riskLevel),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Raw JSON Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Analysis Data',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _emotionAnalysisJson,
                    style: const TextStyle(
                      fontFamily: 'Monospace',
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analysis Result',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SelectableText(
              _emotionAnalysisJson,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildAnalysisCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value.toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['role'] == 'user' || message['isUser'] == true;
    final content = message['content']?.toString() ?? '';
    final timestamp = message['timestamp'] is DateTime
        ? message['timestamp'] as DateTime
        : DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blueAccent, Colors.lightBlueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          if (!isUser) const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.blueAccent : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: isUser
                          ? const Radius.circular(20)
                          : const Radius.circular(4),
                      bottomRight: isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content,
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.black87,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(timestamp),
                        style: TextStyle(
                          color: isUser
                              ? Colors.white.withValues(alpha: 0.8)
                              : Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 12),
          if (isUser)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.grey, Colors.grey],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: 5,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                      ),
                      style: const TextStyle(fontSize: 15),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isLoading ? 56 : 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isLoading
                    ? [Colors.grey, Colors.grey.shade400]
                    : [Colors.blueAccent, Colors.lightBlueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: _isLoading
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.blueAccent.withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
              onPressed: _isLoading || _messageController.text.trim().isEmpty
                  ? null
                  : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'AI Chat Assistant',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          actions: [
            if (_messages.length > 1 && !_showAnalysis)
              IconButton(
                onPressed: _isAnalyzing ? null : _analyzeEmotion,
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.blueAccent),
                        ),
                      )
                    : const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Colors.green,
                        size: 24,
                      ),
                tooltip: 'Analyze Conversation',
              ),
          ],
        ),
        body: Stack(
          children: [
            // Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF8FAFF), Color(0xFFF0F4FF)],
                ),
              ),
            ),

            // Content
            Column(
              children: [
                // Analysis Result
                if (_showAnalysis && _emotionAnalysisJson.isNotEmpty)
                  Expanded(
                    child: SingleChildScrollView(child: _buildAnalysisResult()),
                  ),

                // Chat Messages
                Expanded(
                  flex: _showAnalysis ? 2 : 3,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
                ),

                // Input Area
                _buildInputArea(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
