import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

// ******************************************************
// REQUIRED: Global key for navigating outside of widget context (used by deep linking)
// NOTE: This key must be defined once and used everywhere navigation is needed.
// It's defined here for centralized access.
// ******************************************************
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// A top-level function required for handling notification taps.
/// It uses the global navigatorKey to perform navigation (deep linking).
void onSelectNotification(String? payload) {
  if (payload != null) {
    // Expected payload format: "/chat?chatRoomId=xxx&senderId=yyy"
    final uri = Uri.parse(payload);

    // Check if the path is the intended chat route
    if (uri.path == '/chat') {
      final chatRoomId = uri.queryParameters['chatRoomId'];
      final senderId = uri.queryParameters['senderId'];

      if (chatRoomId != null && senderId != null) {
        // Navigate to the chat screen using the extracted data
        // Check if current state exists before pushing
        navigatorKey.currentState?.pushNamed(
          '/chat',
          arguments: {
            'chatRoomId': chatRoomId,
            'senderId': senderId,
          },
        );
      }
    }
  }
}

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  /// Initializes the local notification plugin settings for Android and iOS.
  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      // Handle notification tap response
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Use the top-level function defined above
        onSelectNotification(response.payload);
      },
    );
  }

  /// Manually requests permissions (needed for iOS and Android 13+).
  Future<void> requestPermissions() async {
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Displays a local notification using the provided details.
  /// This is called when a Firebase message is received in the FOREGROUND.
  Future<void> showNotification(
      int id,
      String title,
      String body,
      String payload,
      ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'chat_channel_id',
      'Chat Notifications',
      channelDescription: 'Notifications for new chat messages.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
    DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }
}
