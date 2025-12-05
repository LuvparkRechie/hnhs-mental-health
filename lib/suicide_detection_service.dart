// lib/services/suicide_detection_service.dart
import 'package:flutter/foundation.dart';

class SuicideDetectionService {
  // Keywords that might indicate concerning thoughts - COMPREHENSIVE LIST
  static const List<String> _highRiskKeywords = [
    'kill myself',
    'kill my self',
    'kill myself.',
    'kill myself!',
    'kill myself?',
    'end it all',
    'want to die',
    'suicide',
    'commit suicide',
    'end my life',
    'take my life',
    'no reason to live',
    'better off dead',
    'self harm',
    'hurt myself',
    'no way out',
    'end everything',
    'not want to live',
    'can\'t go on',
    'give up on life',
  ];

  static const List<String> _moderateRiskKeywords = [
    'depressed',
    'hopeless',
    'overwhelmed',
    'struggling',
    'alone',
    'empty inside',
    'lost',
    'scared',
    'worthless',
    'give up',
    'can\'t cope',
    'no hope',
    'nothing matters',
    'tired of life',
    'no point',
    'miserable',
    'in pain',
    'suffering',
  ];

  static const List<String> _lowRiskKeywords = [
    'stressed',
    'worried',
    'tired',
    'sad',
    'down',
    'upset',
    'frustrated',
    'anxious',
    'nervous',
    'overwhelmed',
    'burnt out',
    'exhausted',
  ];

  // Supportive responses
  static const List<String> _highRiskResponses = [
    "I'm really concerned about what you're sharing. Your feelings are valid and important.",
    "Thank you for trusting me with this. I hear how much pain you're in.",
    "It sounds like you're going through an incredibly difficult time.",
    "I can hear the depth of your pain in what you're sharing.",
  ];

  static const List<String> _moderateRiskResponses = [
    "That sounds really difficult to be dealing with.",
    "I hear how much you're struggling right now.",
    "It sounds like you're carrying a heavy burden.",
    "Thank you for sharing that with me.",
    "I can hear that you're going through a tough time.",
  ];

  static const List<String> _lowRiskResponses = [
    "I'm sorry you're feeling that way.",
    "It sounds like you've been dealing with some challenges.",
    "Thank you for sharing that.",
    "I hear you. It's completely normal to feel that way sometimes.",
    "That sounds tough. Would you like to talk more about it?",
  ];

  static const List<String> _followUpQuestions = [
    "How long have you been feeling this way?",
    "Have you talked to anyone about what you're going through?",
    "What usually helps you feel better?",
    "Is there someone you feel comfortable reaching out to?",
  ];

  // Emergency response for high-risk situations
  static const String _emergencyResponse =
      "I'm really concerned about what you're sharing. It sounds like you're going through an incredibly difficult time, and I want you to know that your life has value and meaning. Would you be open to talking with a trained professional who can provide immediate support? I'm here to listen, but I also want to make sure you get the help you deserve.";

