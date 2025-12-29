import 'package:flutter/material.dart';
import 'package:hnhsmind_care/pages/admin_screen/admin_journal.dart';
import 'package:hnhsmind_care/pages/admin_screen/admin_mood_tracker_screen.dart';
import 'package:hnhsmind_care/pages/admin_screen/booked_appoinment.dart';
import 'package:hnhsmind_care/pages/admin_screen/emergency_alert_screen.dart';
import 'package:hnhsmind_care/pages/registration_screen.dart';
import 'package:hnhsmind_care/pages/update_profile/update_profile.dart';
import 'package:hnhsmind_care/provider/auth_provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../app_theme.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final List<AdminDashboardItem> _adminMenuItems = [
    AdminDashboardItem(
      title: "Appointments",
      description: "Manage all booked appointments",
      icon: Iconsax.calendar_tick,
      color: AppTheme.primaryRed,
      gradient: [Color(0xFFFF6B8B), AppTheme.primaryRed],
      route: '/appointments',
    ),
    AdminDashboardItem(
      title: "Chat",
      description: "Monitor urgent cases",
      icon: Iconsax.warning_2,
      color: Colors.orange,
      gradient: [Color(0xFFFFA726), Color(0xFFFFB74D)],
      route: '/emergencyAlerts',
    ),
    AdminDashboardItem(
      title: "Daily Journal",
      description: "Review user reflections",
      icon: Iconsax.book_1,
      color: Color(0xFF8B5CF6),
      gradient: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
      route: '/userJournals',
    ),
    AdminDashboardItem(
      title: "Mood",
      description: "Track user emotional trends",
      icon: Iconsax.chart_2,
      color: Color(0xFF10B981),
      gradient: [Color(0xFF10B981), Color(0xFF34D399)],
      route: '/moodAnalytics',
    ),
    AdminDashboardItem(
      title: "Register Staff",
      description: "Add new administrators",
      icon: Iconsax.user_add,
      color: Color(0xFF3B82F6),
      gradient: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
      route: '/registerStaff',
    ),
  ];

  Map<String, dynamic> userData = {};

  @override
  void initState() {
    super.initState();
    getUser();
  }

  void getUser() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final data = await authProvider.getAuthData();

    setState(() {
      userData = data;
    });
  }

  void _handleMenuTap(AdminDashboardItem item) {
    switch (item.route) {
      case '/appointments':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BookedAppointment()),
        );
        break;
      case '/emergencyAlerts':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EmergencyAlertsScreen()),
        );
        break;
      case '/userJournals':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AdminJournalScreen()),
        );
        break;
      case '/moodAnalytics':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AdminMoodTrackerScreen()),
        );
        break;
      case '/registerStaff':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RegisterScreen(roleId: 1)),
        );
        break;
      case '/userManagement':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User Management - Coming Soon'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
        break;
    }

    // Show snackbar feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${item.title}'),
        duration: Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final timeOfDay = _getTimeOfDay();

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        drawer: _buildDrawer(user),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeaderSection(user, timeOfDay),
                SizedBox(height: 24),

                // Admin Stats Card
                _buildAdminStatsCard(),
                SizedBox(height: 24),

                // Daily Admin Task
                _buildDailyTask(),
                SizedBox(height: 24),

                // Quick Access Grid
                _buildQuickAccessGrid(), SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(User? user, String timeOfDay) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.surfaceColor, AppTheme.backgroundColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Admin Avatar with Status
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryRed, Color(0xFFFF6B8B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryRed.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Iconsax.shield_tick,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 16),

              // Admin Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Good $timeOfDay, Admin!",
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      user?.username ?? "Administrator",
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Administrator Dashboard",
                      style: TextStyle(
                        color: AppTheme.textSecondary.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Menu Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Builder(
                  builder: (context) => IconButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    icon: Icon(
                      Iconsax.menu_1,
                      color: AppTheme.primaryRed,
                      size: 22,
                    ),
                    padding: EdgeInsets.all(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminStatsCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "System Overview",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Manage mental health platform",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.shield_tick, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        "Admin Privileges",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(Iconsax.shield_cross, size: 40, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessGrid() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Admin Tools",
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                "${_adminMenuItems.length} tools",
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 15,
              childAspectRatio: .9,
            ),
            itemCount: _adminMenuItems.length,
            itemBuilder: (context, index) {
              return _buildAdminFeatureCard(_adminMenuItems[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdminFeatureCard(AdminDashboardItem item) {
    return Container(
      height: 230,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: item.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: item.gradient[0].withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _handleMenuTap(item),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(item.icon, size: 24, color: Colors.white),
                  ),
                ),
                SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      item.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyTask() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryRed, Color(0xFFFF6B8B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(Iconsax.task, size: 22, color: Colors.white),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Priority",
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Review pending appointments and check emergency alerts for urgent cases.",
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(User? user) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer Header
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryRed, AppTheme.secondaryRed],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Icon(Iconsax.user, size: 30, color: Colors.white),
                  ),
                  SizedBox(height: 15),
                  Text(
                    user?.username ?? "Admin",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    user?.email ?? "admin@example.com",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Profile Section
          ListTile(
            leading: Icon(Iconsax.profile_circle, color: AppTheme.primaryRed),
            title: Text(
              'Edit Profile',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () {
              Navigator.of(context).pop();
              if (user != null) {
                Map<String, dynamic> userData = {
                  'id': user.id,
                  'username': user.username,
                  'email': user.email,
                  'mobile_no': user.mobileNo,
                  'created_at': user.createdAt,
                  "birth_date": user.dateOfBirth.toString(),
                  "address": user.address,
                  "role": user.role,
                  "role_id": user.roleId,
                };
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        UserProfileUpdateScreen(userData: userData),
                  ),
                );
              }
            },
          ),

          Divider(height: 20),

          // Logout
          Container(
            margin: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.dangerColor),
            ),
            child: ListTile(
              leading: Icon(Iconsax.logout, color: AppTheme.dangerColor),
              title: Text(
                'Logout',
                style: TextStyle(
                  color: AppTheme.dangerColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                authProvider.clearAuthData();
                Navigator.pushReplacementNamed(context, '/splash');
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

class AdminDashboardItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<Color> gradient;
  final String route;

  AdminDashboardItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.gradient,
    required this.route,
  });
}
