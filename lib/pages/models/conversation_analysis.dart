// lib/provider/conversation_analyzer_provider.dart
import 'package:flutter/foundation.dart';

class ConversationAnalysis {
  final String sessionId;
  final double emotionalIntensity;
  final List<String> detectedMoods;
  final List<String> keyTopics;
  final bool requiresReflection;
  final String summary;
  final DateTime analyzedAt;

  ConversationAnalysis({
    required this.sessionId,
    required this.emotionalIntensity,
    required this.detectedMoods,
    required this.keyTopics,
    required this.requiresReflection,
    required this.summary,
    required this.analyzedAt,
  });
}

class ConversationAnalyzerProvider with ChangeNotifier {
  bool _isAnalyzing = false;
  ConversationAnalysis? _lastAnalysis;

  bool get isAnalyzing => _isAnalyzing;
  ConversationAnalysis? get lastAnalysis => _lastAnalysis;

  // Analyze conversation and determine if mood reflection is needed
  Future<ConversationAnalysis> analyzeConversation({
    required List<Map<String, dynamic>> messages,
    required String sessionId,
  }) async {
    _isAnalyzing = true;
    // Don't call notifyListeners() here during build phase

    try {
      final analysis = _performAnalysis(messages, sessionId);
      _lastAnalysis = analysis;
      _isAnalyzing = false;
      // We'll notify listeners after the build phase
      return analysis;
    } catch (e) {
      _isAnalyzing = false;
      rethrow;
    }
  }

  ConversationAnalysis _performAnalysis(
    List<Map<String, dynamic>> messages,
    String sessionId,
  ) {
    // Your existing analysis logic
    final userMessages = messages
        .where((msg) => msg['isUser'] == true)
        .map((msg) => msg['message'].toString().toLowerCase())
        .toList();

    final emotionalIntensity = _calculateEmotionalIntensity(userMessages);
    final detectedMoods = _detectMoods(userMessages);
    final keyTopics = _extractKeyTopics(userMessages);
    final requiresReflection = _shouldRequireReflection(
      emotionalIntensity,
      detectedMoods,
      userMessages,
    );
    final summary = _generateSummary(
      emotionalIntensity,
      detectedMoods,
      keyTopics,
    );

    return ConversationAnalysis(
      sessionId: sessionId,
      emotionalIntensity: emotionalIntensity,
      detectedMoods: detectedMoods,
      keyTopics: keyTopics,
      requiresReflection: requiresReflection,
      summary: summary,
      analyzedAt: DateTime.now(),
    );
  }

  double _calculateEmotionalIntensity(List<String> messages) {
    if (messages.isEmpty) return 0.0;

    final emotionalWords = {
      // Positive emotions
      'happy': 0.3, 'good': 0.2, 'better': 0.3, 'great': 0.4, 'amazing': 0.5,
      'wonderful': 0.5, 'excited': 0.4, 'hopeful': 0.3, 'relieved': 0.3,
      'calm': 0.2, 'peaceful': 0.3, 'grateful': 0.4,

      // Negative emotions
      'sad': 0.6, 'bad': 0.4, 'worse': 0.5, 'terrible': 0.7, 'awful': 0.7,
      'angry': 0.6, 'mad': 0.6, 'frustrated': 0.5, 'anxious': 0.6,
      'worried': 0.5, 'scared': 0.6, 'afraid': 0.6, 'nervous': 0.5,
      'stressed': 0.5, 'overwhelmed': 0.7, 'hopeless': 0.8, 'lonely': 0.7,
      'tired': 0.4, 'exhausted': 0.5,

      // High-intensity words
      'love': 0.6, 'hate': 0.8, 'desperate': 0.9, 'suicidal': 1.0,
      'cannot take': 0.8, 'end it': 0.9, 'give up': 0.7,
    };

    double totalIntensity = 0.0;
    int emotionalMessageCount = 0;

    for (final message in messages) {
      double messageIntensity = 0.0;
      emotionalWords.forEach((word, intensity) {
        if (message.contains(word)) {
          messageIntensity = messageIntensity > intensity
              ? messageIntensity
              : intensity;
        }
      });

      if (messageIntensity > 0) {
        totalIntensity += messageIntensity;
        emotionalMessageCount++;
      }
    }

    // Calculate average intensity, with base score for any conversation
    final baseScore = messages.length > 2 ? 0.1 : 0.0;
    final emotionalScore = emotionalMessageCount > 0
        ? totalIntensity / emotionalMessageCount
        : 0.0;

    return (baseScore + emotionalScore).clamp(0.0, 1.0);
  }

