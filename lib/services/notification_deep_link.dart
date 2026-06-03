import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/notification.dart';
import '../screens/book_detail_screen.dart';
import '../screens/order_list_screen.dart';
import '../screens/podcast_hub_screen.dart';
import '../screens/search_screen.dart';
import 'navigation_service.dart';

/// Handles push notification deep links.
/// FCM data: type, target, payload (all strings).
class NotificationDeepLink {
  static void handle(
    Map<String, dynamic>? data, {
    AppNotification? notification,
  }) {
    if (data == null || data.isEmpty) return;
    final navigator = NavigationService.navigatorKey.currentState;
    if (navigator == null) return;

    final target = (data['target'] as String?)?.trim() ?? 'notifications';
    final payload = data['payload'] as String?;

    switch (target) {
      case 'book':
        final prodId = payload ?? data['prod_id'] as String?;
        if (prodId != null && prodId.isNotEmpty) {
          navigator.push(
            MaterialPageRoute(
              builder: (_) => BookDetailScreen(
                book: Book.minimal(
                  id: prodId,
                  title: notification?.title ?? '書籍詳情',
                ),
              ),
            ),
          );
        }
        break;
      case 'orders':
        navigator.push(
          MaterialPageRoute(builder: (_) => const OrderListScreen()),
        );
        break;
      case 'search':
        final query = payload ?? '';
        if (query.isNotEmpty) {
          navigator.push(
            MaterialPageRoute(
              builder: (_) => SearchScreen(query: query),
            ),
          );
        }
        break;
      case 'podcast':
        navigator.push(
          MaterialPageRoute(builder: (_) => const PodcastHubScreen()),
        );
        break;
      case 'home':
        navigator.popUntil((route) => route.isFirst);
        break;
      case 'notifications':
      default:
        break;
    }
  }
}
