import 'package:flutter/material.dart';
import 'package:hnhsmind_care/app_theme.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../provider/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    // Delay the navigation to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToNext();
    });
  }

  void _navigateToNext() async {
    // Correct way to access provider in initState
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Initialize auth provider
    await authProvider.initialize();

    // Use the same instance that was initialized
    final userData = await authProvider.getAuthData();

    // authProvider.clearAuthData();

    await Future.delayed(Duration(seconds: 3));
    if (mounted) {
      if (userData == null) {
        Navigator.pushReplacementNamed(context, '/onboarding');
        return;
      }

      if (userData["role_id"].toString() == "2") {
        Navigator.pushReplacementNamed(context, '/users');
      } else {
        Navigator.pushReplacementNamed(context, '/admin');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
            height: double.infinity,
            padding: EdgeInsets.all(10),
            width: MediaQuery.of(context).size.width / 1.8,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/heartbeat.json',
                  controller: _controller,
                  onLoaded: (composition) {
                    _controller
                      ..duration = composition.duration
                      ..forward();
                  },
                  height: 180,
                  fit: BoxFit.cover,
                ),
                SizedBox(height: 32),
                Text(
                  'HNHS Mental Health',
                  style: GoogleFonts.poppins(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black.withOpacity(0.2),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Supporting Your Mental Wellness',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 50),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
