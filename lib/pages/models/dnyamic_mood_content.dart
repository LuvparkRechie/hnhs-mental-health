// lib/models/dynamic_mood_content.dart
import 'package:flutter/material.dart';

class DynamicMoodContent {
  final String primaryMood;
  final double emotionalIntensity;
  final String screenTitle;
  final String mainQuestion;
  final String contextualDescription;
  final List<MoodOption> moodOptions;
  final List<String> aspects;
  final String intensityQuestion;
  final String reflectionPrompt;
  final Color primaryColor;
  final LinearGradient gradient;
  final IconData icon;

  DynamicMoodContent({
    required this.primaryMood,
    required this.emotionalIntensity,
    required this.screenTitle,
    required this.mainQuestion,
    required this.contextualDescription,
    required this.moodOptions,
    required this.aspects,
    required this.intensityQuestion,
    required this.reflectionPrompt,
    required this.primaryColor,
    required this.gradient,
    required this.icon,
  });
}

class MoodOption {
  final String emoji;
  final String label;
  final Color color;

  MoodOption({required this.emoji, required this.label, required this.color});
}
