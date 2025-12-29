// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';

// import '../../app_theme.dart';
// import '../../provider/auth_provider.dart';
// import '../chat_screen.dart';

// class ConversationAnalysisScreen extends StatefulWidget {
//   final List<ChatMessage> conversation;
//   final List<RiskAlert> alerts;

//   const ConversationAnalysisScreen({
//     super.key,
//     required this.conversation,
//     required this.alerts,
//   });

//   @override
//   _ConversationAnalysisScreenState createState() =>
//       _ConversationAnalysisScreenState();
// }

// class _ConversationAnalysisScreenState
//     extends State<ConversationAnalysisScreen> {
//   final ConversationAnalyzer _analyzer = ConversationAnalyzer();
//   ConversationAnalysis? _analysis;
//   bool _isAnalyzing = true;
//   String? _error;

//   @override
//   void initState() {
//     super.initState();
//     _analyzeConversation();
//   }

//   Future<void> _analyzeConversation() async {
//     print("widget.conversation ${widget.conversation}");
//     try {
//       final analysis = await _analyzer.analyze(
//         conversation: widget.conversation,
//         alerts: widget.alerts,
//       );

//       setState(() {
//         _analysis = analysis;
//         _isAnalyzing = false;
//       });
//     } catch (e) {
//       setState(() {
//         _error = "Failed to analyze conversation: $e";
//         _isAnalyzing = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = Provider.of<AuthProvider>(context);
//     final user = authProvider.user;

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 1,
//         title: Text(
//           'Conversation Analysis',
//           style: GoogleFonts.poppins(
//             fontWeight: FontWeight.w600,
//             color: AppTheme.textPrimary,
//           ),
//         ),
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: AppTheme.primaryRed),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//         actions: [
//           if (_analysis != null && !_analysis!.isSafe)
//             IconButton(
//               onPressed: () => _showResourcesDialog(),
//               icon: Icon(Icons.help_outline, color: AppTheme.primaryRed),
//               tooltip: 'Support Resources',
//             ),
//         ],
//       ),
//       body: _buildContent(user),
//     );
//   }

//   Widget _buildContent(user) {
//     if (_isAnalyzing) {
//       return _buildLoadingView();
//     }

//     if (_error != null) {
//       return _buildErrorView();
//     }

//     if (_analysis == null) {
//       return _buildNoAnalysisView();
//     }

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header with user info
//           _buildHeader(user),
//           const SizedBox(height: 24),

//           // Overall Risk Assessment
//           _buildRiskCard(),
//           const SizedBox(height: 20),

//           // Emotional Analysis
//           _buildEmotionalAnalysis(),
//           const SizedBox(height: 20),

//           // Key Concerns
//           _buildKeyConcerns(),
//           const SizedBox(height: 20),

//           // Conversation Statistics
//           _buildStatistics(),
//           const SizedBox(height: 20),

//           // Follow-up Questions
//           _buildFollowUpQuestions(),
//           const SizedBox(height: 20),

//           // Recommendations
//           _buildRecommendations(),
//           const SizedBox(height: 20),

