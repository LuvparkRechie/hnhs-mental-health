import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:hnhsmind_care/api_key/api_key.dart';
import 'package:hnhsmind_care/app_theme.dart';

class AdminMoodTrackerScreen extends StatefulWidget {
  const AdminMoodTrackerScreen({super.key});

  @override
  State<AdminMoodTrackerScreen> createState() => _AdminMoodTrackerScreenState();
}

class MoodEntry {
  final String id;
  final String mood;
  final int intensity;
  final String note;
  final String relatedTo;
  final String tags;
  final DateTime createdDate;
  final String userName;
  final String? userId;

  MoodEntry({
    required this.id,
    required this.mood,
    required this.intensity,
    required this.note,
    required this.relatedTo,
    required this.tags,
    required this.createdDate,
    required this.userName,
    this.userId,
  });
}

class _AdminMoodTrackerScreenState extends State<AdminMoodTrackerScreen> {
  Map<String, List<MoodEntry>> _groupedMoods = {};
  bool _isLoading = true;
  String _errorMessage = '';
  String? _selectedUser;

  @override
  void initState() {
    super.initState();
    getUsersMood();
  }

  void getUsersMood() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final api = ApiPhp(tableName: 'mood_entries');

      final joinConfig = {
        'join': 'INNER JOIN users u ON u.id = mood_entries.user_id',
        'columns': 'mood_entries.*, u.username AS user_name',
        'where': '1=1',
        'orderBy': 'mood_entries.created_date DESC',
        'limit': 100,
      };

      final response = await api.selectWithJoin(joinConfig);

      Map<String, List<MoodEntry>> groupedByUser = {};

      if (response['data'] is List) {
        List moodData = response['data'];

        for (var entry in moodData) {
          String userName = entry['user_name'] ?? 'Unknown';

          MoodEntry moodEntry = MoodEntry(
            id: entry['id'].toString(),
            mood: entry['mood'] ?? '',
            intensity: int.tryParse(entry['intensity'].toString()) ?? 0,
            note: entry['note'] ?? '',
            relatedTo: entry['related_to'] ?? '',
            tags: entry['tags'] ?? '',
            createdDate: DateTime.parse(entry['created_date']),
            userName: userName,
            userId: entry['user_id']?.toString(),
          );

          if (!groupedByUser.containsKey(userName)) {
            groupedByUser[userName] = [];
          }
          groupedByUser[userName]!.add(moodEntry);
        }
      }

      setState(() {
        _groupedMoods = groupedByUser;
        _isLoading = false;
      });

