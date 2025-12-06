import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:hnhsmind_care/api_key/api_key.dart';

class NotificationController {
  static ReceivePort? receivePort;

  static Future<void> initializeLocalNotifications() async {
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: 'alerts',
        channelName: 'Alerts',
        channelDescription: 'General Alerts',
        importance: NotificationImportance.High,
        defaultColor: Colors.deepPurple,
        ledColor: Colors.deepPurple,
      ),
    ], debug: true);
  }

  static Future<void> initializeIsolateReceivePort() async {
    receivePort = ReceivePort("notification_action_port")
      ..listen((event) {
        print("🔔 Notification action: $event");
      });

    IsolateNameServer.registerPortWithName(
      receivePort!.sendPort,
      'notification_action_port',
    );
  }

  static Future<void> startListeningNotificationEvents() async {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceived,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> onActionReceived(ReceivedAction action) async {
    print("NOTIFICATION ACTION RECEIVED: ${action.payload}");
  }
}

Future<dynamic> getAdminNotif(String userId) async {
  try {
    final api = ApiPhp(tableName: 'admin_alerts');

    final response = await api.select();
    // Make sure admin alert exists
    if (response["data"].isNotEmpty) {
      return response["data"]; // return first alert
    }

    return [];
  } catch (e) {
    print("❌ Error fetching admin alert: $e");
    return [];
  }
}
