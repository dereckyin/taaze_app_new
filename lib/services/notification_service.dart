import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../providers/notification_provider.dart';
import '../models/notification.dart' as model;

/// Background message handler must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize({NotificationProvider? provider}) async {
    if (_initialized) return;

    await Firebase.initializeApp();

    // Local notifications setup
    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const darwinInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );
    await _local.initialize(initSettings);

    // Request permissions
    await _requestPermissions();

    // iOS foreground presentation
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Token
    final token = await _messaging.getToken();
    if (kDebugMode) debugPrint('FCM token: $token');

    // Listen to token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      if (kDebugMode) debugPrint('FCM token refreshed: $newToken');
      // TODO: send to backend
    });

    // Foreground messages -> show local notification and push to provider
    FirebaseMessaging.onMessage.listen((message) async {
      await _showLocal(message);
      _pushToProvider(provider, message);
    });

    // Tapped notifications
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _pushToProvider(provider, message);
    });

    // Initial message when launched from terminated state
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _pushToProvider(provider, initialMessage);
    }

    _initialized = true;
  }

  Future<NotificationSettings> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      sound: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
    return settings;
  }

  Future<void> _showLocal(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'General Notifications',
      channelDescription: 'General notifications for the bookstore app',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data['payload'],
    );
  }

  void _pushToProvider(NotificationProvider? provider, RemoteMessage message) {
    if (provider == null) return;
    final n = model.AppNotification(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? '通知',
      body: message.notification?.body ?? '',
      type: model.NotificationType.general,
      createdAt: DateTime.now(),
    );
    provider.addNotification(n);
  }
}