//           // Action Buttons
//           _buildActionButtons(),
//           const SizedBox(height: 40),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeader(user) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 60,
//             height: 60,
//             decoration: BoxDecoration(
//               gradient: AppTheme.primaryGradient,
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(
//               Icons.psychology_outlined,
//               color: Colors.white,
//               size: 28,
//             ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   user?.username != null
//                       ? 'Conversation with ${user.username}'
//                       : 'Conversation Analysis',
//                   style: GoogleFonts.poppins(
//                     fontWeight: FontWeight.w600,
//                     fontSize: 16,
//                     color: AppTheme.textPrimary,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Analyzed on ${_formatDate(DateTime.now())}',
//                   style: GoogleFonts.inter(
//                     fontSize: 13,
//                     color: AppTheme.textSecondary,
//                   ),
//                 ),
//                 Text(
//                   '${widget.conversation.length} messages • ${widget.alerts.length} alerts',
//                   style: GoogleFonts.inter(
//                     fontSize: 12,
//                     color: AppTheme.textSecondary,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRiskCard() {
//     final riskLevel = _analysis!.riskLevel;
//     Color riskColor;
//     IconData riskIcon;
//     String riskText;

//     switch (riskLevel) {
//       case RiskLevel.critical:
//         riskColor = Colors.red;
//         riskIcon = Icons.warning_amber_rounded;
//         riskText = 'CRITICAL';
//         break;
//       case RiskLevel.high:
//         riskColor = Colors.orange;
//         riskIcon = Icons.warning;
//         riskText = 'HIGH';
//         break;
//       case RiskLevel.medium:
//         riskColor = Colors.yellow[700]!;
//         riskIcon = Icons.info_outline;
//         riskText = 'MEDIUM';
//         break;
//       case RiskLevel.low:
//         riskColor = Colors.blue;
//         riskIcon = Icons.check_circle;
//         riskText = 'LOW';
//         break;
//       default:
//         riskColor = Colors.green;
//         riskIcon = Icons.check_circle_outline;
//         riskText = 'SAFE';
//     }

//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: riskColor.withOpacity(0.08),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: riskColor.withOpacity(0.3), width: 2),
//       ),
//       child: Row(
//         children: [
//           Icon(riskIcon, size: 36, color: riskColor),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Risk Level: $riskText',
//                   style: GoogleFonts.poppins(
//                     fontWeight: FontWeight.w700,
//                     fontSize: 18,
//                     color: riskColor,
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 Text(
//                   _analysis!.riskDescription,
//                   style: GoogleFonts.inter(
//                     fontSize: 14,
//                     color: AppTheme.textSecondary,
//                     height: 1.4,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 LinearProgressIndicator(
//                   value: _analysis!.riskScore / 10,
//                   backgroundColor: riskColor.withOpacity(0.2),
//                   valueColor: AlwaysStoppedAnimation<Color>(riskColor),
//                   minHeight: 8,
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 const SizedBox(height: 4),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Risk Score',
//                       style: GoogleFonts.inter(
//                         fontSize: 12,
//                         color: AppTheme.textSecondary,
//                       ),
//                     ),
//                     Text(
//                       '${_analysis!.riskScore.toStringAsFixed(1)}/10',
//                       style: GoogleFonts.inter(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                         color: riskColor,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmotionalAnalysis() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 Icons.emoji_emotions_outlined,
//                 color: AppTheme.primaryRed,
//                 size: 24,
//               ),
//               const SizedBox(width: 10),
//               Text(
//                 'Emotional Analysis',
//                 style: GoogleFonts.poppins(
//                   fontWeight: FontWeight.w600,
//                   fontSize: 18,
//                   color: AppTheme.textPrimary,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),

//           // Primary Emotion
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: _getEmotionColor(
//                 _analysis!.primaryEmotion,
//               ).withOpacity(0.1),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: _getEmotionColor(
//                   _analysis!.primaryEmotion,
//                 ).withOpacity(0.3),
//               ),
//             ),
//             child: Row(
//               children: [
//                 Container(
//                   width: 50,
//                   height: 50,
//                   decoration: BoxDecoration(
//                     color: _getEmotionColor(_analysis!.primaryEmotion),
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(
//                     _getEmotionIcon(_analysis!.primaryEmotion),
//                     color: Colors.white,
//                     size: 24,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         _analysis!.primaryEmotion.toUpperCase(),
//                         style: GoogleFonts.inter(
//                           fontWeight: FontWeight.w700,
//                           fontSize: 16,
//                           color: _getEmotionColor(_analysis!.primaryEmotion),
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         _analysis!.emotionDescription,
//                         style: GoogleFonts.inter(
//                           fontSize: 13,
//                           color: AppTheme.textSecondary,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Text(
//                   '${(_analysis!.emotionIntensity * 100).toInt()}%',
//                   style: GoogleFonts.inter(
//                     fontWeight: FontWeight.w700,
//                     fontSize: 20,
//                     color: _getEmotionColor(_analysis!.primaryEmotion),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 12),

//           // Secondary Emotions
//           if (_analysis!.secondaryEmotions.isNotEmpty)
//             Wrap(
//               spacing: 8,
//               runSpacing: 8,
//               children: _analysis!.secondaryEmotions.map((emotion) {
//                 return Chip(
//                   label: Text(
//                     emotion,
//                     style: GoogleFonts.inter(
//                       fontSize: 12,
//                       color: _getEmotionColor(emotion),
//                     ),
//                   ),
//                   backgroundColor: _getEmotionColor(emotion).withOpacity(0.1),
//                   side: BorderSide(
//                     color: _getEmotionColor(emotion).withOpacity(0.3),
//                   ),
//                   avatar: Icon(
//                     _getEmotionIcon(emotion),
//                     size: 16,
//                     color: _getEmotionColor(emotion),
//                   ),
//                 );
//               }).toList(),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildKeyConcerns() {
//     if (_analysis!.keyConcerns.isEmpty) {
//       return Container(
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.flag_outlined, color: AppTheme.primaryRed, size: 24),
//                 const SizedBox(width: 10),
//                 Text(
//                   'Key Concerns',
//                   style: GoogleFonts.poppins(
//                     fontWeight: FontWeight.w600,
//                     fontSize: 18,
//                     color: AppTheme.textPrimary,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.green.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.check_circle, color: Colors.green, size: 24),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       'No major concerns detected in this conversation.',
//                       style: GoogleFonts.inter(
//                         fontSize: 14,
//                         color: Colors.green[800],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.flag_outlined, color: AppTheme.primaryRed, size: 24),
//               const SizedBox(width: 10),
//               Text(
//                 'Key Concerns (${_analysis!.keyConcerns.length})',
//                 style: GoogleFonts.poppins(
//                   fontWeight: FontWeight.w600,
//                   fontSize: 18,
//                   color: AppTheme.textPrimary,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Column(
//             children: _analysis!.keyConcerns.asMap().entries.map((entry) {
//               final index = entry.key;
//               final concern = entry.value;
//               return Container(
//                 margin: EdgeInsets.only(
//                   bottom: index == _analysis!.keyConcerns.length - 1 ? 0 : 12,
//                 ),
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.orange.withOpacity(0.05),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.orange.withOpacity(0.2)),
//                 ),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Container(
//                       width: 32,
//                       height: 32,
//                       decoration: BoxDecoration(
//                         color: Colors.orange.withOpacity(0.2),
//                         shape: BoxShape.circle,
//                       ),
//                       child: Center(
//                         child: Text(
//                           '${index + 1}',
//                           style: GoogleFonts.inter(
//                             fontWeight: FontWeight.w700,
//                             color: Colors.orange[800],
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             concern,
//                             style: GoogleFonts.inter(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w500,
//                               color: AppTheme.textPrimary,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             }).toList(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatistics() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 Icons.analytics_outlined,
//                 color: AppTheme.primaryRed,
//                 size: 24,
//               ),
//               const SizedBox(width: 10),
//               Text(
//                 'Conversation Statistics',
//                 style: GoogleFonts.poppins(
//                   fontWeight: FontWeight.w600,
//                   fontSize: 18,
//                   color: AppTheme.textPrimary,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           GridView.count(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             crossAxisCount: 2,
//             crossAxisSpacing: 12,
//             mainAxisSpacing: 12,
//             childAspectRatio: 1.2,
//             children: [
//               _buildStatCard(
//                 'Total Messages',
//                 widget.conversation.length.toString(),
//                 Icons.chat_bubble_outline,
//                 Colors.blue,
//               ),
//               _buildStatCard(
//                 'Risk Alerts',
//                 widget.alerts.length.toString(),
//                 Icons.warning_amber_rounded,
//                 Colors.orange,
//               ),
//               _buildStatCard(
//                 'User Messages',
//                 widget.conversation.where((m) => m.isUser).length.toString(),
//                 Icons.person_outline,
//                 AppTheme.primaryRed,
//               ),
//               _buildStatCard(
//                 'AI Responses',
//                 widget.conversation.where((m) => !m.isUser).length.toString(),
//                 Icons.psychology_outlined,
//                 Colors.purple,
//               ),
//               _buildStatCard(
//                 'Duration',
//                 '${_analysis!.durationInMinutes} min',
//                 Icons.timer_outlined,
//                 Colors.green,
//               ),
//               _buildStatCard(
//                 'Response Time',
//                 '${_analysis!.avgResponseTime.toStringAsFixed(1)}s',
//                 Icons.speed_outlined,
//                 Colors.teal,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatCard(
//     String title,
//     String value,
//     IconData icon,
//     Color color,
//   ) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, size: 28, color: color),
//           const SizedBox(height: 8),
//           Text(
//             value,
//             style: GoogleFonts.poppins(
//               fontWeight: FontWeight.w700,
//               fontSize: 22,
//               color: color,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             title,
//             style: GoogleFonts.inter(
//               fontSize: 11,
//               color: AppTheme.textSecondary,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFollowUpQuestions() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 Icons.question_answer_outlined,
//                 color: AppTheme.primaryRed,
//                 size: 24,
//               ),
//               const SizedBox(width: 10),
//               Text(
//                 'Follow-up Questions',
//                 style: GoogleFonts.poppins(
//                   fontWeight: FontWeight.w600,
//                   fontSize: 18,
//                   color: AppTheme.textPrimary,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Text(
//             'Questions to ask for better understanding and support:',
//             style: GoogleFonts.inter(
//               fontSize: 14,
//               color: AppTheme.textSecondary,
//             ),
//           ),
//           const SizedBox(height: 16),
//           Column(
//             children: _analysis!.followUpQuestions.asMap().entries.map((entry) {
//               final index = entry.key;
//               final question = entry.value;
//               return Container(
//                 margin: EdgeInsets.only(
//                   bottom: index == _analysis!.followUpQuestions.length - 1
//                       ? 0
//                       : 12,
//                 ),
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.blue.withOpacity(0.05),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.blue.withOpacity(0.2)),
//                 ),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Container(
//                       width: 28,
//                       height: 28,
//                       decoration: BoxDecoration(
//                         color: Colors.blue.withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Center(
//                         child: Text(
//                           '${index + 1}',
//                           style: GoogleFonts.inter(
//                             fontWeight: FontWeight.w700,
//                             color: Colors.blue[800],
//                             fontSize: 12,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Text(
//                         question,
//                         style: GoogleFonts.inter(
//                           fontSize: 14,
//                           color: AppTheme.textPrimary,
//                           height: 1.4,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             }).toList(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRecommendations() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 Icons.recommend_outlined,
//                 color: AppTheme.primaryRed,
//                 size: 24,
//               ),
//               const SizedBox(width: 10),
//               Text(
//                 'Recommendations',
//                 style: GoogleFonts.poppins(
//                   fontWeight: FontWeight.w600,
//                   fontSize: 18,
//                   color: AppTheme.textPrimary,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Column(
//             children: _analysis!.recommendations.asMap().entries.map((entry) {
//               final index = entry.key;
//               final recommendation = entry.value;
//               return Container(
//                 margin: EdgeInsets.only(
//                   bottom: index == _analysis!.recommendations.length - 1
//                       ? 0
//                       : 12,
//                 ),
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.green.withOpacity(0.05),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.green.withOpacity(0.2)),
//                 ),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Icon(
//                       Icons.check_circle_outline,
//                       color: Colors.green,
//                       size: 20,
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Text(
//                         recommendation,
//                         style: GoogleFonts.inter(
//                           fontSize: 14,
//                           color: AppTheme.textPrimary,
//                           height: 1.4,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             }).toList(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButtons() {
//     return Row(
//       children: [
//         Expanded(
//           child: ElevatedButton(
//             onPressed: () => _showResourcesDialog(),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.white,
//               foregroundColor: AppTheme.primaryRed,
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 side: BorderSide(color: AppTheme.primaryRed, width: 2),
//               ),
//               elevation: 0,
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.help_outline, size: 20),
//                 const SizedBox(width: 8),
//                 Text(
//                   'View Resources',
//                   style: GoogleFonts.inter(
//                     fontWeight: FontWeight.w600,
//                     fontSize: 15,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: ElevatedButton(
//             onPressed: () => _exportAnalysis(),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppTheme.primaryRed,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               elevation: 2,
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.share_outlined, size: 20),
//                 const SizedBox(width: 8),
//                 Text(
//                   'Export Report',
//                   style: GoogleFonts.inter(
//                     fontWeight: FontWeight.w600,
//                     fontSize: 15,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildLoadingView() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           CircularProgressIndicator(color: AppTheme.primaryRed, strokeWidth: 3),
//           const SizedBox(height: 20),
//           Text(
//             'Analyzing conversation...',
//             style: GoogleFonts.inter(
//               fontSize: 16,
//               color: AppTheme.textSecondary,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'This may take a moment',
//             style: GoogleFonts.inter(
//               fontSize: 13,
//               color: AppTheme.textSecondary.withOpacity(0.7),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildErrorView() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(40),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error_outline, size: 60, color: Colors.orange),
//             const SizedBox(height: 20),
//             Text(
//               'Analysis Failed',
//               style: GoogleFonts.poppins(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w600,
//                 color: AppTheme.textPrimary,
//               ),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               _error!,
//               style: GoogleFonts.inter(
//                 fontSize: 14,
//                 color: AppTheme.textSecondary,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton(
//               onPressed: _analyzeConversation,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppTheme.primaryRed,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 32,
//                   vertical: 12,
//                 ),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//               child: Text(
//                 'Try Again',
//                 style: GoogleFonts.inter(
//                   fontWeight: FontWeight.w600,
//                   fontSize: 15,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildNoAnalysisView() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(40),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.analytics_outlined,
//               size: 60,
//               color: AppTheme.primaryRed,
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'No Analysis Available',
//               style: GoogleFonts.poppins(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w600,
//                 color: AppTheme.textPrimary,
//               ),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               'Unable to generate analysis for this conversation.',
//               style: GoogleFonts.inter(
//                 fontSize: 14,
//                 color: AppTheme.textSecondary,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton(
//               onPressed: () => Navigator.of(context).pop(),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppTheme.primaryRed,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 32,
//                   vertical: 12,
//                 ),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//               child: Text(
//                 'Go Back',
//                 style: GoogleFonts.inter(
//                   fontWeight: FontWeight.w600,
//                   fontSize: 15,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showResourcesDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Row(
//           children: [
//             Icon(Icons.help_outline, color: AppTheme.primaryRed, size: 28),
//             const SizedBox(width: 12),
//             Text(
//               'Support Resources',
//               style: GoogleFonts.poppins(
//                 fontWeight: FontWeight.w600,
//                 fontSize: 18,
//               ),
//             ),
//           ],
//         ),
//         content: SizedBox(
//           width: double.maxFinite,
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildResourceItem(
//                   'Crisis Helpline',
//                   '988',
//                   'National Suicide Prevention Lifeline',
//                   Icons.phone,
//                 ),
//                 _buildResourceItem(
//                   'Crisis Text Line',
//                   'Text HOME to 741741',
//                   '24/7 crisis counseling via text',
//                   Icons.sms,
//                 ),
//                 _buildResourceItem(
//                   'Emergency Services',
//                   '911',
//                   'For immediate danger or emergency',
//                   Icons.local_hospital,
//                 ),
//                 _buildResourceItem(
//                   'Mental Health America',
//                   '1-800-273-TALK',
//                   'Information and referrals',
//                   Icons.health_and_safety,
//                 ),
//                 _buildResourceItem(
//                   'The Trevor Project',
//                   '1-866-488-7386',
//                   'LGBTQ+ youth crisis intervention',
//                   Icons.diversity_3,
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   'Remember: You are not alone. Help is available 24/7.',
//                   style: GoogleFonts.inter(
//                     fontSize: 13,
//                     color: AppTheme.textSecondary,
//                     fontStyle: FontStyle.italic,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             style: TextButton.styleFrom(
//               foregroundColor: AppTheme.textSecondary,
//             ),
//             child: Text(
//               'Close',
//               style: GoogleFonts.inter(fontWeight: FontWeight.w600),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildResourceItem(
//     String title,
//     String contact,
//     String description,
//     IconData icon,
//   ) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: Colors.blue.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.blue.withOpacity(0.2)),
//       ),
//       child: Row(
//         children: [
//           Icon(icon, size: 24, color: Colors.blue),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: GoogleFonts.inter(
//                     fontWeight: FontWeight.w600,
//                     fontSize: 14,
//                     color: AppTheme.textPrimary,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   contact,
//                   style: GoogleFonts.inter(
//                     fontWeight: FontWeight.w700,
//                     fontSize: 15,
//                     color: Colors.blue[800],
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   description,
//                   style: GoogleFonts.inter(
//                     fontSize: 12,
//                     color: AppTheme.textSecondary,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _exportAnalysis() {
//     // In a real app, this would export to PDF or share
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           'Report exported successfully',
//           style: GoogleFonts.inter(),
//         ),
//         backgroundColor: Colors.green,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }

//   Color _getEmotionColor(String emotion) {
//     switch (emotion.toLowerCase()) {
//       case 'distress':
//         return Colors.red;
//       case 'anxiety':
//         return Colors.orange;
//       case 'depression':
//         return Colors.blue;
//       case 'anger':
//         return Colors.red[900]!;
//       case 'sadness':
//         return Colors.blue[800]!;
//       case 'fear':
//         return Colors.purple;
//       case 'loneliness':
//         return Colors.grey[700]!;
//       case 'stress':
//         return Colors.orange[800]!;
//       case 'confusion':
//         return Colors.yellow[700]!;
//       case 'neutral':
//         return Colors.grey;
//       default:
//         return AppTheme.primaryRed;
//     }
//   }

//   IconData _getEmotionIcon(String emotion) {
//     switch (emotion.toLowerCase()) {
//       case 'distress':
//         return Icons.warning_amber_rounded;
//       case 'anxiety':
//         return Icons.psychology_outlined;
//       case 'depression':
//         return Icons.mood_bad;
//       case 'anger':
//         return Icons.flash_on;
//       case 'sadness':
//         return Icons.sentiment_very_dissatisfied;
//       case 'fear':
//         return Icons.warning;
//       case 'loneliness':
//         return Icons.person_off;
//       case 'stress':
//         return Icons.fitness_center;
//       case 'confusion':
//         return Icons.help_outline;
//       case 'neutral':
//         return Icons.sentiment_neutral;
//       default:
//         return Icons.emoji_emotions_outlined;
//     }
//   }

//   String _formatDate(DateTime date) {
//     return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
//   }
// }

// // ==================== ANALYZER CLASS ====================

// class ConversationAnalyzer {
//   Future<ConversationAnalysis> analyze({
//     required List<ChatMessage> conversation,
//     required List<RiskAlert> alerts,
//   }) async {
//     // Calculate basic statistics
//     final userMessages = conversation.where((m) => m.isUser).toList();
//     final aiMessages = conversation.where((m) => !m.isUser).toList();

//     final duration = conversation.isNotEmpty
//         ? conversation.last.timestamp.difference(conversation.first.timestamp)
//         : const Duration();

//     // Analyze emotions from user messages
//     final emotionalAnalysis = _analyzeEmotions(userMessages);

//     // Calculate risk score
//     final riskScore = _calculateRiskScore(alerts, userMessages);
//     final riskLevel = _determineRiskLevel(riskScore);

//     // Extract key concerns
//     final keyConcerns = _extractKeyConcerns(userMessages, alerts);

//     // Generate follow-up questions
//     final followUpQuestions = _generateFollowUpQuestions(
//       emotionalAnalysis.primaryEmotion,
//       keyConcerns,
//       riskLevel,
//     );

//     // Generate recommendations
//     final recommendations = _generateRecommendations(
//       riskLevel,
//       emotionalAnalysis,
//     );

//     return ConversationAnalysis(
//       conversation: conversation,
//       alerts: alerts,
//       riskScore: riskScore,
//       riskLevel: riskLevel,
//       riskDescription: _getRiskDescription(riskLevel),
//       isSafe: riskLevel == RiskLevel.low || riskLevel == RiskLevel.none,
//       primaryEmotion: emotionalAnalysis.primaryEmotion,
//       secondaryEmotions: emotionalAnalysis.secondaryEmotions,
//       emotionDescription: emotionalAnalysis.description,
//       emotionIntensity: emotionalAnalysis.intensity,
//       keyConcerns: keyConcerns,
//       followUpQuestions: followUpQuestions,
//       recommendations: recommendations,
//       durationInMinutes: duration.inMinutes,
//       avgResponseTime: _calculateAvgResponseTime(conversation),
//       totalMessages: conversation.length,
//       userMessageCount: userMessages.length,
//       aiMessageCount: aiMessages.length,
//     );
//   }

//   EmotionalAnalysis _analyzeEmotions(List<ChatMessage> userMessages) {
//     if (userMessages.isEmpty) {
//       return EmotionalAnalysis(
//         primaryEmotion: 'neutral',
//         secondaryEmotions: [],
//         description: 'No emotional data available',
//         intensity: 0.0,
//       );
//     }

//     // Emotion patterns
//     final emotionPatterns = {
//       'distress': [
//         'kill myself',
//         'suicide',
//         'end my life',
//         'want to die',
//         'better off dead',
//       ],
//       'anxiety': [
//         'anxious',
//         'worried',
//         'nervous',
//         'panic',
//         'overwhelmed',
//         'stress',
//       ],
//       'depression': [
//         'depressed',
//         'sad',
//         'hopeless',
//         'worthless',
//         'empty',
//         'nothing matters',
//       ],
//       'anger': ['angry', 'frustrated', 'mad', 'hate', 'rage', 'upset'],
//       'sadness': ['sad', 'cry', 'tears', 'unhappy', 'miserable'],
//       'fear': ['scared', 'afraid', 'fear', 'terrified', 'anxious'],
//       'loneliness': ['alone', 'lonely', 'isolated', 'no one', 'nobody'],
//       'stress': ['stress', 'pressure', 'overwhelmed', 'busy', 'tired'],
//       'confusion': ['confused', 'unsure', 'don\'t know', 'lost', 'uncertain'],
//     };

//     Map<String, int> emotionCounts = {};
//     double totalIntensity = 0.0;

//     for (var message in userMessages) {
//       final lowerMessage = message.message.toLowerCase();

//       for (var entry in emotionPatterns.entries) {
//         for (var pattern in entry.value) {
//           if (lowerMessage.contains(pattern)) {
//             emotionCounts[entry.key] = (emotionCounts[entry.key] ?? 0) + 1;

//             // Intensity based on risk score
//             final intensity = (message.riskScore ?? 0) / 10.0;
//             totalIntensity += intensity;
//             break;
//           }
//         }
//       }
//     }

//     // Determine primary emotion
//     String primaryEmotion = 'neutral';
//     List<String> secondaryEmotions = [];

//     if (emotionCounts.isNotEmpty) {
//       final sortedEmotions = emotionCounts.entries.toList()
//         ..sort((a, b) => b.value.compareTo(a.value));

//       primaryEmotion = sortedEmotions.first.key;
//       secondaryEmotions = sortedEmotions
//           .sublist(1, min(sortedEmotions.length, 3))
//           .map((e) => e.key)
//           .toList();
//     }

//     // Calculate average intensity
//     final avgIntensity = totalIntensity / userMessages.length;

//     // Generate description
//     final description = _getEmotionDescription(primaryEmotion, avgIntensity);

//     return EmotionalAnalysis(
//       primaryEmotion: primaryEmotion,
//       secondaryEmotions: secondaryEmotions,
//       description: description,
//       intensity: avgIntensity.clamp(0.0, 1.0),
//     );
//   }

//   double _calculateRiskScore(
//     List<RiskAlert> alerts,
//     List<ChatMessage> userMessages,
//   ) {
//     if (alerts.isEmpty && userMessages.isEmpty) return 0.0;

//     // Base score from alerts
//     double alertScore = 0.0;
//     for (var alert in alerts) {
//       alertScore += alert.riskScore / 10.0;
//     }
//     if (alerts.isNotEmpty) {
//       alertScore /= alerts.length;
//     }

//     // Additional score from risky messages without alerts
//     int riskyMessages = 0;
//     for (var message in userMessages) {
//       if (message.riskScore != null && message.riskScore! > 3) {
//         riskyMessages++;
//       }
//     }

//     final riskyMessageScore = riskyMessages / userMessages.length;

//     // Combine scores
//     return (alertScore * 0.7 + riskyMessageScore * 0.3) * 10;
//   }

//   RiskLevel _determineRiskLevel(double score) {
//     if (score >= 8.0) return RiskLevel.critical;
//     if (score >= 6.0) return RiskLevel.high;
//     if (score >= 4.0) return RiskLevel.medium;
//     if (score >= 2.0) return RiskLevel.low;
//     return RiskLevel.none;
//   }

//   List<String> _extractKeyConcerns(
//     List<ChatMessage> userMessages,
//     List<RiskAlert> alerts,
//   ) {
//     final concerns = <String>{};

//     // Add concerns from alerts
//     for (var alert in alerts) {
//       if (alert.riskScore >= 6) {
//         concerns.add('Expressed thoughts of ${alert.keywords.join('/')}');
//       } else if (alert.riskScore >= 4) {
//         concerns.add('Showed signs of ${alert.keywords.join('/')}');
//       }
//     }

//     // Extract concerns from messages
//     final concernPatterns = {
//       'Relationship issues': ['partner', 'relationship', 'breakup', 'divorce'],
//       'Work/school stress': ['work', 'job', 'school', 'exam', 'deadline'],
//       'Financial worries': ['money', 'bills', 'debt', 'financial'],
//       'Health concerns': ['sick', 'health', 'pain', 'doctor', 'hospital'],
//       'Family problems': ['family', 'parent', 'child', 'sibling'],
//       'Social isolation': ['alone', 'lonely', 'friend', 'social'],
//       'Self-esteem issues': ['worthless', 'failure', 'stupid', 'ugly'],
//       'Trauma': ['trauma', 'abuse', 'accident', 'loss', 'grief'],
//     };

//     for (var message in userMessages) {
//       final lowerMessage = message.message.toLowerCase();
//       for (var entry in concernPatterns.entries) {
//         for (var keyword in entry.value) {
//           if (lowerMessage.contains(keyword)) {
//             concerns.add(entry.key);
//             break;
//           }
//         }
//       }
//     }

//     return concerns.toList().take(5).toList();
//   }

//   List<String> _generateFollowUpQuestions(
//     String primaryEmotion,
//     List<String> keyConcerns,
//     RiskLevel riskLevel,
//   ) {
//     final questions = <String>[];

//     // General questions
//     questions.add('How have you been feeling since our last conversation?');
//     questions.add('What\'s been the most challenging part of your day/week?');
//     questions.add(
//       'Is there anything specific that\'s been on your mind lately?',
//     );

//     // Emotion-specific questions
//     switch (primaryEmotion.toLowerCase()) {
//       case 'distress':
//         questions.add(
//           'What kind of support would be most helpful for you right now?',
//         );
//         questions.add(
//           'Have you been able to reach out to anyone about how you\'re feeling?',
//         );
//         break;
//       case 'anxiety':
//         questions.add('What situations tend to make you feel most anxious?');
//         questions.add('What helps you feel more calm and centered?');
//         break;
//       case 'depression':
//         questions.add('How has your energy and motivation been lately?');
//         questions.add(
//           'What activities usually help lift your mood, even a little?',
//         );
//         break;
//       case 'anger':
//         questions.add('What typically triggers feelings of anger for you?');
//         questions.add('How do you usually handle strong emotions like anger?');
//         break;
//     }

//     // Concern-specific questions
//     if (keyConcerns.isNotEmpty) {
//       if (keyConcerns.any((c) => c.contains('Relationship'))) {
//         questions.add('How are things going in your important relationships?');
//       }
//       if (keyConcerns.any((c) => c.contains('Work') || c.contains('school'))) {
//         questions.add(
//           'How are you managing your work/school responsibilities?',
//         );
//       }
//     }

//     // Risk-level questions
//     if (riskLevel == RiskLevel.critical || riskLevel == RiskLevel.high) {
//       questions.add(
//         'Do you have a safety plan or support system you can reach out to?',
//       );
//       questions.add(
//         'What helps you feel safer when you\'re having difficult thoughts?',
//       );
//     }

//     // Ensure we have exactly 5 questions
//     return questions.take(5).toList();
//   }

//   List<String> _generateRecommendations(
//     RiskLevel riskLevel,
//     EmotionalAnalysis emotions,
//   ) {
//     final recommendations = <String>[];

//     // Risk-based recommendations
//     switch (riskLevel) {
//       case RiskLevel.critical:
//         recommendations.add('Immediate professional support is recommended');
//         recommendations.add(
//           'Contact crisis services if thoughts become overwhelming',
//         );
//         recommendations.add('Create a safety plan with trusted individuals');
//         break;
//       case RiskLevel.high:
//         recommendations.add(
//           'Consider speaking with a mental health professional',
//         );
//         recommendations.add(
//           'Regular check-ins with support system recommended',
//         );
//         recommendations.add(
//           'Practice self-care and stress management techniques',
//         );
//         break;
//       case RiskLevel.medium:
//         recommendations.add('Monitor emotional state and seek help if needed');
//         recommendations.add(
//           'Engage in regular physical activity and social connection',
//         );
//         recommendations.add(
//           'Practice mindfulness or relaxation techniques daily',
//         );
//         break;
//       case RiskLevel.low:
//         recommendations.add('Continue healthy coping strategies');
//         recommendations.add(
//           'Maintain regular self-reflection and emotional awareness',
//         );
//         recommendations.add(
//           'Build resilience through positive habits and connections',
//         );
//         break;
//       case RiskLevel.none:
//         recommendations.add('Continue positive mental health practices');
//         recommendations.add('Regular emotional check-ins are beneficial');
//         recommendations.add(
//           'Maintain healthy lifestyle and social connections',
//         );
//         break;
//     }

//     // Emotion-specific recommendations
//     switch (emotions.primaryEmotion.toLowerCase()) {
//       case 'distress':
//         recommendations.add('Immediate crisis support is crucial');
//         recommendations.add('Remove access to potential means of self-harm');
//         break;
//       case 'anxiety':
//         recommendations.add('Practice grounding techniques when anxious');
//         recommendations.add('Consider anxiety management strategies');
//         break;
//       case 'depression':
//         recommendations.add(
//           'Establish a daily routine with small, achievable goals',
//         );
//         recommendations.add(
//           'Seek activities that provide a sense of accomplishment',
//         );
//         break;
//       case 'anger':
//         recommendations.add('Practice anger management techniques');
//         recommendations.add('Identify triggers and develop coping strategies');
//         break;
//     }

//     return recommendations.take(5).toList();
//   }

//   double _calculateAvgResponseTime(List<ChatMessage> conversation) {
//     if (conversation.length < 2) return 0.0;

//     double totalResponseTime = 0.0;
//     int responseCount = 0;

//     for (int i = 0; i < conversation.length - 1; i++) {
//       if (conversation[i].isUser && !conversation[i + 1].isUser) {
//         final responseTime = conversation[i + 1].timestamp
//             .difference(conversation[i].timestamp)
//             .inSeconds;
//         totalResponseTime += responseTime;
//         responseCount++;
//       }
//     }

//     return responseCount > 0 ? totalResponseTime / responseCount : 0.0;
//   }

//   String _getRiskDescription(RiskLevel level) {
//     switch (level) {
//       case RiskLevel.critical:
//         return 'Immediate intervention and professional support required. User expressed severe distress or suicidal thoughts.';
//       case RiskLevel.high:
//         return 'Significant emotional distress detected. Professional support recommended.';
//       case RiskLevel.medium:
//         return 'Moderate emotional concerns identified. Monitoring and support advised.';
//       case RiskLevel.low:
//         return 'Minor emotional concerns noted. General support and self-care recommended.';
//       case RiskLevel.none:
//         return 'Conversation appears safe with no significant concerns detected.';
//     }
//   }

//   String _getEmotionDescription(String emotion, double intensity) {
//     final intensityLevel = intensity >= 0.7
//         ? 'severe'
//         : intensity >= 0.4
//         ? 'moderate'
//         : 'mild';

//     switch (emotion.toLowerCase()) {
//       case 'distress':
//         return 'Experiencing $intensityLevel emotional distress and potential crisis';
//       case 'anxiety':
//         return 'Showing $intensityLevel signs of anxiety and worry';
//       case 'depression':
//         return 'Exhibiting $intensityLevel depressive symptoms and low mood';
//       case 'anger':
//         return 'Displaying $intensityLevel anger and frustration';
//       case 'sadness':
//         return 'Feeling $intensityLevel sadness and emotional pain';
//       case 'fear':
//         return 'Experiencing $intensityLevel fear and apprehension';
//       case 'loneliness':
//         return 'Feeling $intensityLevel loneliness and social isolation';
//       case 'stress':
//         return 'Under $intensityLevel stress and pressure';
//       case 'confusion':
//         return 'Experiencing $intensityLevel confusion and uncertainty';
//       default:
//         return 'Emotional state appears relatively stable';
//     }
//   }
// }

// // ==================== DATA MODELS ====================

// class ConversationAnalysis {
//   final List<ChatMessage> conversation;
//   final List<RiskAlert> alerts;
//   final double riskScore;
//   final RiskLevel riskLevel;
//   final String riskDescription;
//   final bool isSafe;

//   final String primaryEmotion;
//   final List<String> secondaryEmotions;
//   final String emotionDescription;
//   final double emotionIntensity;

//   final List<String> keyConcerns;
//   final List<String> followUpQuestions;
//   final List<String> recommendations;

//   final int durationInMinutes;
//   final double avgResponseTime;
//   final int totalMessages;
//   final int userMessageCount;
//   final int aiMessageCount;

//   ConversationAnalysis({
//     required this.conversation,
//     required this.alerts,
//     required this.riskScore,
//     required this.riskLevel,
//     required this.riskDescription,
//     required this.isSafe,
//     required this.primaryEmotion,
//     required this.secondaryEmotions,
//     required this.emotionDescription,
//     required this.emotionIntensity,
//     required this.keyConcerns,
//     required this.followUpQuestions,
//     required this.recommendations,
//     required this.durationInMinutes,
//     required this.avgResponseTime,
//     required this.totalMessages,
//     required this.userMessageCount,
//     required this.aiMessageCount,
//   });
// }

// class EmotionalAnalysis {
//   final String primaryEmotion;
//   final List<String> secondaryEmotions;
//   final String description;
//   final double intensity;

//   EmotionalAnalysis({
//     required this.primaryEmotion,
//     required this.secondaryEmotions,
//     required this.description,
//     required this.intensity,
//   });
// }

// enum RiskLevel { none, low, medium, high, critical }
