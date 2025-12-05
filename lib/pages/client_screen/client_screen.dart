import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_theme.dart';
import '../chat_screen.dart';
import '../profile_screen.dart';
import '../resources_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ClientHomeScreenState createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    ChatScreen(),
    ResourcesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryRed,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.favorite, size: 18, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text(
              'HNHS Mental Health',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                fontSize: 20,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppTheme.lightRed,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.emergency_outlined, color: AppTheme.primaryRed),
              onPressed: () {
                _showEmergencyOptions();
              },
            ),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppTheme.primaryRed,
        unselectedItemColor: AppTheme.textSecondary,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Container(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.chat_bubble_outline),
            ),
            activeIcon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.lightRed,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chat_bubble),
            ),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.health_and_safety_outlined),
            ),
            activeIcon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.lightRed,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.health_and_safety),
            ),
            label: 'Resources',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.person_outline),
            ),
            activeIcon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.lightRed,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _showEmergencyOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Emergency Support',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Immediate help is available',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
            SizedBox(height: 24),
            _buildEmergencyButton(
              'National Suicide Prevention Lifeline',
              '1-800-273-8255',
              Icons.phone,
            ),
            SizedBox(height: 12),
            _buildEmergencyButton(
              'Crisis Text Line',
              'Text HOME to 741741',
              Icons.message,
            ),
            SizedBox(height: 12),
            _buildEmergencyButton('Emergency Services', '911', Icons.emergency),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyButton(String title, String subtitle, IconData icon) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Handle emergency call
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.lightRed,
          foregroundColor: AppTheme.primaryRed,
          padding: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          children: [
            Icon(icon, size: 24),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.primaryRed),
          ],
        ),
      ),
    );
  }
}