  List<String> _detectMoods(List<String> messages) {
    final moodPatterns = {
      'Anxious': ['anxious', 'worried', 'nervous', 'scared', 'afraid', 'panic'],
      'Sad': [
        'sad',
        'unhappy',
        'depressed',
        'miserable',
        'hopeless',
        'tearful',
      ],
      'Angry': [
        'angry',
        'mad',
        'frustrated',
        'irritated',
        'annoyed',
        'furious',
      ],
      'Stressed': [
        'stressed',
        'overwhelmed',
        'pressure',
        'burnout',
        'exhausted',
      ],
      'Happy': ['happy', 'good', 'great', 'wonderful', 'amazing', 'excited'],
      'Calm': ['calm', 'peaceful', 'relaxed', 'serene', 'content'],
      'Grateful': ['grateful', 'thankful', 'appreciate', 'blessed'],
      'Confused': ['confused', 'unsure', 'uncertain', 'lost', 'doubt'],
      'Lonely': ['lonely', 'alone', 'isolated', 'empty'],
    };

    final detectedMoods = <String>[];
    final moodScores = <String, int>{};

    for (final message in messages) {
      moodPatterns.forEach((mood, patterns) {
        for (final pattern in patterns) {
          if (message.contains(pattern)) {
            moodScores[mood] = (moodScores[mood] ?? 0) + 1;
            if (!detectedMoods.contains(mood)) {
              detectedMoods.add(mood);
            }
          }
        }
      });
    }

    // Sort by frequency and return top 3 moods
    detectedMoods.sort(
      (a, b) => (moodScores[b] ?? 0).compareTo(moodScores[a] ?? 0),
    );
    return detectedMoods.take(3).toList();
  }

  List<String> _extractKeyTopics(List<String> messages) {
    final topicPatterns = {
      'Work': ['work', 'job', 'career', 'boss', 'colleague', 'office'],
      'Relationships': [
        'friend',
        'partner',
        'family',
        'relationship',
        'boyfriend',
        'girlfriend',
      ],
      'Health': ['health', 'sick', 'pain', 'doctor', 'hospital', 'medical'],
      'Sleep': ['sleep', 'tired', 'insomnia', 'dream', 'night'],
      'Food': ['food', 'eat', 'diet', 'hungry', 'meal'],
      'Exercise': ['exercise', 'workout', 'gym', 'run', 'walk'],
      'School': ['school', 'study', 'exam', 'test', 'homework'],
      'Money': ['money', 'financial', 'bill', 'debt', 'expensive'],
      'Future': ['future', 'goal', 'plan', 'dream', 'ambition'],
    };

    final topics = <String>[];
    final topicScores = <String, int>{};

    for (final message in messages) {
      topicPatterns.forEach((topic, patterns) {
        for (final pattern in patterns) {
          if (message.contains(pattern)) {
            topicScores[topic] = (topicScores[topic] ?? 0) + 1;
            if (!topics.contains(topic)) {
              topics.add(topic);
            }
          }
        }
      });
    }

    // Return top 3 topics
    topics.sort((a, b) => (topicScores[b] ?? 0).compareTo(topicScores[a] ?? 0));
    return topics.take(3).toList();
  }

  bool _shouldRequireReflection(
    double emotionalIntensity,
    List<String> moods,
    List<String> messages,
  ) {
    // Always require reflection for intense conversations
    if (emotionalIntensity > 0.6) return true;

    // Require reflection for negative emotional conversations
    if (moods.any(
      (mood) =>
          ['Anxious', 'Sad', 'Angry', 'Stressed', 'Lonely'].contains(mood),
    )) {
      return true;
    }

    // Require reflection for longer conversations (more than 3 messages)
    if (messages.length > 3) return true;

    // Require reflection if specific intense words are present
    final intenseWords = [
      'better',
      'worse',
      'helped',
      'changed',
      'realized',
      'understand',
    ];
    if (messages.any(
      (message) => intenseWords.any((word) => message.contains(word)),
    )) {
      return true;
    }

    return false;
  }

  String _generateSummary(
    double intensity,
    List<String> moods,
    List<String> topics,
  ) {
    if (intensity < 0.3) {
      return "This was a light conversation. You seemed to be in a relatively neutral state.";
    } else if (intensity < 0.6) {
      return "This was an emotionally engaged conversation. You expressed ${moods.isNotEmpty ? moods.join(' and ') : 'various feelings'}.";
    } else {
      return "This was an intense conversation. You expressed strong emotions of ${moods.isNotEmpty ? moods.join(' and ') : 'emotional distress'}.";
    }
  }

  void clearAnalysis() {
    _lastAnalysis = null;
    notifyListeners();
  }
}
