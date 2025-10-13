import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../models/notification.dart' as model;
import 'notification_api_service.dart';
import 'navigation_service.dart';
import '../screens/notifications_screen.dart';

/// Background message handler must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  late FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  String? _currentToken;

  Future<void> initialize({
    NotificationProvider? provider,
    AuthProvider? authProvider,
  }) async {
    if (_initialized) return;

    await Firebase.initializeApp();
    _messaging = FirebaseMessaging.instance;

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
    _currentToken = token;
    if (kDebugMode) debugPrint('FCM token: $token');

    // Register token to backend if logged in
    if (token != null &&
        authProvider?.authToken != null &&
        authProvider?.user != null) {
      await _registerTokenToBackend(token, authProvider!);
    }

    // Listen to token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      if (kDebugMode) debugPrint('FCM token refreshed: $newToken');
      _currentToken = newToken;
      if (authProvider?.authToken != null && authProvider?.user != null) {
        await _registerTokenToBackend(newToken, authProvider!);
      }
    });

    // Foreground messages -> show local notification and push to provider
    FirebaseMessaging.onMessage.listen((message) async {
      await _showLocal(message);
      _pushToProvider(provider, message);
    });

    // Tapped notifications
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _pushToProvider(provider, message);
      _handleNavigationFromData(message.data);
    });

    // Initial message when launched from terminated state
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _pushToProvider(provider, initialMessage);
      _handleNavigationFromData(initialMessage.data);
    }

    _initialized = true;
  }

  void _handleNavigationFromData(Map<String, dynamic> data) {
    final target = data['target'] as String?;
    if (target == null || target.isEmpty) return;
    // Minimal handling: go to Notifications tab/screen
    final navigator = NavigationService.navigatorKey.currentState;
    if (navigator == null) return;
    navigator.push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  Future<void> _registerTokenToBackend(
    String token,
    AuthProvider authProvider,
  ) async {
    try {
      final meta = await _collectDeviceMeta();
      await NotificationApiService.registerToken(
        token: token,
        platform: Platform.isIOS ? 'ios' : 'android',
        appVersion: meta.appVersion,
        deviceModel: meta.deviceModel,
        locale: meta.locale,
        authToken: authProvider.authToken!,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Register token failed: $e');
    }
  }

  Future<void> revokeCurrentToken(AuthProvider authProvider) async {
    final token = _currentToken ?? await _messaging.getToken();
    if (token == null) return;
    try {
      await NotificationApiService.revokeToken(
        token: token,
        authToken: authProvider.authToken!,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Revoke token failed: $e');
    }
  }

  Future<_DeviceMeta> _collectDeviceMeta() async {
    final package = await PackageInfo.fromPlatform();
    final deviceInfo = DeviceInfoPlugin();
    String deviceModel = '';
    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      deviceModel = '${info.manufacturer} ${info.model}';
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      deviceModel = info.utsname.machine;
    }
    return _DeviceMeta(
      appVersion: package.version,
      deviceModel: deviceModel,
      locale: WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag(),
    );
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

class _DeviceMeta {
  final String appVersion;
  final String deviceModel;
  final String locale;
  _DeviceMeta({
    required this.appVersion,
    required this.deviceModel,
    required this.locale,
  });
}
