import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../api_key/api_key.dart';
import '../../app_theme.dart';
import '../../provider/auth_provider.dart';
import 'package:provider/provider.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  _MoodTrackerScreenState createState() => _MoodTrackerScreenState();
}

class MoodEntry {
  final String id;
  final DateTime date;
  final String mood;
  final int intensity;
  final String note;
  final String? relatedTo;
  final String? tags;

  MoodEntry({
    required this.id,
    required this.date,
    required this.mood,
    required this.intensity,
    required this.note,
    this.relatedTo,
    this.tags,
  });
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  List<MoodEntry> _moodEntries = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchMoods();
  }

  Future<void> _fetchMoods() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;

      if (currentUser == null) {
        setState(() {
          _errorMessage = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      final api = ApiPhp(
        tableName: 'mood_entries',
        whereClause: {'user_id': currentUser.id},
        orderBy: 'created_date DESC',
      );

      final response = await api.select();

      List<Map<String, dynamic>> moodData = [];
      final data = response['data'];
      if (data is List) {
        moodData = data.cast<Map<String, dynamic>>();
      }

      // Convert to MoodEntry objects
      final entries = moodData.map((moodData) {
        return MoodEntry(
          id: moodData['id'].toString(),
          date: DateTime.parse(moodData['created_date']),
          mood: moodData['mood'] ?? 'Unknown',
          intensity: moodData['intensity'] is int
              ? moodData['intensity']
              : int.tryParse(moodData['intensity'].toString()) ?? 5,
          note: moodData['note'] ?? '',
          relatedTo: moodData['related_to'],
          tags: moodData['tags'] ?? '',
        );
      }).toList();

      setState(() {
        _moodEntries = entries;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching moods: $e');
      setState(() {
        _errorMessage = 'Failed to load moods: $e';
        _isLoading = false;
      });
    }
  }

  // Get today's moods only
  List<MoodEntry> get _todaysMoods {
    final now = DateTime.now();
    return _moodEntries.where((entry) {
      return entry.date.year == now.year &&
          entry.date.month == now.month &&
          entry.date.day == now.day;
    }).toList();
  }

  // Get chat-related moods
  List<MoodEntry> get _chatMoods {
    return _moodEntries.where((entry) {
      final relatedTo = entry.relatedTo ?? '';
      return relatedTo.contains('chat') || relatedTo.contains('Chat');
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left, color: AppTheme.primaryRed),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mood Tracker',
          style: GoogleFonts.poppins(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Iconsax.refresh, color: AppTheme.primaryRed),
            onPressed: _fetchMoods,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryRed))
          : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.warning_2, color: Colors.orange, size: 50),
                  SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchMoods,
                    child: Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRed,
                    ),
                  ),
                ],
              ),
            )
          : _todaysMoods.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    title: "Today's Moods",
                    count: _todaysMoods.length,
                    entries: _todaysMoods,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required int count,
    required List<MoodEntry> entries,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.lightRed.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count entries',
                  style: GoogleFonts.inter(
                    color: AppTheme.primaryRed,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        if (entries.isEmpty)
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'No $title found',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          )
        else
          Column(
            children: entries.map((entry) => _buildMoodCard(entry)).toList(),
          ),
        SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMoodCard(MoodEntry entry) {
    final isUrgent = (entry.tags ?? '').contains('Urgent');
    final isToday = _todaysMoods.contains(entry);
    final isChat = _chatMoods.contains(entry);

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isUrgent
              ? Colors.red
              : isToday
              ? AppTheme.primaryRed.withOpacity(0.3)
              : Colors.transparent,
          width: isUrgent ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Mood Emoji/Icon

          // Mood Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.mood,
                      style: GoogleFonts.inter(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    if (isUrgent)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'URGENT',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (isChat)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Iconsax.message,
                          size: 10,
                          color: Colors.blue,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy • HH:mm').format(entry.date),
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                if (entry.note.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    entry.note,
                    style: GoogleFonts.inter(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (entry.relatedTo != null && entry.relatedTo!.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    'Related to: ${entry.relatedTo}',
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Intensity
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${entry.intensity}/10',
              style: GoogleFonts.inter(
                color: AppTheme.primaryRed,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Emoji Container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryRed.withOpacity(0.1),
                  AppTheme.lightRed.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: AppTheme.primaryRed.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                // Background pattern
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.05,
                    child: Icon(
                      Iconsax.emoji_happy,
                      size: 80,
                      color: AppTheme.primaryRed,
                    ),
                  ),
                ),
                // Main emoji
                Center(
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        colors: [AppTheme.primaryRed, Color(0xFFFF6B8B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds);
                    },
                    child: Icon(
                      Iconsax.emoji_sad,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 32),

          // Main Title
          Text(
            'No Mood Entries Today',
            style: GoogleFonts.poppins(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),

          // Description
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Your mood journal is empty for today. Take a moment to check in with yourself.',
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 40),

          // Stats Container
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 20),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Why Track Moods
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(
                          Iconsax.chart,
                          size: 20,
                          color: AppTheme.primaryRed,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Why Track Your Mood?',
                            style: GoogleFonts.inter(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Helps identify patterns and improve emotional awareness over time.',
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Divider
                Container(height: 1, color: AppTheme.lightRed.withOpacity(0.3)),
                SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: _fetchMoods,
                  icon: Icon(Iconsax.refresh, size: 16),
                  label: Text(
                    'Refresh',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.backgroundColor,
                    foregroundColor: AppTheme.textPrimary,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: AppTheme.lightRed.withOpacity(0.5),
                      ),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 30),

          // Tips Section
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryRed.withOpacity(0.03),
                  AppTheme.lightRed.withOpacity(0.01),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryRed.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Iconsax.lamp_charge,
                      size: 18,
                      color: AppTheme.primaryRed,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Quick Tip',
                      style: GoogleFonts.inter(
                        color: AppTheme.primaryRed,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  'Try checking in at different times of the day to get a complete picture of your emotional state.',
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),

          // Last Updated
          Padding(
            padding: EdgeInsets.only(top: 30, bottom: 20),
            child: Text(
              'Last updated: ${DateFormat('h:mm a').format(DateTime.now())}',
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary.withOpacity(0.6),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
