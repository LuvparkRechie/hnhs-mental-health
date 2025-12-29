import 'dart:async';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:hnhsmind_care/pages/registration_screen.dart';
import 'package:hnhsmind_care/service/notification_sqllite.dart';
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
import 'provider/notification_controller.dart';
import 'service/cleaner_service.dart';

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

  // Fetch admin alerts from server
  final alertList = await getAdminNotif(userId);

  if (alertList.isEmpty) {
    await AdminAlertDB.instance.deleteAll();
    return;
  }

  // Extract current valid server alert IDs
  List<int> validIds = alertList
      .map<int>((e) => int.parse(e["id"].toString()))
      .toList();

  // STEP 1: Load local stored IDs
  final db = await AdminAlertDB.instance.database;
  final localRows = await db.query("admin_alerts");
  List<int> localIds = localRows.map((e) => e["id"] as int).toList();

  // STEP 2: Delete alerts in SQLite that no longer exist on server
  final toRemove = localIds.where((id) => !validIds.contains(id)).toList();

  for (var removeId in toRemove) {
    await db.delete("admin_alerts", where: "id = ?", whereArgs: [removeId]);
  }

  // STEP 3: Loop through server alerts and notify new ones
  for (final alert in alertList) {
    final alertId = int.parse(alert["id"].toString());

    // Check if exists in SQLite
    final exists = await AdminAlertDB.instance.getAlert(alertId);

    if (exists != null) {
      continue;
    }

    // Send notification ONCE
    final notifId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notifId,
        channelKey: 'alerts',
        title: alert["user_message"],
        body: alert["description"],
        wakeUpScreen: true,
        autoDismissible: true,
      ),
    );

    // Save alert into SQLite to prevent duplicates
    await AdminAlertDB.instance.insertAlert({
      "id": alertId,
      "user_message": alert["user_message"],
      "description": alert["description"],
    });
  }
}

// =====================================================
// MAIN ENTRY
// =====================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await AdminAlertDB.instance.database;
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
          create: (_) => AppDataProvider()..initializeSampleData(),
        ),
      ],
      child: MyApp(key: myAppKey),
    ),
  );
}

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

  Future<void> initBackgroundAlarm() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = await authProvider.getAuthData();
    if (user == null) {
      return;
    }

    final userId = user["id"].toString();
    final roleId = int.parse(user["role_id"].toString());

    if (roleId != 1) {
      return;
    }

    await AndroidAlarmManager.periodic(
      const Duration(seconds: 5),
      888, // unique ID
      backgroundFunc,
      startAt: DateTime.now(),
      exact: true,
      wakeup: true,
      params: {"userId": userId, "role": roleId},
    );
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
