import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../app_theme.dart';

class UserAgreementScreen extends StatelessWidget {
  final VoidCallback onAccept;
  const UserAgreementScreen({super.key, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text(
            'User Agreement & Privacy Policy',
            style: GoogleFonts.poppins(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppTheme.surfaceColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Iconsax.arrow_left, color: AppTheme.primaryRed),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(19),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Iconsax.security_safe,
                            size: 60,
                            color: AppTheme.primaryRed,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'CONFIDENTIALITY AGREEMENT',
                            style: GoogleFonts.poppins(
                              color: AppTheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'HNHS Mental Health App',
                            style: GoogleFonts.inter(
                              color: AppTheme.primaryRed,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

                    // Effective Date
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.lightRed.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryRed.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Iconsax.calendar,
                            color: AppTheme.primaryRed,
                            size: 20,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Effective Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                            style: GoogleFonts.inter(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

                    // Introduction
                    Text(
                      'INTRODUCTION',
                      style: GoogleFonts.inter(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Welcome to HNHS Mental Health App. This User Agreement and Privacy Policy ("Agreement") outlines the terms and conditions governing the use of our mental health consultation services. By accessing or using our services, you agree to be bound by this Agreement.',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: 24),

                    // Section 1: Confidentiality
                    _buildSection(
                      title: '1. STRICT CONFIDENTIALITY POLICY',
                      icon: Iconsax.shield_tick,
                      content: [
                        'All conversations between users (students) and mental health professionals are strictly confidential.',
                        'No content, messages, or personal information shared during consultations may be disclosed, shared, or leaked to any third party.',
                        'This confidentiality applies to both administrators and users of the platform.',
                      ],
                    ),
                    SizedBox(height: 24),

                    // Section 2: Non-Disclosure Agreement
                    _buildSection(
                      title: '2. NON-DISCLOSURE AGREEMENT (NDA)',
                      icon: Iconsax.document,
                      content: [
                        'By using this platform, you agree not to disclose any conversation details to anyone outside the platform.',
                        'You acknowledge that mental health conversations contain sensitive personal information that must remain private.',
                        'Screenshots, recordings, or any form of conversation capture without explicit consent is strictly prohibited.',
                      ],
                    ),
                    SizedBox(height: 24),

                    // Section 3: Sanctions for Violation
                    _buildSection(
                      title: '3. SANCTIONS FOR POLICY VIOLATION',
                      icon: Iconsax.warning_2,
                      content: [
                        'Any user found leaking or sharing conversation details will face immediate sanctions:',
                        '• First offense: Temporary suspension of account (7-30 days)',
                        '• Second offense: Permanent removal from the platform',
                        '• Severe violations: Immediate expulsion without warning',
                      ],
                    ),
                    SizedBox(height: 24),

                    // Section 4: Administrator Responsibility
                    _buildSection(
                      title: '4. ADMINISTRATOR RESPONSIBILITIES',
                      icon: Iconsax.user_tick,
                      content: [
                        'Administrators are equally bound by this confidentiality agreement.',
                        'Administrators must maintain professional discretion and protect user privacy at all times.',
                        'Any administrator found violating confidentiality will face immediate removal from their position and potential legal action.',
                      ],
                    ),
                    SizedBox(height: 24),

                    // Section 5: User Responsibilities
                    _buildSection(
                      title: '5. USER RESPONSIBILITIES',
                      icon: Iconsax.user,
                      content: [
                        'Users must respect the privacy of their own conversations and those of others.',
                        'Do not attempt to access conversations that are not your own.',
                        'Report any suspected privacy breaches immediately to support.',
                        'Use the platform for its intended purpose only - mental health support.',
                      ],
                    ),
                    SizedBox(height: 24),

                    // Section 6: Data Protection
                    _buildSection(
                      title: '6. DATA PROTECTION AND SECURITY',
                      icon: Iconsax.lock,
                      content: [
                        'All conversations are encrypted end-to-end for maximum security.',
                        'Personal data is stored securely and only accessible to authorized personnel.',
                        'We comply with data protection regulations to ensure your information remains safe.',
                        'Regular security audits are conducted to maintain platform integrity.',
                      ],
                    ),
                    SizedBox(height: 24),

                    // Section 7: Agreement Acceptance
                    _buildSection(
                      title: '7. AGREEMENT ACCEPTANCE',
                      icon: Iconsax.tick_circle,
                      content: [
                        'By continuing to use HNHS Mental Health App, you acknowledge that you have read, understood, and agree to all terms outlined in this Agreement.',
                        'This Agreement may be updated periodically. Continued use after updates constitutes acceptance of modified terms.',
                        'You can withdraw consent by discontinuing use of the platform.',
                      ],
                    ),
                    SizedBox(height: 24),

                    // Section 8: Emergency Situations
                    _buildSection(
                      title: '8. EMERGENCY SITUATIONS',
                      icon: Iconsax.call,
                      content: [
                        'In emergency situations where there is immediate risk of harm to yourself or others, confidentiality may be breached to ensure safety.',
                        'This exception only applies to life-threatening situations and follows professional ethical guidelines.',
                        'Users will be notified of any such breach as soon as possible.',
                      ],
                    ),
                    SizedBox(height: 24),

                    // Acceptance Checkbox
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.lightRed),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Iconsax.info_circle,
                            color: AppTheme.primaryRed,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'IMPORTANT NOTICE',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.dangerColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Violation of this agreement may result in immediate account termination and permanent ban from the platform. Please read carefully and ensure you understand all provisions.',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

                    // Signature/Acceptance
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [AppTheme.cardShadow],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'ELECTRONIC ACCEPTANCE',
                            style: GoogleFonts.inter(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'By using HNHS Mental Health App, you electronically sign this agreement and confirm your understanding and acceptance of all terms and conditions.',
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          Divider(color: AppTheme.lightRed),
                          SizedBox(height: 16),
                          Text(
                            'Last Updated: ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onAccept();
                  },
                  label: Text("Accept"),
                  icon: Icon(Iconsax.tick_circle),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<String> content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primaryRed, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: content.map((point) {
            return Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(
                      Iconsax.arrow_right_3,
                      color: AppTheme.primaryRed,
                      size: 16,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      point,
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
