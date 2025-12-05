// Update your main.dart
import 'package:flutter/material.dart';
import 'package:hnhsmind_care/pages/registration_screen.dart';
import 'package:hnhsmind_care/pages/users/users_mood_tracker.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'database_provider/database_provider.dart';
import 'pages/admin_screen/admin_dashboard_screen.dart';
import 'pages/login.dart';
import 'pages/client_screen/client_screen.dart';
import 'pages/onboarding.dart';
import 'pages/splash_screen.dart';
import 'pages/users/booking_appointment.dart';
import 'pages/users/daily_journal.dart';
import 'pages/users/users_dashboard.dart';
import 'provider/auth_provider.dart';
import 'provider/chat_provider.dart';
import 'service/cleaner_service.dart';
import 'suicide_detection_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Start the appointment cleaner
  final cleanerService = AppointmentCleanerService();
  cleanerService.start(); // Runs every 60 seconds by default
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(
          create: (context) =>
              ChatProvider(detectionService: SuicideDetectionService()),
        ),
        ChangeNotifierProvider(
          // ADD THIS PROVIDER
          create: (context) => AppDataProvider()..initializeSampleData(),
        ),
        ChangeNotifierProvider(create: (_) => AppDataProvider()),
      ],
      child: MaterialApp(
        title: 'HNHS Mental Health',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => SplashScreen(),
          '/onboarding': (context) => OnboardingScreen(),
          '/auth': (context) => AuthScreen(),
          '/client': (context) => ClientHomeScreen(),
          '/users': (context) => UserDashboard(),
          '/admin': (context) => AdminDashboard(),
          '/register': (context) => RegisterScreen(),
          '/bookAppointment': (context) => BookAppointmentScreen(),
          '/userJournal': (context) => DailyJournalScreen(),
          '/usersMoodTracker': (context) => MoodTrackerScreen(),
        },
      ),
    );
  }
}
