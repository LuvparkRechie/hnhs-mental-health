// lib/pages/client_screen/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:hnhsmind_care/database_provider/database_provider.dart';
import 'package:hnhsmind_care/pages/mood_question.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_theme.dart';
import '../../provider/chat_provider.dart';
import 'models/conversation_models.dart';
import '../../provider/auth_provider.dart'; // Add this import

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showFinishButton = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      _startNewChatSession();
    });
  }

  void _startNewChatSession() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    final userId = currentUser?.id.toString();
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final appDataProvider = Provider.of<AppDataProvider>(
      context,
      listen: false,
    );
    chatProvider.clearConversations(userId!);
    appDataProvider.startChatSession(); // Remove sessionId parameter
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final appDataProvider = Provider.of<AppDataProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;

      chatProvider.sendMessage(message, currentUser!.id.toString());

      appDataProvider.incrementMessageCount();

      _messageController.clear();
      _scrollToBottom();

      if (!_showFinishButton) {
        setState(() {
          _showFinishButton = true;
        });
      }

      Future.delayed(Duration(seconds: 2), () {
        _scrollToBottom();
      });
    }
  }

  void _finishConversation() {
    final appDataProvider = Provider.of<AppDataProvider>(
      context,
      listen: false,
    );
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    final userId = currentUser?.id.toString();

    if (appDataProvider.currentSessionId != null &&
        chatProvider.conversations.isNotEmpty) {
      Navigator.of(context).pop();
      // Get the chat provider
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      // Navigate to MoodQuestionScreen WITH conversation data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MoodQuestionScreen(
            chatSessionId:
                'current_chat_${DateTime.now().millisecondsSinceEpoch}',
            conversationData: chatProvider.conversations,
          ),
        ),
      );
    } else {
      Navigator.of(context).pop();
      chatProvider.clearConversations(userId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;

    return Scaffold(
      body: Consumer2<ChatProvider, AppDataProvider>(
        // Use Consumer2 for multiple providers
        builder: (context, chatProvider, appDataProvider, child) {
          return SafeArea(
            child: Column(
              children: [
                // Enhanced Header with User Info
                Container(
                  padding: EdgeInsets.fromLTRB(10, 20, 20, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.psychology_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HNHS AI',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              currentUser?.username != null
                                  ? 'Supporting ${currentUser!.username}'
                                  : 'Here to support you 24/7',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            // Show user name if available
                            if (currentUser?.username != null)
                              Container(
                                margin: EdgeInsets.only(top: 2),
                                child: Text(
                                  '${_getUserGreeting()}, ${currentUser!.username}!',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: AppTheme.primaryRed,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextButton.icon(
                          icon: Icon(
                            Iconsax.tick_circle,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Finish',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          onPressed: _finishConversation,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Loading Indicator
                if (chatProvider.isLoading)
                  LinearProgressIndicator(
                    backgroundColor: AppTheme.backgroundColor,
                    color: AppTheme.primaryRed,
                    minHeight: 2,
                  ),

                // Error Message
                if (chatProvider.error != null)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    color: AppTheme.lightRed,
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppTheme.dangerColor,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            chatProvider.error!,
                            style: GoogleFonts.inter(
                              color: AppTheme.dangerColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 16),
                          onPressed: () {
                            chatProvider.clearError();
                          },
                        ),
                      ],
                    ),
                  ),

                // Chat Messages
                Expanded(
                  child: Container(
                    color: AppTheme.backgroundColor,
                    child: chatProvider.conversations.isEmpty
                        ? _buildEmptyState(currentUser)
                        : ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.all(16),
                            itemCount: chatProvider.conversations.length,
                            itemBuilder: (context, index) {
                              final message = chatProvider.conversations[index];
                              return _buildMessageBubble(message, currentUser);
                            },
                          ),
                  ),
                ),

                // Message Input
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      // User avatar in input area
                      if (currentUser != null)
                        Container(
                          width: 40,
                          height: 40,
                          margin: EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.lightRed,
                            shape: BoxShape.circle,
                            // Add profile picture if available in your user model
                            // image: currentUser.profilePicture != null
                            //   ? DecorationImage(
                            //       image: NetworkImage(currentUser.profilePicture!),
                            //       fit: BoxFit.cover,
                            //     )
                            //   : null,
                          ),
                          child: Icon(
                            Icons.person,
                            color: AppTheme.primaryRed,
                            size: 20,
                          ),
                        ),

                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          enabled: !chatProvider.isLoading,
                          decoration: InputDecoration(
                            hintText: chatProvider.isLoading
                                ? 'AI is thinking...'
                                : currentUser?.username != null
                                ? 'Message ${currentUser!.username}...'
                                : 'Type your message...',
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(color: AppTheme.lightRed),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(color: AppTheme.lightRed),
                            ),
                            hintStyle: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(color: AppTheme.lightRed),
                            ),
                            suffixIcon: Icon(
                              Icons.emoji_emotions_outlined,
                              color: AppTheme.primaryRed,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          gradient: chatProvider.isLoading
                              ? LinearGradient(
                                  colors: [Colors.grey, Colors.grey],
                                )
                              : AppTheme.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: chatProvider.isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Icon(Icons.send, color: Colors.white),
                          onPressed: chatProvider.isLoading
                              ? null
                              : _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(currentUser) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.psychology_outlined, size: 80, color: AppTheme.lightRed),
          SizedBox(height: 16),
          Text(
            currentUser?.username != null
                ? 'Welcome, ${currentUser.username}!'
                : 'Start a Conversation',
            style: GoogleFonts.poppins(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            currentUser?.username != null
                ? 'How can I support you today, ${currentUser.username}?'
                : 'Share your thoughts and feelings with\nMindCare AI',
            style: GoogleFonts.inter(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    final appDataProvider = Provider.of<AppDataProvider>(
      context,
      listen: false,
    );
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (appDataProvider.currentSessionId != null && // Fixed property name
        chatProvider.conversations.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Leave Conversation?',
            style: GoogleFonts.poppins(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'You have an ongoing conversation. Would you like to finish and reflect, or leave without saving?',
            style: GoogleFonts.inter(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back
              },
              child: Text(
                'Leave',
                style: GoogleFonts.inter(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _finishConversation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Finish & Reflect',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  Widget _buildMessageBubble(Conversation message, currentUser) {
    final isUser = message.isUser;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.psychology_outlined,
                color: Colors.white,
                size: 16,
              ),
            ),
          SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primaryRed : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: GoogleFonts.inter(
                      color: isUser ? Colors.white : AppTheme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  if (message.suicideRiskScore != null &&
                      message.suicideRiskScore! > 0.3)
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Colors.white.withOpacity(0.2)
                            : AppTheme.lightRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 12,
                            color: isUser ? Colors.white : AppTheme.primaryRed,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Support Mode',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isUser
                                  ? Colors.white
                                  : AppTheme.primaryRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isUser) SizedBox(width: 8),
          if (isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.lightRed,
                shape: BoxShape.circle,
                // Add profile picture if available
                // image: currentUser?.profilePicture != null
                //     ? DecorationImage(
                //         image: NetworkImage(currentUser!.profilePicture!),
                //         fit: BoxFit.cover,
                //       )
                //     : null,
              ),
              child: Icon(Icons.person, color: AppTheme.primaryRed, size: 16),
            ),
        ],
      ),
    );
  }

  String _getUserGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
