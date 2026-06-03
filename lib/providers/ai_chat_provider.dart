import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../screens/ai_chat_screen.dart';
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

    await _startStreaming(prompt: trimmed, token: token);
  }

  Future<void> _startStreaming({
    required String prompt,
    String? token,
  }) async {
    _cancelActiveStream();
    _sseBuffer.clear();

    final uri =
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.aiTalkToBooksEndpoint}');
    final payload = <String, dynamic>{
      'prompt': prompt,
      'history': _buildHistoryPayload(),
      'exclude_prod_ids': _buildExcludeProdIds(),
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
        if (response.statusCode == 401) {
          _setAssistantMessageContent(
            '登入已失效（無效的令牌）。請至「我的」登出後重新登入，再使用 AI 對話。',
          );
          _stopStreaming();
          return;
        }
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

  List<Map<String, String>> _buildHistoryPayload() {
    if (_messages.length <= 2) return const [];

    final history = <Map<String, String>>[];
    final end = _messages.length - 2;
    final start = end > 20 ? end - 20 : 0;

    for (var i = start; i < end; i++) {
      final message = _messages[i];
      final content = message.content.trim();
      if (content.isEmpty) continue;
      history.add({
        'role': message.isUser ? 'user' : 'assistant',
        'content': content,
      });
    }
    return history;
  }

  List<String> _buildExcludeProdIds() {
    if (_messages.length <= 2) return const [];

    final ids = <String>{};
    final end = _messages.length - 2;
    for (var i = 0; i < end; i++) {
      final books = _messages[i].books;
      if (books == null || books.isEmpty) continue;
      for (final book in books) {
        if (book.id.isNotEmpty) ids.add(book.id);
        final orgId = book.orgProdId;
        if (orgId != null && orgId.isNotEmpty) ids.add(orgId);
      }
    }
    return ids.toList();
  }

  void _handleStreamChunk(String chunk) {
    if (chunk.isEmpty) return;

    final sanitized = chunk.replaceAll('\r', '');
    if (sanitized.trim() == '[DONE]') {
      _stopStreaming();
      return;
    }

    _sseBuffer.write(sanitized);
    _drainSseBuffer();
  }

  void _drainSseBuffer({bool forceFlush = false}) {
    final raw = _sseBuffer.toString();
    if (raw.isEmpty) return;

    final frames = raw.split('\n\n');
    final hasTrailing = raw.endsWith('\n\n');
    final pending = (hasTrailing || forceFlush) ? '' : frames.removeLast();
    _sseBuffer
      ..clear()
      ..write(pending);

    for (final frame in frames) {
      _processSseFrame(frame);
    }
  }

  void _processSseFrame(String frame) {
    final trimmedFrame = frame.trim();
    if (trimmedFrame.isEmpty) return;

    var eventName = 'message';
    final dataLines = <String>[];

    for (final line in trimmedFrame.split('\n')) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;
      if (trimmedLine.startsWith('event:')) {
        eventName = trimmedLine.substring(6).trim();
        continue;
      }
      if (trimmedLine.startsWith('data:')) {
        dataLines.add(trimmedLine.substring(5).trimLeft());
      }
    }

    if (dataLines.isEmpty) {
      _processPayload(trimmedFrame, eventName: eventName);
      return;
    }

    for (final data in dataLines) {
      if (data.isEmpty) continue;
      _processPayload(data, eventName: eventName);
    }
  }

  void _processPayload(String payload, {String eventName = 'message'}) {
    if (payload == '[DONE]') {
      _stopStreaming();
      return;
    }

    if (eventName == 'books') {
      _ingestBooksPayload(payload);
      return;
    }

    if (eventName == 'prompt') {
      _ingestPromptPayload(payload);
      return;
    }

    if (payload.contains('\n')) {
      for (final line in payload.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty) {
          _processPayload(trimmed, eventName: eventName);
        }
      }
      return;
    }

    if (payload.startsWith('{') && payload.endsWith('}')) {
      try {
        final decoded = json.decode(payload);
        if (decoded is Map<String, dynamic>) {
          _ingestStreamMetadata(decoded);
          final text = _unwrapContent(decoded);
          if (text != null && text.isNotEmpty) {
            _appendAssistantContent(text);
          }
          return;
        }
      } catch (_) {
        // Fall through for non-JSON text chunks.
      }
    }

    if (payload.startsWith('[') && payload.endsWith(']')) {
      if (_ingestBooksPayload(payload)) return;
    }

    if (!_looksLikeStructuredPayload(payload)) {
      _appendAssistantContent(payload);
    }
  }

  bool _ingestBooksPayload(String payload) {
    try {
      final decoded = json.decode(payload);
      if (decoded is List) {
        _ingestBookSuggestions(decoded);
        return true;
      }
      if (decoded is Map<String, dynamic>) {
        final booksRaw = decoded['books'] ?? decoded['items'] ?? decoded['data'];
        if (booksRaw is List) {
          _ingestBookSuggestions(booksRaw);
          return true;
        }
        if (_looksLikeBookMap(decoded)) {
          _ingestBookSuggestions([decoded]);
          return true;
        }
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  void _ingestPromptPayload(String payload) {
    try {
      final decoded = json.decode(payload);
      if (decoded is List) {
        final lines = decoded.map((e) => e.toString()).where((e) => e.trim().isNotEmpty);
        _ingestPromptSuggestions(lines.join('\n'));
        return;
      }
      if (decoded is Map<String, dynamic>) {
        _ingestPromptSuggestions(decoded['prompt'] as String?);
      }
    } catch (_) {
      _ingestPromptSuggestions(payload);
    }
  }

  bool _looksLikeStructuredPayload(String payload) {
    final trimmed = payload.trim();
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      try {
        final decoded = json.decode(trimmed);
        if (decoded is List && decoded.isNotEmpty) {
          final first = decoded.first;
          if (first is Map && _looksLikeBookMap(Map<String, dynamic>.from(first))) {
            return true;
          }
        }
      } catch (_) {
        return false;
      }
    }
    if (!(trimmed.startsWith('{') && trimmed.endsWith('}'))) {
      return false;
    }
    try {
      final decoded = json.decode(trimmed);
      if (decoded is! Map<String, dynamic>) return false;
      return decoded.containsKey('books') ||
          decoded.containsKey('items') ||
          decoded.containsKey('prompt') ||
          decoded.containsKey('prodId') ||
          decoded.containsKey('prod_id') ||
          decoded.containsKey('titleMain') ||
          decoded.containsKey('imageUrl');
    } catch (_) {
      return false;
    }
  }

  void _ingestStreamMetadata(Map<String, dynamic> decoded) {
    _ingestPromptSuggestions(decoded['prompt'] as String?);

    final booksRaw = decoded['books'];
    if (booksRaw is List) {
      _ingestBookSuggestions(booksRaw);
      return;
    }

    if (_looksLikeBookMap(decoded)) {
      _ingestBookSuggestions([decoded]);
    }
  }

  bool _looksLikeBookMap(Map<String, dynamic> map) {
    final hasTitle = map.containsKey('titleMain') ||
        map.containsKey('title') ||
        map.containsKey('title_main');
    final hasBookSignal = map.containsKey('prodId') ||
        map.containsKey('prod_id') ||
        map.containsKey('id') ||
        map.containsKey('imageUrl') ||
        map.containsKey('salePrice') ||
        map.containsKey('listPrice');
    return hasTitle && hasBookSignal;
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
    _drainSseBuffer(forceFlush: true);
    _finalizeAssistantMessage();
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

  void _finalizeAssistantMessage() {
    if (_assistantMessageIndex == null) return;

    final current = _messages[_assistantMessageIndex!];
    final extractedBooks = <Book>[];
    final cleanedContent = _peelEmbeddedMetadata(current.content, extractedBooks);

    if (cleanedContent == current.content && extractedBooks.isEmpty) {
      return;
    }

    final mergedBooks = _mergeBooks(current.books ?? const [], extractedBooks);
    _messages[_assistantMessageIndex!] = current.copyWith(
      content: cleanedContent.trim(),
      books: mergedBooks.isNotEmpty ? mergedBooks : current.books,
      timestamp: DateTime.now(),
    );
    notifyListeners();
  }

  String _peelEmbeddedMetadata(String content, List<Book> booksOut) {
    final buffer = StringBuffer();
    var index = 0;

    while (index < content.length) {
      final char = content[index];
      if (char != '{' && char != '[') {
        buffer.write(char);
        index++;
        continue;
      }

      final end = char == '{'
          ? _findMatchingBrace(content, index, '{', '}')
          : _findMatchingBrace(content, index, '[', ']');
      if (end == null) {
        buffer.write(char);
        index++;
        continue;
      }

      final candidate = content.substring(index, end + 1);
      if (_tryExtractMetadataCandidate(candidate, booksOut)) {
        index = end + 1;
        continue;
      }

      buffer.write(candidate);
      index = end + 1;
    }

    return buffer.toString();
  }

  int? _findMatchingBrace(
    String input,
    int start,
    String open,
    String close,
  ) {
    var depth = 0;
    var inString = false;
    var escaped = false;

    for (var i = start; i < input.length; i++) {
      final char = input[i];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (char == '\\') {
          escaped = true;
        } else if (char == '"') {
          inString = false;
        }
        continue;
      }

      if (char == '"') {
        inString = true;
        continue;
      }
      if (char == open) {
        depth++;
      } else if (char == close) {
        depth--;
        if (depth == 0) return i;
      }
    }
    return null;
  }

  bool _tryExtractMetadataCandidate(String candidate, List<Book> booksOut) {
    try {
      final decoded = json.decode(candidate);
      if (decoded is List) {
        final books = _booksFromDynamicList(decoded);
        if (books.isNotEmpty) {
          booksOut.addAll(books);
          return true;
        }
      } else if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('prompt') && decoded.length <= 2) {
          _ingestPromptSuggestions(decoded['prompt'] as String?);
          return true;
        }
        final booksRaw = decoded['books'] ?? decoded['items'];
        if (booksRaw is List) {
          final books = _booksFromDynamicList(booksRaw);
          if (books.isNotEmpty) {
            booksOut.addAll(books);
            return true;
          }
        }
        if (_looksLikeBookMap(decoded)) {
          booksOut.add(Book.fromJson(decoded));
          return true;
        }
        if (_looksLikeStructuredPayload(candidate) &&
            _unwrapContent(decoded) == null) {
          return true;
        }
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  List<Book> _booksFromDynamicList(List<dynamic> rawBooks) {
    final books = <Book>[];
    for (final item in rawBooks) {
      if (item is Map<String, dynamic>) {
        books.add(Book.fromJson(item));
      } else if (item is Map) {
        books.add(Book.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    return books;
  }

  List<Book> _mergeBooks(List<Book> existing, List<Book> incoming) {
    if (incoming.isEmpty) return existing;
    final merged = List<Book>.from(existing);
    for (final book in incoming) {
      final duplicate = merged.any(
        (item) =>
            item.id.isNotEmpty &&
            book.id.isNotEmpty &&
            item.id == book.id,
      );
      if (!duplicate) merged.add(book);
    }
    return merged;
  }

  void _ingestBookSuggestions(dynamic rawBooks) {
    if (rawBooks is! List || _assistantMessageIndex == null) return;

    final books = _booksFromDynamicList(rawBooks);
    if (books.isEmpty) return;

    final current = _messages[_assistantMessageIndex!];
    final merged = _mergeBooks(current.books ?? const [], books);
    _messages[_assistantMessageIndex!] = current.copyWith(
      books: merged,
      timestamp: DateTime.now(),
    );
    notifyListeners();
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
