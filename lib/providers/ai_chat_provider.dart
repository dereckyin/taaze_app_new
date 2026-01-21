import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../screens/ai_chat_screen.dart';
import '../services/search_service.dart';
import '../models/book.dart';

class AiChatProvider with ChangeNotifier {
  final List<ChatMessage> _messages = [];
  final List<String> _suggestedPrompts = [];
  bool _isLoading = false;
  String? _activeProductId;

  final http.Client _httpClient = http.Client();
  StreamSubscription<String>? _streamSubscription;
  int? _assistantMessageIndex;
  final StringBuffer _sseBuffer = StringBuffer();

  static const Duration _requestTimeout = Duration(seconds: 45);

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<String> get suggestedPrompts => List.unmodifiable(_suggestedPrompts);
  bool get isLoading => _isLoading;
  String? get activeProductId => _activeProductId;

  Future<void> sendMessage(
    String userMessage, {
    String? token,
    String? productId,
  }) async {
    final trimmed = userMessage.trim();
    if (trimmed.isEmpty) return;
    if (_isLoading) return;

    _messages.add(
      ChatMessage(
        content: trimmed,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );
    _suggestedPrompts.clear();
    _isLoading = true;
    notifyListeners();

    if (token == null || token.isEmpty) {
    _messages.add(
      ChatMessage(
          content: '請先登入會員後再使用 AI 對話功能。',
          isUser: false,
        timestamp: DateTime.now(),
      ),
    );
      _isLoading = false;
    notifyListeners();
      return;
  }

    _messages.add(
      ChatMessage(
        content: '',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
    _assistantMessageIndex = _messages.length - 1;
    _activeProductId = productId ?? _activeProductId;
    notifyListeners();

    // 判斷是否為針對特定書籍的對話
    if (_activeProductId != null && _activeProductId!.isNotEmpty) {
      // 針對書籍：使用原有的串流對話 API
      await _startStreaming(prompt: trimmed, token: token);
    } else {
      // 一般搜尋/主題：使用向量搜尋 API
      await _performVectorSearch(query: trimmed);
    }
  }

  Future<void> _performVectorSearch({required String query}) async {
    try {
      final result = await SearchService.searchVector(keyword: query);
      final List<Book> foundBooks = result.books;

      String responseText;
      if (foundBooks.isEmpty) {
        responseText = '抱歉，我沒有找到相關的書籍。建議您嘗試不同的關鍵字，或是換個說法。';
      } else {
        responseText = '根據您的需求，我為您精選了以下書籍：';
      }

      if (_assistantMessageIndex != null) {
        _messages[_assistantMessageIndex!] =
            _messages[_assistantMessageIndex!].copyWith(
          content: responseText,
          books: foundBooks,
          timestamp: DateTime.now(),
        );
      }

      // 產生建議提問
      if (result.books.isNotEmpty) {
        _suggestedPrompts.clear();
        _suggestedPrompts.addAll([
          '還有其他的嗎？',
          '這幾本有什麼特色？',
          '幫我挑最便宜的',
        ]);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _setAssistantMessageContent('搜尋失敗：$e\n這可能是由於網路連線問題或搜尋服務暫時不可用。');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _startStreaming({
    required String prompt,
    String? token,
  }) async {
    _cancelActiveStream();
    _sseBuffer.clear();

    final uri =
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.aiTalkToBooksEndpoint}');
    final payload = <String, String>{
      'prompt': prompt,
    };

    final product = _activeProductId;
    if (product != null && product.isNotEmpty) {
      payload['product_id'] = product;
    }

    final request = http.Request('POST', uri)
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream,application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      })
      ..body = jsonEncode(payload);

    try {
      final response = await _httpClient.send(request).timeout(_requestTimeout);

      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        throw Exception(
          'AI 服務錯誤 (${response.statusCode})：'
          '${errorBody.isEmpty ? '請稍後再試' : errorBody}',
        );
      }

      _streamSubscription = response.stream
          .transform(utf8.decoder)
          .listen(
            _handleStreamChunk,
            onError: _handleStreamError,
            onDone: _handleStreamDone,
          );
    } catch (e) {
      _setAssistantMessageContent('AI 服務無法回應：$e');
      _stopStreaming();
    }
  }

  void _handleStreamChunk(String chunk) {
    if (chunk.isEmpty) return;

    final sanitized = chunk.replaceAll('\r', '');
    if (sanitized.trim() == '[DONE]') {
      _stopStreaming();
      return;
    }

    if (sanitized.contains('data:')) {
      _sseBuffer.write(sanitized);
      _drainSseBuffer();
      return;
    }

    final text = _extractTextPayload(sanitized) ?? sanitized;
    _appendAssistantContent(text);
  }

  void _drainSseBuffer() {
    final raw = _sseBuffer.toString();
    if (raw.isEmpty) return;

    final frames = raw.split('\n\n');
    final hasTrailing = raw.endsWith('\n\n');
    final pending = hasTrailing ? '' : frames.removeLast();
    _sseBuffer
      ..clear()
      ..write(pending);

    for (final frame in frames) {
      final dataLines = frame
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) => line.trim());
      final buffer = StringBuffer();
      for (final line in dataLines) {
        if (line.startsWith('data:')) {
          buffer.writeln(line.substring(5).trimLeft());
        }
      }

      final payload = buffer.toString().trim();
      if (payload.isEmpty) continue;

      if (payload == '[DONE]') {
        _stopStreaming();
        continue;
      }

      final text = _extractTextPayload(payload) ?? payload;
      _appendAssistantContent(text);
    }
  }

