// lib/pages/users/mood_tracking_screen.dart - SIMPLIFIED VERSION
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../pages/models/conversation_models.dart'; // Your Conversation model
import '../database_provider/database_provider.dart';

class MoodQuestionScreen extends StatefulWidget {
  final String chatSessionId;
  final List<Conversation>? conversationData; // REQUIRED parameter

  const MoodQuestionScreen({
    super.key,
    required this.chatSessionId,
    required this.conversationData, // Make it required
  });

  @override
  _MoodQuestionScreenState createState() => _MoodQuestionScreenState();
}

class _MoodQuestionScreenState extends State<MoodQuestionScreen>
    with SingleTickerProviderStateMixin {
  // Analysis Phase
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _analysisComplete = false;
  List<String> _detectedMoods = [];
  List<Map<String, dynamic>> _conversationMessages = [];

  // Mood Question Phase
  final List<MoodOption> _allMoodOptions = [
    MoodOption(emoji: '😊', label: 'Happy', color: Colors.green),
    MoodOption(emoji: '😢', label: 'Sad', color: Colors.blue),
    MoodOption(emoji: '😰', label: 'Anxious', color: Colors.orange),
    MoodOption(emoji: '😠', label: 'Angry', color: Colors.red),
    MoodOption(emoji: '😌', label: 'Calm', color: Colors.teal),
    MoodOption(emoji: '😴', label: 'Tired', color: Colors.purple),
    MoodOption(emoji: '🤔', label: 'Thoughtful', color: Colors.indigo),
    MoodOption(emoji: '😌', label: 'Relieved', color: Colors.lightGreen),
    MoodOption(emoji: '😔', label: 'Hopeless', color: Colors.brown),
    MoodOption(emoji: '😐', label: 'Neutral', color: Colors.grey),
    MoodOption(emoji: '🤗', label: 'Supported', color: Colors.pink),
    MoodOption(emoji: '😌', label: 'Understood', color: Colors.cyan),
  ];

  String? _selectedMood;
  int _intensity = 5;
  final TextEditingController _noteController = TextEditingController();

  // DYNAMIC CONTENT
  late String _dynamicQuestion;
  late String _dynamicSubtitle;
  late String _conversationContext;
  late String _conversationPreview;
  late List<MoodOption> _relevantMoodOptions;
  late String _intensityQuestion;
  late String _reflectionPrompt;
  late Color _themeColor;
  late LinearGradient _themeGradient;
  late IconData _themeIcon;

  bool _showMoodQuestion = false;
  bool _isUrgentConcern = false;
  bool _isDepressed = false;
  bool _isHappy = false;
  bool _isAnxious = false;
  bool _isAngry = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    // Initialize with default values
    _dynamicQuestion = 'How did this conversation make you feel?';
    _dynamicSubtitle =
        'Select the emotion that best describes your current state';
    _conversationContext =
        'Reflecting on our conversation helps understand your emotional journey';
    _conversationPreview = '';
    _relevantMoodOptions = _allMoodOptions;
    _intensityQuestion = 'How strong is this feeling?';
    _reflectionPrompt = 'Any thoughts about this feeling?';
    _themeColor = AppTheme.primaryRed;
    _themeGradient = AppTheme.primaryGradient;
    _themeIcon = Iconsax.message_question;

    _startAnalysis();
  }

  void _startAnalysis() async {
    _controller.repeat(reverse: true);

    // CRITICAL: Check if we have conversation data
    if (widget.conversationData == null || widget.conversationData!.isEmpty) {
      _showNoDataError();
      return;
    }

    // Convert the passed conversation data
    _conversationMessages = _convertToMessageFormat(widget.conversationData!);

    // Get only user messages
    _conversationMessages
        .where((msg) => msg['isUser'] == true)
        .map((msg) => msg['message'].toString().toLowerCase())
        .toList();

    await Future.delayed(Duration(milliseconds: 500));

    // Enhanced emotion detection
    _detectedMoods = _analyzeConversationMoodsAdvanced(_conversationMessages);

    // Check for emotional states with improved logic
    _checkForEmotionalStatesAdvanced();

    // AUTO-SELECT MOOD BASED ON DETECTION
    _autoSelectMood();

    // Generate dynamic content
    _generateDynamicContent();

    _controller.stop();
    setState(() {
      _analysisComplete = true;
    });

    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _showMoodQuestion = true;
    });
  }

  void _showNoDataError() {
    _controller.stop();
    setState(() {
      _analysisComplete = true;
    });

    // Show error message after a delay
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _showMoodQuestion = true;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Analysis Failed'),
            content: Text(
              'Could not retrieve conversation data. Please return to the chat and try again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      });
    });
  }

  void _autoSelectMood() {
    // Priority order: Urgent > Depressed > Happy > Anxious > Angry
    if (_isUrgentConcern) {
      _selectedMood = 'In Crisis';
      _intensity = 10;
      print('Auto-selected: In Crisis (Urgent)');
    } else if (_isDepressed) {
      _selectedMood = 'Heavy Heart';
      _intensity = 8;
      print('Auto-selected: Heavy Heart (Depressed)');
    } else if (_isHappy) {
      _selectedMood = 'Happy'; // AUTO-SELECT HAPPY
      _intensity = 7;
      print('Auto-selected: Happy (Happy)');
    } else if (_isAnxious) {
      _selectedMood = 'Worried';
      _intensity = 6;
      print('Auto-selected: Worried (Anxious)');
    } else if (_isAngry) {
      _selectedMood = 'Frustrated';
      _intensity = 6;
      print('Auto-selected: Frustrated (Angry)');
    } else {
      // If no strong emotion detected, check detected moods
      if (_detectedMoods.isNotEmpty && _detectedMoods[0] != 'Neutral') {
        final detectedMood = _detectedMoods[0];
        if (_allMoodOptions.any((mood) => mood.label == detectedMood)) {
          _selectedMood = detectedMood;
          print('Auto-selected from detected mood: $detectedMood');
        }
      }
    }
  }

  List<Map<String, dynamic>> _convertToMessageFormat(
    List<Conversation> conversations,
  ) {
    final List<Map<String, dynamic>> messages = [];

    for (var conv in conversations) {
      try {
        // Direct conversion from Conversation model
        final messageText = conv.message?.toString().trim() ?? '';

        if (messageText.isNotEmpty) {
          messages.add({'message': messageText, 'isUser': conv.isUser});
          print('✓ Converted: "$messageText" (isUser: ${conv.isUser})');
        }
      } catch (e) {
        print('Error converting conversation: $e');
      }
    }

    return messages;
  }

  void _checkForEmotionalStatesAdvanced() {
    final userMessages = _conversationMessages
        .where((msg) => msg['isUser'] == true)
        .map((msg) => msg['message'].toString().toLowerCase())
        .toList();

    if (userMessages.isEmpty) {
      print('No user messages found for emotion detection');
      return;
    }

    print('Analyzing ${userMessages.length} user messages for emotions...');

    // Define patterns
    final urgentPatterns = [
      'suicide',
      'suicidal',
      'end my life',
      'kill myself',
      'want to die',
      'not want to live',
      'end it all',
      'better off dead',
      'no point living',
      "can't go on",
      "cant go on",
      'give up on life',
      'life is worthless',
      'end everything',
      'want to disappear',
      'disappear forever',
      'hopeless',
      'nothing to live for',
      'no reason to live',
      'end it',
      'take my life',
    ];

    final depressionPatterns = [
      'depressed',
      'depression',
      'hopeless',
      'worthless',
      'useless',
      'empty',
      'numb',
      'nothing matters',
      "can't take it",
      "cant take it",
      "can't handle it",
      "cant handle it",
      'miserable',
      'unhappy',
      'sad all the time',
      'sad all day',
      'no hope',
      'no future',
      'no point',
      'cry all day',
      'cry all the time',
      'hate myself',
      "don't like myself",
      "dont like myself",
      'lonely',
      'alone',
      'isolated',
      'helpless',
    ];

    final happyPatterns = [
      'happy',
      'happiness',
      'joyful',
      'good',
      'great',
      'excellent',
      'awesome',
      'better',
      'improved',
      'progress',
      'relieved',
      'relief',
      'thankful',
      'grateful',
      'excited',
      'excitement',
      'looking forward',
      'proud',
      'accomplished',
      'achieved',
      'joy',
      'wonderful',
      'amazing',
      'fantastic',
      'feeling good',
      'feeling better',
      'feeling great',
      'optimistic',
      'positive',
      'hopeful',
      'glad',
      'pleased',
      'delighted',
    ];

    final anxiousPatterns = [
      'anxious',
      'anxiety',
      'worried',
      'worrying',
      'concerned',
      'nervous',
      'scared',
      'afraid',
      'fear',
      'panic',
      'panicking',
      'overwhelmed',
      'stressed',
      'stress',
      'pressure',
      'tense',
      'on edge',
      'restless',
    ];

    final angryPatterns = [
      'angry',
      'anger',
      'mad',
      'furious',
      'frustrated',
      'frustrating',
      'irritated',
      'annoyed',
      'upset',
      'bothered',
      'hate',
      'hating',
      'resent',
      'pissed off',
      'fed up',
      'had enough',
    ];

    // Count matches
    int urgentCount = 0;
    int depressionCount = 0;
    int happyCount = 0;
    int anxiousCount = 0;
    int angryCount = 0;

    for (final message in userMessages) {
      final lowerMessage = message.toLowerCase();

      // Check all patterns
      for (final pattern in urgentPatterns) {
        if (lowerMessage.contains(pattern)) {
          urgentCount++;
          print('🚨 Urgent: "$pattern" in "$message"');
        }
      }

      for (final pattern in depressionPatterns) {
        if (lowerMessage.contains(pattern)) {
          depressionCount++;
          print('😔 Depression: "$pattern" in "$message"');
        }
      }

      for (final pattern in happyPatterns) {
        if (lowerMessage.contains(pattern)) {
          happyCount++;
          print('😊 Happy: "$pattern" in "$message"');
        }
      }

      for (final pattern in anxiousPatterns) {
        if (lowerMessage.contains(pattern)) {
          anxiousCount++;
          print('😰 Anxious: "$pattern" in "$message"');
        }
      }

      for (final pattern in angryPatterns) {
        if (lowerMessage.contains(pattern)) {
          angryCount++;
          print('😠 Angry: "$pattern" in "$message"');
        }
      }
    }

    print(
      'Emotion counts - Urgent: $urgentCount, Depression: $depressionCount, Happy: $happyCount, Anxious: $anxiousCount, Angry: $angryCount',
    );

    // Set emotional states (lower thresholds for testing)
    if (urgentCount > 0) {
      _isUrgentConcern = true;
      _detectedMoods = ['Urgent Support Needed'];
      print('🚨 URGENT CONCERN DETECTED');
    } else if (depressionCount > 0) {
      _isDepressed = true;
      _detectedMoods.add('Depressed');
      print('😔 DEPRESSION DETECTED');
    } else if (happyCount > 0) {
      _isHappy = true;
      _detectedMoods.add('Happy');
      print('😊 HAPPINESS DETECTED');
    }

    if (anxiousCount > 0) {
      _isAnxious = true;
      _detectedMoods.add('Anxious');
      print('😰 ANXIETY DETECTED');
    }

    if (angryCount > 0) {
      _isAngry = true;
      _detectedMoods.add('Angry');
      print('😠 ANGER DETECTED');
    }

    // If nothing detected, add Neutral
    if (_detectedMoods.isEmpty) {
      _detectedMoods.add('Neutral');
    }

    // Limit to 3 moods
    if (_detectedMoods.length > 3) {
      _detectedMoods = _detectedMoods.take(3).toList();
    }
  }

  List<String> _analyzeConversationMoodsAdvanced(
    List<Map<String, dynamic>> messages,
  ) {
    final userMessages = messages
        .where((msg) => msg['isUser'] == true)
        .map((msg) => msg['message'].toString().toLowerCase())
        .toList();

    if (userMessages.isEmpty) {
      return ['Neutral'];
    }

    // Simple keyword detection
    final emotionKeywords = {
      'Happy': [
        'happy',
        'good',
        'great',
        'joy',
        'glad',
        'thankful',
        'grateful',
      ],
      'Sad': ['sad', 'unhappy', 'miserable', 'depressed', 'down'],
      'Anxious': ['anxious', 'worried', 'nervous', 'scared', 'afraid'],
      'Angry': ['angry', 'mad', 'furious', 'frustrated', 'irritated'],
      'Hopeless': [
        'hopeless',
        'worthless',
        'useless',
        'empty',
        'nothing matters',
      ],
    };

    final emotionScores = <String, int>{};

    for (final message in userMessages) {
      for (final emotion in emotionKeywords.keys) {
        for (final keyword in emotionKeywords[emotion]!) {
          if (message.contains(keyword)) {
            emotionScores[emotion] = (emotionScores[emotion] ?? 0) + 1;
          }
        }
      }
    }

    // Sort by score
    final sortedEmotions = emotionScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedEmotions.isEmpty) {
      return ['Neutral'];
    }

    return sortedEmotions.take(3).map((e) => e.key).toList();
  }

  void _generateDynamicContent() {
    final userMessages = _conversationMessages
        .where((msg) => msg['isUser'] == true)
        .map((msg) => msg['message'].toString())
        .toList();

    if (userMessages.isEmpty) {
      _setNeutralTheme();
      return;
    }

    final lastMessage = userMessages.last;
    _conversationPreview = lastMessage.length > 60
        ? '"${lastMessage.substring(0, 60)}..."'
        : '"$lastMessage"';

    // Set theme based on detected emotion
    if (_isUrgentConcern) {
      _setUrgentConcernTheme(lastMessage);
    } else if (_isDepressed) {
      _setDepressedTheme(lastMessage);
    } else if (_isHappy) {
      _setHappyTheme(lastMessage);
    } else if (_isAnxious) {
      _setAnxiousTheme(lastMessage);
    } else if (_isAngry) {
      _setAngryTheme(lastMessage);
    } else {
      _setNeutralTheme();
    }
  }

  void _setUrgentConcernTheme(String lastMessage) {
    _themeColor = Colors.red.shade800;
    _themeGradient = LinearGradient(
      colors: [Colors.red.shade900, Colors.red.shade700],
    );
    _themeIcon = Iconsax.warning_2;
    _dynamicQuestion =
        'I\'m deeply concerned about you. How are you holding on right now?';
    _dynamicSubtitle =
        'Your life is precious. What small hope can we hold onto together in this moment?';
    _conversationContext =
        'You shared feelings of deep despair. I want you to know that you matter, and there are people who care about you deeply.';
    _relevantMoodOptions = [
      MoodOption(emoji: '💔', label: 'In Crisis', color: Colors.red.shade800),
      MoodOption(emoji: '😰', label: 'Overwhelmed', color: Colors.orange),
      MoodOption(emoji: '🤗', label: 'Need Support', color: Colors.pink),
      MoodOption(
        emoji: '🕯️',
        label: 'Holding On',
        color: Colors.yellow.shade700,
      ),
      MoodOption(emoji: '🙏', label: 'Seeking Hope', color: Colors.green),
      MoodOption(emoji: '💙', label: 'Not Alone', color: Colors.blue),
    ];
    _intensityQuestion = 'How overwhelming are these feelings right now?';
    _reflectionPrompt =
        'What part of you wants to keep going? You are not alone in this.';
  }

  void _setDepressedTheme(String lastMessage) {
    _themeColor = Colors.blue.shade800;
    _themeGradient = LinearGradient(
      colors: [Colors.blue.shade900, Colors.blue.shade700],
    );
    _themeIcon = Iconsax.heart_slash;
    _dynamicQuestion =
        'I can hear the heavy weight you\'re carrying. How is your heart holding up today?';
    _dynamicSubtitle =
        'Depression can feel incredibly lonely. What small comfort would help right now?';
    _conversationContext =
        'You shared feelings of deep sadness. Taking things one moment at a time is enough. Your feelings are valid.';
    _relevantMoodOptions = [
      MoodOption(
        emoji: '😔',
        label: 'Heavy Heart',
        color: Colors.blue.shade800,
      ),
      MoodOption(emoji: '🌧️', label: 'Clouded', color: Colors.grey.shade600),
      MoodOption(emoji: '💔', label: 'Hurt', color: Colors.purple),
      MoodOption(emoji: '🤗', label: 'Need Comfort', color: Colors.pink),
      MoodOption(
        emoji: '🕯️',
        label: 'Seeking Light',
        color: Colors.yellow.shade600,
      ),
      MoodOption(emoji: '🙏', label: 'Hopeful', color: Colors.green),
    ];
    _intensityQuestion = 'How heavy does this sadness feel today?';
    _reflectionPrompt = 'What small thing would feel comforting right now?';
  }

  void _setHappyTheme(String lastMessage) {
    _themeColor = Colors.green.shade600;
    _themeGradient = LinearGradient(
      colors: [Colors.green.shade700, Colors.green.shade500],
    );
    _themeIcon = Iconsax.like_1;
    _dynamicQuestion =
        'That\'s wonderful to hear! How is this happiness glowing within you?';
    _dynamicSubtitle =
        'Celebrating your positive moments! What feels especially good right now?';
    _conversationContext =
        'You shared such uplifting energy! Savoring these positive feelings helps them grow even stronger.';
    _relevantMoodOptions = [
      MoodOption(emoji: '😊', label: 'Happy', color: Colors.green),
      MoodOption(emoji: '🌟', label: 'Shining', color: Colors.yellow.shade700),
      MoodOption(emoji: '🙏', label: 'Grateful', color: Colors.amber),
      MoodOption(emoji: '💝', label: 'Loved', color: Colors.pink),
      MoodOption(emoji: '💪', label: 'Empowered', color: Colors.lightGreen),
      MoodOption(emoji: '😌', label: 'Content', color: Colors.teal),
    ];
    _intensityQuestion = 'How brightly is this joy shining?';
    _reflectionPrompt = 'What makes this moment so special for you?';
  }

  void _setAnxiousTheme(String lastMessage) {
    _themeColor = Colors.orange.shade600;
    _themeGradient = LinearGradient(
      colors: [Colors.orange.shade700, Colors.orange.shade500],
    );
    _themeIcon = Iconsax.heart_tick;
    _dynamicQuestion =
        'I sense some anxiety in our conversation. How is that feeling sitting with you?';
    _dynamicSubtitle =
        'Anxiety can be overwhelming. What would help you feel more grounded right now?';
    _conversationContext =
        'You shared feelings of worry or anxiety. Remember to breathe deeply - you\'re safe in this moment.';
    _relevantMoodOptions = [
      MoodOption(emoji: '😰', label: 'Worried', color: Colors.orange),
      MoodOption(
        emoji: '🌪️',
        label: 'Overwhelmed',
        color: Colors.red.shade600,
      ),
      MoodOption(emoji: '💫', label: 'Nervous', color: Colors.yellow.shade700),
      MoodOption(emoji: '🤗', label: 'Need Reassurance', color: Colors.pink),
      MoodOption(emoji: '🧘', label: 'Seeking Calm', color: Colors.teal),
      MoodOption(emoji: '🛡️', label: 'Protected', color: Colors.blue),
    ];
    _intensityQuestion = 'How intense is this anxiety feeling?';
    _reflectionPrompt = 'What would help you feel more safe and secure?';
  }

  void _setAngryTheme(String lastMessage) {
    _themeColor = Colors.red.shade600;
    _themeGradient = LinearGradient(
      colors: [Colors.red.shade700, Colors.red.shade500],
    );
    _themeIcon = Iconsax.flash;
    _dynamicQuestion =
        'I hear the frustration in your words. How is that anger sitting with you?';
    _dynamicSubtitle =
        'Anger is a valid emotion. What would help channel this energy constructively?';
    _conversationContext =
        'You shared feelings of anger or frustration. It\'s okay to feel this way - let\'s explore what\'s beneath it.';
    _relevantMoodOptions = [
      MoodOption(emoji: '😠', label: 'Frustrated', color: Colors.red),
      MoodOption(emoji: '💢', label: 'Irritated', color: Colors.orange),
      MoodOption(emoji: '⚡', label: 'Energized', color: Colors.yellow.shade700),
      MoodOption(emoji: '🛡️', label: 'Protective', color: Colors.blue),
      MoodOption(emoji: '🌋', label: 'Volcanic', color: Colors.red.shade800),
      MoodOption(emoji: '🕊️', label: 'Seeking Peace', color: Colors.green),
    ];
    _intensityQuestion = 'How strong is this anger feeling?';
    _reflectionPrompt = 'What do you need to feel heard and understood?';
  }

  void _setNeutralTheme() {
    _themeColor = AppTheme.primaryRed;
    _themeGradient = AppTheme.primaryGradient;
    _themeIcon = Iconsax.message_question;
    _dynamicQuestion = 'How did this conversation resonate with you?';
    _dynamicSubtitle =
        'Select the emotion that best describes your current state';
    _conversationContext =
        'Reflecting on our conversation helps understand your emotional journey';
    _relevantMoodOptions = _allMoodOptions;
    _intensityQuestion = 'How strong is this feeling?';
    _reflectionPrompt = 'Any thoughts about this feeling?';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,

      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: SafeArea(
          child: _showMoodQuestion
              ? _buildMoodQuestion()
              : _buildAnalysisScreen(),
        ),
      ),
    );
  }

  Widget _buildAnalysisScreen() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: _themeGradient,
              shape: BoxShape.circle,
            ),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Icon(
                  _themeIcon,
                  color: Colors.white,
                  size: 50 + (_animation.value * 10),
                );
              },
            ),
          ),
          SizedBox(height: 40),
          Text(
            _isUrgentConcern
                ? '🚨 Your Well-being Matters'
                : _isDepressed
                ? '💙 Understanding Your Feelings'
                : _isHappy
                ? '🌟 Celebrating Your Joy'
                : _isAnxious
                ? '😰 Recognizing Your Anxiety'
                : _isAngry
                ? '😠 Acknowledging Your Anger'
                : 'Understanding Your Conversation',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: _isUrgentConcern
                  ? Colors.red.shade800
                  : _isDepressed
                  ? Colors.blue.shade800
                  : _isHappy
                  ? Colors.green.shade600
                  : _isAnxious
                  ? Colors.orange.shade600
                  : _isAngry
                  ? Colors.red.shade600
                  : AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            _isUrgentConcern
                ? 'We\'re here with you. Creating supportive questions with care and concern...'
                : _isDepressed
                ? 'We hear the weight you\'re carrying. Preparing gentle reflection questions...'
                : _isHappy
                ? 'We\'re celebrating your positive energy! Creating uplifting questions...'
                : _isAnxious
                ? 'We recognize the anxiety. Preparing calming, grounding questions...'
                : _isAngry
                ? 'We acknowledge your frustration. Preparing constructive reflection questions...'
                : 'We\'re reading your messages to create personalized reflection questions',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 40),
          if (!_analysisComplete) _buildLoadingIndicator(),
          if (_analysisComplete) _buildDetectedMoodsPreview(),
          SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            backgroundColor: AppTheme.lightRed,
            color: _themeColor,
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(height: 16),
        Text(
          _isUrgentConcern
              ? 'Reading with deep care and concern...'
              : _isDepressed
              ? 'Reading with gentle understanding...'
              : _isHappy
              ? 'Reading your joyful energy...'
              : _isAnxious
              ? 'Reading with calm attention...'
              : _isAngry
              ? 'Reading with open understanding...'
              : 'Reading your emotional landscape...',
          style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildDetectedMoodsPreview() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _isUrgentConcern
                ? 'We recognize you need immediate support:'
                : _isDepressed
                ? 'We hear your emotional pain:'
                : _isHappy
                ? 'We celebrate your positive energy:'
                : _isAnxious
                ? 'We recognize your anxious feelings:'
                : _isAngry
                ? 'We acknowledge your anger:'
                : 'We detected these emotional themes:',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _detectedMoods.map((mood) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  mood,
                  style: GoogleFonts.inter(
                    color: _themeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedMood != null) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _themeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _themeColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, color: _themeColor, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Auto-selected: $_selectedMood',
                    style: GoogleFonts.inter(
                      color: _themeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 8),
          Text(
            _isUrgentConcern
                ? 'Creating supportive questions with deep care...'
                : _isDepressed
                ? 'Creating gentle, understanding questions...'
                : _isHappy
                ? 'Creating celebratory questions...'
                : _isAnxious
                ? 'Creating calming, grounding questions...'
                : _isAngry
                ? 'Creating constructive reflection questions...'
                : 'Creating personalized questions...',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodQuestion() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isUrgentConcern
                ? 'Your Well-being Matters'
                : _isDepressed
                ? 'Gentle Reflection'
                : _isHappy
                ? 'Celebrating Your Joy'
                : _isAnxious
                ? 'Calm Reflection'
                : _isAngry
                ? 'Constructive Reflection'
                : 'Emotional Reflection',
            style: GoogleFonts.poppins(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 20),
          _buildConversationContextCard(),
          SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: _themeGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(_themeIcon, color: Colors.white, size: 40),
                SizedBox(height: 12),
                Text(
                  _dynamicQuestion,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  _conversationContext,
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(height: 30),
          Text(
            'What emotion resonates most?',
            style: GoogleFonts.inter(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _dynamicSubtitle,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),
          _buildMoodGrid(),
          SizedBox(height: 30),
          Text(
            _intensityQuestion,
            style: GoogleFonts.inter(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Rate from mild to intense',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),
          _buildIntensitySlider(),
          SizedBox(height: 30),
          Text(
            _reflectionPrompt,
            style: GoogleFonts.inter(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Share what comes to mind',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),
          _buildNoteInput(),
          SizedBox(height: 30),
          _buildSubmitButton(),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildConversationContextCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _themeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _themeColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_themeIcon, size: 18, color: _themeColor),
              SizedBox(width: 8),
              Text(
                _isUrgentConcern
                    ? 'Your Safety Matters'
                    : _isDepressed
                    ? 'Gentle Support'
                    : _isHappy
                    ? 'Celebrating Together'
                    : _isAnxious
                    ? 'Calm Support'
                    : _isAngry
                    ? 'Constructive Support'
                    : 'Personalized Reflection',
                style: GoogleFonts.inter(
                  color: _themeColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            _conversationPreview.isNotEmpty
                ? _conversationPreview
                : 'Conversation preview',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (_detectedMoods.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              'Emotional themes: ${_detectedMoods.join(', ')}',
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          if (_selectedMood != null) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _themeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 12, color: _themeColor),
                  SizedBox(width: 4),
                  Text(
                    'Suggested: $_selectedMood',
                    style: GoogleFonts.inter(
                      color: _themeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMoodGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: _relevantMoodOptions.length,
      itemBuilder: (context, index) {
        final mood = _relevantMoodOptions[index];
        final isSelected = _selectedMood == mood.label;
        return GestureDetector(
          onTap: () => setState(() => _selectedMood = mood.label),
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? mood.color.withOpacity(0.2)
                  : AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? mood.color : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(mood.emoji, style: TextStyle(fontSize: 24)),
                SizedBox(height: 8),
                Text(
                  mood.label,
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIntensitySlider() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Intensity Level',
                style: GoogleFonts.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_intensity/10',
                  style: GoogleFonts.inter(
                    color: _themeColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Slider(
            value: _intensity.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: _themeColor,
            inactiveColor: _themeColor.withOpacity(0.3),
            onChanged: (value) => setState(() => _intensity = value.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mild',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                'Moderate',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                'Intense',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoteInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _themeColor),
      ),
      child: TextField(
        controller: _noteController,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: _isUrgentConcern
              ? 'You are not alone. Share what\'s on your heart...'
              : _isDepressed
              ? 'Share what feels heavy or what might help...'
              : _isHappy
              ? 'Share what makes this moment special...'
              : _isAnxious
              ? 'Share what\'s making you feel anxious and what might help...'
              : _isAngry
              ? 'Share what\'s causing this feeling and what you need...'
              : 'Share what comes to mind...',
          hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
        style: GoogleFonts.inter(color: AppTheme.textPrimary),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isEnabled = _selectedMood != null;
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: isEnabled
            ? _themeGradient
            : LinearGradient(colors: [Colors.grey, Colors.grey]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: _themeColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isEnabled ? _submitMood : null,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.track_changes_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  _isUrgentConcern
                      ? 'Save with Care'
                      : _isDepressed
                      ? 'Save Reflection'
                      : _isHappy
                      ? 'Celebrate This Moment'
                      : _isAnxious
                      ? 'Save Calm Reflection'
                      : _isAngry
                      ? 'Save Constructive Reflection'
                      : 'Save Reflection',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitMood() {
    if (_selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select how you\'re feeling'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      return;
    }

    final appDataProvider = Provider.of<AppDataProvider>(
      context,
      listen: false,
    );
    final moodEntry = MoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      mood: _selectedMood!,
      intensity: _intensity,
      note: _noteController.text.trim(),
      relatedTo: widget.chatSessionId,
      tags: _detectedMoods,
    );

    appDataProvider.addMoodEntry(moodEntry, context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isUrgentConcern
              ? 'Your reflection is saved. Remember, you matter and there is hope.'
              : _isDepressed
              ? 'Your reflection is saved. Taking things one moment at a time is enough.'
              : _isHappy
              ? 'Your joyful moment is saved! Celebrate these positive feelings.'
              : _isAnxious
              ? 'Your reflection is saved. Remember to breathe deeply and take one moment at a time.'
              : _isAngry
              ? 'Your reflection is saved. Your feelings are valid and important.'
              : 'Your reflection has been saved!',
        ),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class MoodOption {
  final String emoji;
  final String label;
  final Color color;
  MoodOption({required this.emoji, required this.label, required this.color});
}
