import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/notification.dart';
import '../screens/book_detail_screen.dart';
import '../screens/main_screen.dart';
import '../screens/messages_hub_screen.dart';
import '../screens/order_list_screen.dart';
import '../screens/podcast_hub_screen.dart';
import '../screens/search_screen.dart';
import '../screens/support_chat_screen.dart';
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
                  title: notification?.title ?? '商品資訊',
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
      case 'support':
        // 舊版群發曾誤標 target=support；有 broadcast 標記則改開通知分頁。
        if (_isBroadcast(data)) {
          _openMessagesHub(tab: 1);
          break;
        }
        final convId = _parseConversationId(data, payload);
        if (convId != null) {
          navigator.push(
            MaterialPageRoute(
              builder: (_) => SupportChatScreen(conversationId: convId),
            ),
          );
        } else {
          _openMessagesHub(tab: 0);
        }
        break;
      case 'home':
        navigator.popUntil((route) => route.isFirst);
        break;
      case 'notifications':
        _openMessagesHub(tab: 1);
        break;
      default:
        break;
    }
  }

  static void _openMessagesHub({required int tab}) {
    final navigator = NavigationService.navigatorKey.currentState;
    if (MainScreen.navKey.currentState != null) {
      navigator?.popUntil((route) => route.isFirst);
      MainScreen.openMessages(tab: tab);
      return;
    }
    navigator?.push(
      MaterialPageRoute(
        builder: (_) => MessagesHubScreen(initialTab: tab),
      ),
    );
  }

  static bool _isBroadcast(Map<String, dynamic> data) {
    final flag = data['broadcast'];
    if (flag == true || flag == 1) return true;
    final s = flag?.toString().trim().toLowerCase();
    return s == '1' || s == 'true' || s == 'yes';
  }

  static int? _parseConversationId(
    Map<String, dynamic> data,
    String? payload,
  ) {
    final direct = data['conversation_id'] ?? data['conversationId'];
    final fromDirect = int.tryParse(direct?.toString() ?? '');
    if (fromDirect != null) return fromDirect;

    if (payload == null || payload.isEmpty) return null;
    final asInt = int.tryParse(payload);
    if (asInt != null) return asInt;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        final id = decoded['conversation_id'] ?? decoded['conversationId'];
        return int.tryParse(id?.toString() ?? '');
      }
    } catch (_) {}
    return null;
  }
}