  // Analyze message for concerning content
  Map<String, dynamic> analyzeMessage(String message) {
    final String lowerMessage = _cleanMessage(message);
    double riskScore = 0.0;
    List<String> detectedKeywords = [];
    bool requiresImmediateAttention = false;
    String? supportiveResponse;

    if (kDebugMode) {
      print('🔍 ANALYZING MESSAGE: "$message"');
      print('   Cleaned message: "$lowerMessage"');
    }

    // Check for high-risk keywords
    for (String keyword in _highRiskKeywords) {
      if (_containsWord(lowerMessage, keyword)) {
        riskScore = 0.9; // High risk overrides everything
        detectedKeywords.add(keyword);
        requiresImmediateAttention = true;
        supportiveResponse = _emergencyResponse;

        if (kDebugMode) {
          print('   🚨 HIGH RISK DETECTED: "$keyword"');
        }
        break; // Found high risk, stop checking
      }
    }

    // Only check moderate risk if no high risk found
    if (!requiresImmediateAttention) {
      for (String keyword in _moderateRiskKeywords) {
        if (_containsWord(lowerMessage, keyword)) {
          riskScore += 0.4;
          detectedKeywords.add(keyword);

          if (kDebugMode) {
            print('   🟡 MODERATE RISK DETECTED: "$keyword"');
          }
        }
      }
    }

    // Only check low risk if no higher risks found
    if (riskScore < 0.5) {
      for (String keyword in _lowRiskKeywords) {
        if (_containsWord(lowerMessage, keyword)) {
          riskScore += 0.2;
          detectedKeywords.add(keyword);

          if (kDebugMode) {
            print('   🟢 LOW RISK DETECTED: "$keyword"');
          }
        }
      }
    }

    // Cap the risk score
    riskScore = riskScore > 1.0 ? 1.0 : riskScore;

    // Select supportive response if not already set (for high risk)
    if (!requiresImmediateAttention) {
      if (riskScore >= 0.7) {
        supportiveResponse =
            _highRiskResponses[DateTime.now().millisecond %
                _highRiskResponses.length];
        requiresImmediateAttention =
            true; // Auto-elevate to immediate attention
      } else if (riskScore >= 0.4) {
        supportiveResponse =
            _moderateRiskResponses[DateTime.now().millisecond %
                _moderateRiskResponses.length];
        // Add follow-up question sometimes
        if (DateTime.now().millisecond % 2 == 0) {
          supportiveResponse +=
              " ${_followUpQuestions[DateTime.now().millisecond % _followUpQuestions.length]}";
        }
      } else if (riskScore >= 0.1) {
        supportiveResponse =
            _lowRiskResponses[DateTime.now().millisecond %
                _lowRiskResponses.length];
      }
    }

    // DEBUG output
    if (kDebugMode) {
      print('🎯 DETECTION RESULTS:');
      print('   Final Risk Score: $riskScore');
      print('   Requires Immediate Attention: $requiresImmediateAttention');
      print('   Detected Keywords: $detectedKeywords');
      print(
        '   Supportive Response: ${supportiveResponse != null ? "YES" : "NO"}',
      );
      if (supportiveResponse != null) {
        print('   Response: "$supportiveResponse"');
      }
      print('---');
    }

    return {
      'riskScore': riskScore,
      'requiresImmediateAttention': requiresImmediateAttention,
      'supportiveResponse': supportiveResponse,
      'detectedKeywords': detectedKeywords,
    };
  }

  // Clean the message for better matching
  String _cleanMessage(String message) {
    return message.toLowerCase().trim();
  }

  // Check if message contains a specific word/phrase (case insensitive)
  bool _containsWord(String message, String word) {
    // Simple contains check for phrases
    if (word.contains(' ')) {
      return message.contains(word);
    }

    // For single words, use regex with word boundaries
    final pattern = RegExp(
      r'\b' + _escapeRegex(word) + r'\b',
      caseSensitive: false,
    );
    return pattern.hasMatch(message);
  }

  // Escape regex special characters
  String _escapeRegex(String input) {
    return input.replaceAllMapped(
      RegExp(r'[.*+?^${}()|[\]\\]'),
      (match) => '\\${match.group(0)}',
    );
  }

  // Test method to verify detection
  void testDetection() {
    if (kDebugMode) {
      print('🧪 TESTING SUICIDE DETECTION SERVICE');
    }

    final testMessages = [
      "kill my self",
      "kill myself",
      "I want to kill myself",
      "I feel like ending it all",
      "I'm so depressed",
      "I'm just stressed",
      "hello how are you",
      "I want to commit suicide",
      "life is not worth living",
    ];

    for (String message in testMessages) {
      if (kDebugMode) {
        print('\n=== TESTING: "$message" ===');
      }
      final result = analyzeMessage(message);
      if (kDebugMode) {
        print(
          'RESULT: Risk ${result['riskScore']}, Alert: ${result['requiresImmediateAttention']}',
        );
      }
    }
  }

  // Simple support suggestions
  static List<String> getSupportSuggestions() {
    return [
      "Consider talking to someone you trust",
      "Remember it's okay to ask for help",
      "Take things one day at a time",
      "Your feelings are valid and important",
      "Reach out to a mental health professional",
      "Call a crisis helpline for immediate support",
    ];
  }

  // Get crisis resources
  static List<String> getCrisisResources() {
    return [
      "National Suicide Prevention Lifeline: 1-800-273-8255",
      "Crisis Text Line: Text HOME to 741741",
      "Emergency: 911",
      "Talk to a trusted adult or healthcare provider",
    ];
  }
}