      print("Found ${groupedByUser.length} users with mood entries");
    } catch (e) {
      print("Error: $e");
      setState(() {
        _errorMessage = 'Failed to load mood data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,

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
                    onPressed: getUsersMood,
                    child: Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRed,
                    ),
                  ),
                ],
              ),
            )
          : _selectedUser == null
          ? _buildUserList()
          : _buildUserMoodList(_selectedUser!),
    );
  }

  Widget _buildUserList() {
    final users = _groupedMoods.keys.toList();

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.emoji_sad, size: 60, color: AppTheme.lightRed),
            SizedBox(height: 16),
            Text(
              'No mood entries found',
              style: GoogleFonts.poppins(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Users will appear here once they log their moods',
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Icon(Iconsax.people, color: AppTheme.primaryRed, size: 20),
              SizedBox(width: 8),
              Text(
                'Users with Mood Entries',
                style: GoogleFonts.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${users.length} users',
                  style: GoogleFonts.inter(
                    color: AppTheme.primaryRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // User List
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userName = users[index];
              final userMoods = _groupedMoods[userName]!;
              final latestMood = userMoods.first;

              return _buildUserCard(userName, userMoods, latestMood);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(
    String userName,
    List<MoodEntry> userMoods,
    MoodEntry latestMood,
  ) {
    final totalEntries = userMoods.length;
    final today = DateTime.now();
    final todayEntries = userMoods.where((mood) {
      return mood.createdDate.year == today.year &&
          mood.createdDate.month == today.month &&
          mood.createdDate.day == today.day;
    }).length;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedUser = userName;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // User Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getUserColor(userName),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    userName.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: GoogleFonts.inter(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),

                    // Latest Mood
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getMoodColor(
                              latestMood.mood,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _getMoodColor(
                                latestMood.mood,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                latestMood.mood,
                                style: GoogleFonts.inter(
                                  color: _getMoodColor(latestMood.mood),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 4),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: _getMoodColor(
                                    latestMood.mood,
                                  ).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${latestMood.intensity}/10',
                                  style: GoogleFonts.inter(
                                    color: _getMoodColor(latestMood.mood),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          DateFormat('h:mm a').format(latestMood.createdDate),
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4),
              Icon(
                Iconsax.arrow_right_3,
                size: 16,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserMoodList(String userName) {
    final userMoods = _groupedMoods[userName] ?? [];

    return Column(
      children: [
        // Back Header
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              IconButton(
                icon: Icon(Iconsax.arrow_left, color: AppTheme.primaryRed),
                onPressed: () {
                  setState(() {
                    _selectedUser = null;
                  });
                },
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getUserColor(userName),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    userName.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: GoogleFonts.inter(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${userMoods.length} mood entries',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Mood Entries List
        Expanded(
          child: userMoods.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.emoji_sad,
                        size: 50,
                        color: AppTheme.lightRed,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No mood entries for $userName',
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: userMoods.length,
                  itemBuilder: (context, index) {
                    return _buildMoodEntryCard(userMoods[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMoodFilterChip(String label, bool isSelected) {
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          color: isSelected ? Colors.white : AppTheme.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {},
      backgroundColor: AppTheme.backgroundColor,
      selectedColor: AppTheme.primaryRed,
      side: BorderSide(color: AppTheme.lightRed),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    );
  }

  Widget _buildMoodEntryCard(MoodEntry entry) {
    final isUrgent = entry.tags.contains('Urgent');
    final isChat = entry.relatedTo.contains('chat');
    final moodColor = _getMoodColor(entry.mood);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Mood Emoji and Name
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.mood,
                            style: GoogleFonts.inter(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            DateFormat(
                              'MMM dd, yyyy • h:mm a',
                            ).format(entry.createdDate),
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Intensity
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
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

              SizedBox(height: 12),

              // Tags and Context
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (isUrgent)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Iconsax.warning_2, size: 10, color: Colors.red),
                          SizedBox(width: 4),
                          Text(
                            'Urgent',
                            style: GoogleFonts.inter(
                              color: Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (isChat)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Iconsax.message, size: 10, color: Colors.blue),
                          SizedBox(width: 4),
                          Text(
                            'Chat Session',
                            style: GoogleFonts.inter(
                              color: Colors.blue,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (entry.relatedTo.isNotEmpty && !isChat)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.lightRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.lightRed),
                      ),
                      child: Text(
                        entry.relatedTo,
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),

              // Note
              if (entry.note.isNotEmpty) ...[
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    entry.note,
                    style: GoogleFonts.inter(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods
  Color _getUserColor(String userName) {
    final hash = userName.codeUnits.fold(0, (int acc, int unit) => acc + unit);
    final colors = [
      AppTheme.primaryRed,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
    ];
    return colors[hash % colors.length];
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'tired':
        return '😴';
      case 'anxious':
        return '😰';
      case 'angry':
        return '😠';
      case 'calm':
        return '😌';
      case 'neutral':
        return '😐';
      case 'excited':
        return '🤩';
      case 'need support':
        return '🆘';
      case 'seeking hope':
        return '🌟';
      default:
        return '😊';
    }
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return Colors.green;
      case 'sad':
        return Colors.blue;
      case 'tired':
        return Colors.purple;
      case 'anxious':
        return Colors.orange;
      case 'angry':
        return Colors.red;
      case 'calm':
        return Colors.teal;
      case 'neutral':
        return Colors.grey;
      case 'excited':
        return Colors.yellow[700]!;
      case 'need support':
        return Colors.red[800]!;
      case 'seeking hope':
        return Colors.amber;
      default:
        return AppTheme.primaryRed;
    }
  }
}
