import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hnhsmind_care/custom/page_route.dart';
import 'package:hnhsmind_care/pages/admin_screen/emergency_alert_screen.dart';
import 'package:hnhsmind_care/pages/admin_screen/admin_journal.dart';
import 'package:hnhsmind_care/pages/admin_screen/admin_mood_tracker_screen.dart';
import 'package:hnhsmind_care/pages/admin_screen/booked_appoinment.dart';
import 'package:hnhsmind_care/pages/registration_screen.dart';
import 'package:hnhsmind_care/pages/update_profile/update_profile.dart';
import 'package:hnhsmind_care/provider/auth_provider.dart';
import 'package:provider/provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  String headerText = "Appointments";
  final List<Widget> _tabs = [
    BookedAppointment(),
    EmergencyAlertsScreen(),
    AdminJournalScreen(),
    AdminMoodTrackerScreen(),
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

  void setIndex(index) {
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 0:
        setState(() {
          headerText = "Appointments";
        });
        break;
      case 1:
        setState(() {
          headerText = "Chat";
        });
        break;
      case 2:
        setState(() {
          headerText = "Journal";
        });
        break;
      case 3:
        setState(() {
          headerText = "Mood";
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(headerText),
        elevation: 0,
        backgroundColor: Colors.red.shade100,
        actions: [SizedBox(width: 20)],
      ),
      drawer: _buildDrawer(),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setIndex(index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey[600],

        items: [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_emotions), label: ''),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.red[800]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(radius: 30, child: Icon(Icons.person)),
                SizedBox(height: 10),
                Text(
                  "${userData["username"]}",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${userData["email"]}",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Administrator'),
            onTap: () {
              Navigator.pop(context);
              SmoothRoute(
                context: context,
                child: RegisterScreen(roleId: 1),
              ).route();
            },
          ),
          ListTile(
            leading: Icon(Icons.people),
            title: Text('Edit Profile'),
            onTap: () {
              Navigator.of(context).pop();
              Map<String, dynamic> userData = {
                'id': user!.id,
                'username': user.username,
                'email': user.email,
                'mobile_no': user.mobileNo,
                'created_at': user.createdAt,
                "birth_date": user.dateOfBirth.toString(),
                "address": user.address,
                "role": user.role,
                "role_id": user.roleId,
              };
              // Navigate to this screen from user list
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfileUpdateScreen(
                    userData: userData, // Pass the user data from your list
                  ),
                ),
              );
            },
          ),

          SizedBox(height: 50),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              authProvider.clearAuthData();
              Navigator.pushReplacementNamed(context, '/splash');
            },
          ),
        ],
      ),
    );
  }
}
