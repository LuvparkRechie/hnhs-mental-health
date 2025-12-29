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
  static Future<void> onActionReceived(ReceivedAction action) async {}
}

Future<dynamic> getAdminNotif(String userId) async {
  try {
    final api = ApiPhp(tableName: 'admin_alerts');

    // Compute today's date
    final today = DateTime.now();
    final todayStr =
        "${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final Map<String, dynamic> joinConfig = {
      'join': 'LEFT JOIN users ON admin_alerts.user_id = users.id',
      'columns': '''
          admin_alerts.*,  
          users.mobile_no,
          users.username
        ''',

      // FIXED: Use AND (NOT comma)
      // FIXED: Correct placeholders
      'where':
          'admin_alerts.is_settled = ? AND DATE(admin_alerts.created_date) = ?',

      // FIXED: Must match EXACT number of ? placeholders
      'where_params': ['N', todayStr],

      'orderBy': 'admin_alerts.created_date DESC',
    };

    final response = await api.selectWithJoin(joinConfig);

    if (response["data"] != null && response["data"].isNotEmpty) {
      return response["data"];
    } else {
      return [];
    }
  } catch (e) {
    return {'success': false, 'message': 'Error: $e'};
  }
}
