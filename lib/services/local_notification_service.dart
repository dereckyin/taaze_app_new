import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../providers/notification_provider.dart';
import '../models/notification.dart' as model;
import 'navigation_service.dart';
import '../screens/notifications_screen.dart';

class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize({NotificationProvider? provider}) async {
    if (_initialized) return;

    // 初始化本地通知
    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      // 預設前景行為（iOS 14+ 還可控制 banner/list）    
      defaultPresentAlert: true,    
      defaultPresentSound: true,    
      defaultPresentBadge: true,    
      defaultPresentBanner: true,    
      defaultPresentList: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 請求權限
    await _requestPermissions();

    _initialized = true;
    if (kDebugMode) debugPrint('Local notification service initialized');
  }

  Future<void> _requestPermissions() async {
    // Android 13+ 需要明確請求通知權限
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.requestNotificationsPermission();
    }
    
    // iOS 需要請求通知權限
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final result = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (kDebugMode) {
        debugPrint('iOS notification permission result: $result');
      }
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // 處理通知點擊
    final navigator = NavigationService.navigatorKey.currentState;
    if (navigator != null) {
      navigator.push(
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      );
    }
  }

  /// 顯示本地通知
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    if (!_initialized) {
      if (kDebugMode) debugPrint('Local notification service not initialized');
      return;
    }

    if (kDebugMode) {
      debugPrint('準備發送本地通知: $title - $body');
    }

    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'General Notifications',
      channelDescription: 'General notifications for the bookstore app',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      badgeNumber: 1,
      interruptionLevel: InterruptionLevel.active,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.show(
        id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        details,
        payload: payload,
      );
      if (kDebugMode) {
        debugPrint('本地通知發送成功');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('發送本地通知失敗: $e');
      }
      rethrow;
    }
  }

  /// 顯示預定通知
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_initialized) {
      if (kDebugMode) debugPrint('Local notification service not initialized');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'scheduled_channel',
      'Scheduled Notifications',
      channelDescription: 'Scheduled notifications for the bookstore app',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 轉換為時區時間
    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      details,
      payload: payload,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// 取消通知
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// 獲取待處理的通知
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }

  /// 檢查通知權限狀態
  Future<bool> checkNotificationPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final result = await iosPlugin?.checkPermissions();
      if (kDebugMode) {
        debugPrint('iOS notification permissions: $result');
      }
      return result?.isEnabled ?? false;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final result = await androidPlugin?.areNotificationsEnabled();
      if (kDebugMode) {
        debugPrint('Android notification permissions: $result');
      }
      return result ?? false;
    }
    return false;
  }

  /// 模擬接收通知（用於測試）
  void simulateNotification({
    required String title,
    required String body,
    NotificationProvider? provider,
  }) async {
    if (kDebugMode) {
      debugPrint('=== 開始測試本地通知 ===');
      debugPrint('標題: $title');
      debugPrint('內容: $body');
    }
    
    // 檢查權限狀態
    final hasPermission = await checkNotificationPermissions();
    if (kDebugMode) {
      debugPrint('通知權限狀態: $hasPermission');
    }
    
    // 檢查服務是否已初始化
    if (kDebugMode) {
      debugPrint('通知服務已初始化: $_initialized');
    }
    
    // 顯示本地通知
    try {
      await showNotification(title: title, body: body);
      if (kDebugMode) {
        debugPrint('本地通知已發送');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('發送本地通知時發生錯誤: $e');
      }
    }

    // 添加到通知列表
    if (provider != null) {
      final notification = model.AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        type: model.NotificationType.general,
        createdAt: DateTime.now(),
      );
      provider.addNotification(notification);
      if (kDebugMode) {
        debugPrint('通知已添加到列表');
      }
    }
    
    if (kDebugMode) {
      debugPrint('=== 測試本地通知完成 ===');
    }
  }
}
