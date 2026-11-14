import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/support.dart';
import '../services/support_api_service.dart';

class SupportProvider extends ChangeNotifier {
  List<SupportConversation> _conversations = [];
  final Map<int, List<SupportMessage>> _messagesByConv = {};
  int _unreadCount = 0;
  bool _loadingList = false;
  bool _loadingMessages = false;
  bool _sending = false;
  String? _error;
  int? _activeConvId;
  Timer? _pollTimer;

  List<SupportConversation> get conversations =>
      List.unmodifiable(_conversations);
  int get unreadCount => _unreadCount;
  bool get loadingList => _loadingList;
  bool get loadingMessages => _loadingMessages;
  bool get sending => _sending;
  String? get error => _error;
  int? get activeConvId => _activeConvId;

  List<SupportMessage> messagesFor(int convId) =>
      List.unmodifiable(_messagesByConv[convId] ?? const []);

  Future<void> refreshConversations(String authToken) async {
    _loadingList = true;
    _error = null;
    notifyListeners();
    try {
      _conversations =
          await SupportApiService.listConversations(authToken: authToken);
      _unreadCount =
          await SupportApiService.unreadCount(authToken: authToken);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingList = false;
      notifyListeners();
    }
  }

  Future<void> refreshUnreadCount(String authToken) async {
    try {
      _unreadCount =
          await SupportApiService.unreadCount(authToken: authToken);
      notifyListeners();
    } catch (_) {}
  }

  Future<SupportConversation?> createConversation({
    required String authToken,
    required String body,
    String? subject,
    String? category,
    bool handoff = false,
  }) async {
    _sending = true;
    _error = null;
    notifyListeners();
    try {
      final conv = await SupportApiService.createConversation(
        authToken: authToken,
        subject: subject,
        body: body,
        category: category,
        handoff: handoff,
      );
      await refreshConversations(authToken);
      return conv;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages({
    required String authToken,
    required int convId,
    bool markRead = true,
  }) async {
    _activeConvId = convId;
    _loadingMessages = true;
    _error = null;
    notifyListeners();
    try {
      final messages = await SupportApiService.listMessages(
        authToken: authToken,
        convId: convId,
      );
      _messagesByConv[convId] = messages;
      if (markRead) {
        await SupportApiService.markRead(
          authToken: authToken,
          convId: convId,
        );
        await refreshUnreadCount(authToken);
        _conversations = _conversations
            .map(
              (c) => c.convId == convId
                  ? SupportConversation(
                      convId: c.convId,
                      custId: c.custId,
                      subject: c.subject,
                      category: c.category,
                      status: c.status,
                      assignedAgent: c.assignedAgent,
                      unreadCustomer: 0,
                      unreadAgent: c.unreadAgent,
                      lastMessageAt: c.lastMessageAt,
                      createdAt: c.createdAt,
                      updatedAt: c.updatedAt,
                      lastMessagePreview: c.lastMessagePreview,
                    )
                  : c,
            )
            .toList();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingMessages = false;
      notifyListeners();
    }
  }

  void startPolling({
    required String authToken,
    required int convId,
    Duration interval = const Duration(seconds: 5),
  }) {
    stopPolling();
    _activeConvId = convId;
    _pollTimer = Timer.periodic(interval, (_) {
      _pollNewMessages(authToken: authToken, convId: convId);
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _pollNewMessages({
    required String authToken,
    required int convId,
  }) async {
    if (_activeConvId != convId) return;
    final existing = _messagesByConv[convId] ?? [];
    final afterId = existing.isEmpty ? null : existing.last.msgId;
    try {
      final newer = await SupportApiService.listMessages(
        authToken: authToken,
        convId: convId,
        afterId: afterId,
      );
      if (newer.isEmpty) return;
      final merged = [...existing];
      final known = existing.map((m) => m.msgId).toSet();
      for (final m in newer) {
        if (!known.contains(m.msgId)) {
          merged.add(m);
        }
      }
      merged.sort((a, b) => a.msgId.compareTo(b.msgId));
      _messagesByConv[convId] = merged;
      await SupportApiService.markRead(authToken: authToken, convId: convId);
      await refreshUnreadCount(authToken);
      notifyListeners();
    } catch (_) {
      // Keep silent on poll errors to avoid UI flicker
    }
  }

  Future<bool> sendMessage({
    required String authToken,
    required int convId,
    required String body,
  }) async {
    final text = body.trim();
    if (text.isEmpty) return false;
    _sending = true;
    _error = null;
    notifyListeners();
    try {
      final message = await SupportApiService.sendMessage(
        authToken: authToken,
        convId: convId,
        body: text,
      );
      _appendMessage(convId, message);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  Future<bool> sendImage({
    required String authToken,
    required int convId,
    required String filePath,
    required String filename,
    String contentType = 'image/jpeg',
  }) async {
    _sending = true;
    _error = null;
    notifyListeners();
    try {
      final message = await SupportApiService.uploadImageMessage(
        authToken: authToken,
        convId: convId,
        filePath: filePath,
        filename: filename,
        contentType: contentType,
      );
      _appendMessage(convId, message);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  Future<bool> closeConversation({
    required String authToken,
    required int convId,
  }) async {
    _error = null;
    try {
      final conv = await SupportApiService.closeConversation(
        authToken: authToken,
        convId: convId,
      );
      _conversations = _conversations
          .map((c) => c.convId == convId ? conv : c)
          .toList();
      if (!_conversations.any((c) => c.convId == convId)) {
        _conversations = [conv, ..._conversations];
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _appendMessage(int convId, SupportMessage message) {
    final existing = _messagesByConv[convId] ?? [];
    if (!existing.any((m) => m.msgId == message.msgId)) {
      _messagesByConv[convId] = [...existing, message];
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
