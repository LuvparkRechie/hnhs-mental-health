import 'dart:async';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:hnhsmind_care/pages/registration_screen.dart';
import 'package:permission_handler/permission_handler.dart'
    hide PermissionStatus;
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'app_theme.dart';
import 'database_provider/database_provider.dart';
import 'pages/admin_screen/admin_dashboard_screen.dart';
import 'pages/client_screen/client_screen.dart';
import 'pages/login.dart';
import 'pages/onboarding.dart';
import 'pages/splash_screen.dart';
import 'pages/users/booking_appointment.dart';
import 'pages/users/daily_journal.dart';
import 'pages/users/users_dashboard.dart';
import 'pages/users/users_mood_tracker.dart';
import 'provider/auth_provider.dart';
import 'provider/chat_provider.dart';
import 'provider/notification_controller.dart';
import 'service/cleaner_service.dart';
import 'suicide_detection_service.dart';

// =====================================================
// GLOBAL KEY
// =====================================================
final GlobalKey<MyAppState> myAppKey = GlobalKey<MyAppState>();

// =====================================================
// BACKGROUND ALARM CALLBACK
// =====================================================
@pragma('vm:entry-point')
Future<void> backgroundFunc(int alarmId, Map<String, dynamic> params) async {
  WidgetsFlutterBinding.ensureInitialized();

  final userId = params["userId"];
  final role = params["role"];

  // Only allow admin users
  if (role != 1) {
    return;
  }

  // Fetch last admin alert
  final alert = await getAdminNotif(userId);
  if (alert.isEmpty) {
    return;
  }
  for (int i = 0; i < alert.length; i++) {
    final notifId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    print("aiii ${alert[i]}");
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notifId,
        channelKey: 'alerts',
        title: alert[i]["user_message"] ?? "New Admin Alert",
        body: alert[i]["description"] ?? "You have a new admin alert.",
        wakeUpScreen: true,
        autoDismissible: true,
      ),
    );
  }
}

// =====================================================
// MAIN ENTRY
// =====================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  await AndroidAlarmManager.initialize();

  // Request notification permission
  final status = await Permission.notification.status;
  if (status.isDenied) {
    await Permission.notification.request();
  }

  bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowed) {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  NotificationController.initializeLocalNotifications();

  // Cleaner service
  AppointmentCleanerService().start();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) =>
              ChatProvider(detectionService: SuicideDetectionService()),
        ),
        ChangeNotifierProvider(
          create: (_) => AppDataProvider()..initializeSampleData(),
        ),
      ],
      child: MyApp(key: myAppKey),
    ),
  );
}

// =====================================================
// APP ROOT
// =====================================================
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Delay to ensure Provider is ready
    Future.microtask(() => initBackgroundAlarm());
  }

  // =====================================================
  // ADMIN-ONLY BACKGROUND ALARM
  // =====================================================
  Future<void> initBackgroundAlarm() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = await authProvider.getAuthData();
    print("⚠user initbackground $user");
    if (user == null) {
      print("⚠ No logged-in user. Alarm not started.");
      return;
    }

    final userId = user["id"].toString();
    final roleId = int.parse(user["role_id"].toString());

    if (roleId != 1) {
      print("⛔ Alarm not started. User is NOT admin.");
      return;
    }

    print("🔥 Starting admin background alarm...");

    await AndroidAlarmManager.periodic(
      const Duration(seconds: 5),
      888, // unique ID
      backgroundFunc,
      startAt: DateTime.now(),
      exact: true,
      wakeup: true,
      params: {"userId": userId, "role": roleId},
    );

    print("✅ Admin alarm started every 5 seconds!");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
    );
  }
}
