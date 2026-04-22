import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_client.dart';
import '../../main.dart';
import '../../features/chat/presentation/pages/chat_page.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    // Request permissions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log('User granted permission');
    } else {
      log('User declined or has not accepted permission');
    }

    // Get FCM Token
    String? token = await _fcm.getToken();
    if (token != null) {
      log("FCM Token: $token");
      await _saveTokenToBackend(token);
    }

    // Listen for token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      _saveTokenToBackend(newToken);
    });

    // Handle Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Got a message whilst in the foreground!');
      log('Message data: ${message.data}');

      if (message.notification != null) {
        log('Message also contained a notification: ${message.notification?.title}');
        // In a real app, we'd use flutter_local_notifications here.
        // For now, we've implemented the listener for system-level tray integration.
      }
    });

    // Handle Background & Terminated states
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('Message clicked! Navigate to: ${message.data['type']}');
      _handleNavigation(message);
    });
  }

  // Static method to handle initial message when app is opened from terminated state
  Future<void> handleInitialMessage() async {
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      log("App opened from terminated state via notification");
      _handleNavigation(initialMessage);
    }
  }

  void _handleNavigation(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];

    if (type == 'chat') {
      final userId = data['userId'];
      final userName = data['userName'] ?? 'Chat';
      final profileUrl = data['profileUrl'] ?? '';
      
      if (userId != null) {
        FloqApp.navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ChatPage(
              chatWith: userName,
              userId: userId,
              profileUrl: profileUrl,
            ),
          ),
        );
      }
    } else if (type == 'post') {
      // Future: Navigate to specific post
    }
  }

  Future<void> _saveTokenToBackend(String token) async {
    try {
      final apiClient = ApiClient();
      await apiClient.dio.patch('/users/update-fcm-token', data: {'fcmToken': token});
      log("FCM Token synced with backend");
    } catch (e) {
      log("Error syncing FCM token: $e");
    }
  }

  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    log("Handling a background message: ${message.messageId}");
  }
}