  String? _extractTextPayload(String payload) {
    final trimmed = payload.trim();
    if (!(trimmed.startsWith('{') && trimmed.endsWith('}'))) {
      return null;
    }

    try {
      final decoded = json.decode(trimmed);
      if (decoded is Map<String, dynamic>) {
        _ingestPromptSuggestions(decoded['prompt'] as String?);
      }
      return _unwrapContent(decoded);
    } catch (_) {
      return null;
    }
  }

  String? _unwrapContent(dynamic data) {
    if (data == null) return null;
    if (data is String) return data;

    if (data is Map<String, dynamic>) {
      const candidateKeys = [
        'content',
        'answer',
        'message',
        'text',
      ];

      for (final key in candidateKeys) {
        final value = data[key];
        if (value is String) return value;
      }

      final delta = data['delta'];
      if (delta is Map<String, dynamic>) {
        final deltaContent = delta['content'];
        if (deltaContent is String) return deltaContent;
      }

      final choices = data['choices'];
      if (choices is List && choices.isNotEmpty) {
        final choice = choices.first;
        if (choice is Map<String, dynamic>) {
          final choiceDelta = choice['delta'];
          if (choiceDelta is Map<String, dynamic>) {
            final deltaContent = choiceDelta['content'];
            if (deltaContent is String) return deltaContent;
          }

          final message = choice['message'];
          if (message is Map<String, dynamic>) {
            final content = message['content'];
            if (content is String) return content;
          }
        }
      }
    }

    return null;
  }

  void _appendAssistantContent(String text) {
    if (_assistantMessageIndex == null) return;

    final current = _messages[_assistantMessageIndex!];
    final updated = current.copyWith(
      content: '${current.content}$text',
      timestamp: DateTime.now(),
    );
    _messages[_assistantMessageIndex!] = updated;
    notifyListeners();
  }

  void _setAssistantMessageContent(String text) {
    if (_assistantMessageIndex == null) {
      _messages.add(
        ChatMessage(
          content: text,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      _assistantMessageIndex = _messages.length - 1;
    } else {
      _messages[_assistantMessageIndex!] =
          _messages[_assistantMessageIndex!].copyWith(
        content: text,
        timestamp: DateTime.now(),
      );
    }
    notifyListeners();
  }

  void _handleStreamError(Object error, [StackTrace? stackTrace]) {
    _setAssistantMessageContent('AI 服務連線失敗：$error');
    _stopStreaming();
  }

  void _handleStreamDone() {
    _stopStreaming();
  }

  void _stopStreaming() {
    _sseBuffer.clear();
    final sub = _streamSubscription;
    _streamSubscription = null;
    sub?.cancel();
    if (_isLoading) {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _cancelActiveStream() {
    final sub = _streamSubscription;
    _streamSubscription = null;
    sub?.cancel();
  }

  void clearChat() {
    _messages.clear();
    _assistantMessageIndex = null;
    _cancelActiveStream();
    _suggestedPrompts.clear();
    _isLoading = false;
    notifyListeners();
  }

  // 添加預設歡迎訊息
  void addWelcomeMessage() {
    if (_messages.isEmpty) {
      _messages.add(
        ChatMessage(
          content: '''歡迎來到讀冊生活網路書店！我是你的AI智能助手 🤖

我可以幫你：
• 📚 推薦適合的書籍
• 💰 解答價格和優惠問題
• 🚚 提供配送資訊
• 👤 協助會員服務
• 🔍 幫你找到想要的書籍

有什麼我可以幫助你的嗎？''',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
    }
  }

  void setProductContext(String? productId) {
    if (productId == null || productId.trim().isEmpty) {
      _activeProductId = null;
      return;
    }
    _activeProductId = productId;
  }

  @override
  void dispose() {
    _cancelActiveStream();
    _httpClient.close();
    super.dispose();
  }

  void _ingestPromptSuggestions(String? promptBlock) {
    if (promptBlock == null || promptBlock.trim().isEmpty) return;

    final lines = promptBlock
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map(
          (line) => line.replaceFirst(RegExp(r'^\d+[\.:)\-：]\s*'), '').trim(),
        )
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) return;

    final unique = <String>[];
    for (final line in lines) {
      if (!unique.contains(line)) {
        unique.add(line);
      }
    }

    if (listEquals(unique, _suggestedPrompts)) {
      return;
    }

    _suggestedPrompts
      ..clear()
      ..addAll(unique);
    notifyListeners();
  }
}
