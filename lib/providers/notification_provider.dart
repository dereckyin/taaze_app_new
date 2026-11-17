import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification.dart';
import '../services/notification_api_service.dart';

class NotificationProvider with ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  String? _authToken;

  static const _localInboxKey = 'local_notification_inbox';

  /// 通知匣不顯示客服對話推播（那些只走「客服」分頁）。
  List<AppNotification> get notifications =>
      _notifications.where((n) => !_isSupportThreadPush(n)).toList();
  List<AppNotification> get unreadNotifications =>
      notifications.where((n) => !n.isRead).toList();
  int get unreadCount => unreadNotifications.length;
  bool get isLoading => _isLoading;
  String? get error => _error;

  NotificationProvider() {
    _loadLocalInbox();
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Future<void> refresh({String? authToken}) async {
    if (authToken != null) {
      _authToken = authToken;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_authToken != null && _authToken!.isNotEmpty) {
        final remote = await NotificationApiService.fetchInbox(
          authToken: _authToken!,
        );
        final localOnly = await _loadLocalOnly();
        _notifications = _mergeNotifications(remote, localOnly)
            .where((n) => !_isSupportThreadPush(n))
            .toList();
        await _persistLocalInbox();
      } else {
        // 未登入不顯示上一帳號本機匣
        _notifications = [];
      }
      _error = null;
    } catch (e) {
      _error = '載入通知失敗：${e.toString()}';
      if (_notifications.isEmpty) {
        _notifications = await _loadLocalOnly();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<AppNotification> _mergeNotifications(
    List<AppNotification> remote,
    List<AppNotification> local,
  ) {
    final seen = <String>{};
    final merged = <AppNotification>[];
    for (final n in [...remote, ...local]) {
      if (seen.add(n.id)) {
        merged.add(n);
      }
    }
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }

  Future<List<AppNotification>> _loadLocalOnly() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localInboxKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _loadLocalInbox() async {
    _notifications = await _loadLocalOnly();
    notifyListeners();
  }

  Future<void> _persistLocalInbox() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_notifications.map((n) => n.toJson()).toList());
    await prefs.setString(_localInboxKey, encoded);
  }

  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index < 0) return;
    _notifications[index] = _notifications[index].copyWith(isRead: true);
    notifyListeners();

    if (_authToken != null) {
      try {
        await NotificationApiService.markInboxRead(
          authToken: _authToken!,
          notificationIds: [notificationId],
        );
      } catch (_) {}
    }
    await _persistLocalInbox();
  }

  Future<void> markAllAsRead() async {
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    notifyListeners();

    if (_authToken != null) {
      try {
        await NotificationApiService.markInboxRead(
          authToken: _authToken!,
          markAll: true,
        );
      } catch (_) {}
    }
    await _persistLocalInbox();
  }

  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();

    if (_authToken != null) {
      try {
        await NotificationApiService.deleteInboxItem(
          authToken: _authToken!,
          notificationId: notificationId,
        );
      } catch (_) {}
    }
    await _persistLocalInbox();
  }

  Future<void> addNotification(AppNotification notification) async {
    // 客服回覆只應出現在「客服」分頁，不要塞進通知匣。
    if (_isSupportThreadPush(notification)) return;
    if (_notifications.any((n) => n.id == notification.id)) return;
    _notifications.insert(0, notification);
    if (_notifications.length > 100) {
      _notifications = _notifications.take(100).toList();
    }
    notifyListeners();
    await _persistLocalInbox();
  }

  /// 登出時清空記憶體與本機匣，避免未登入仍看到上一帳號訊息。
  Future<void> clearSession() async {
    _notifications = [];
    _authToken = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localInboxKey);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  static bool _isSupportThreadPush(AppNotification n) {
    final data = n.data;
    if (data != null) {
      final broadcast = data['broadcast']?.toString().trim().toLowerCase();
      if (broadcast == '1' ||
          broadcast == 'true' ||
          broadcast == 'yes') {
        return false;
      }
      final type = data['type']?.toString();
      final target = data['target']?.toString();
      if (type == 'support' || target == 'support') return true;
      if (data.containsKey('conversation_id') ||
          data.containsKey('conversationId')) {
        return true;
      }
    }
    return n.type == NotificationType.support;
  }
}
