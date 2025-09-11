import 'package:flutter/foundation.dart';
import '../models/notification.dart';

class NotificationProvider with ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  List<AppNotification> get unreadNotifications => 
      _notifications.where((notification) => !notification.isRead).toList();
  int get unreadCount => unreadNotifications.length;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 模擬通知資料
  final List<AppNotification> _mockNotifications = [
    AppNotification(
      id: '1',
      title: '歡迎來到書店！',
      body: '感謝您註冊我們的書店應用程式，享受購物樂趣！',
      type: NotificationType.general,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AppNotification(
      id: '2',
      title: '限時優惠',
      body: '程式設計類書籍全系列8折優惠，僅限今日！',
      type: NotificationType.promotion,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    AppNotification(
      id: '3',
      title: '訂單確認',
      body: '您的訂單 #12345 已確認，正在準備出貨。',
      type: NotificationType.order,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    AppNotification(
      id: '4',
      title: '推薦書籍',
      body: '基於您的興趣，我們為您推薦《Flutter開發實戰》',
      type: NotificationType.bookRecommendation,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  NotificationProvider() {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 模擬API調用延遲
      await Future.delayed(const Duration(milliseconds: 500));
      
      _notifications = List.from(_mockNotifications);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = '載入通知失敗：${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index >= 0) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void markAllAsRead() {
    _notifications = _notifications.map((notification) {
      return notification.copyWith(isRead: true);
    }).toList();
    notifyListeners();
  }

  void deleteNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
