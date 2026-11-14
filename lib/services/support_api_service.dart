import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/support.dart';

class SupportApiService {
  static String get baseUrl => ApiConfig.baseUrl;
  static const Duration timeout = Duration(seconds: 20);
  static const Duration uploadTimeout = Duration(seconds: 60);

  static Map<String, String> _headers(String authToken) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

  /// attachment_url may be `/api/v1/support/media/...` while baseUrl already ends with `/api/v1`.
  static String resolveMediaUrl(String attachmentUrl) {
    final path = attachmentUrl.trim();
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final origin = baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');
    if (path.startsWith('/')) return '$origin$path';
    return '$baseUrl/$path';
  }

  static Future<List<SupportConversation>> listConversations({
    required String authToken,
  }) async {
    final uri = Uri.parse('$baseUrl/support/conversations');
    final res = await http
        .get(uri, headers: _headers(authToken))
        .timeout(timeout);
    if (res.statusCode != 200) {
      throw Exception('List conversations failed: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body);
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => SupportConversation.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<SupportConversation> createConversation({
    required String authToken,
    required String body,
    String? subject,
    String? category,
    bool handoff = false,
  }) async {
    final uri = Uri.parse('$baseUrl/support/conversations');
    final res = await http
        .post(
          uri,
          headers: _headers(authToken),
          body: jsonEncode({
            'body': body,
            if (subject != null && subject.isNotEmpty) 'subject': subject,
            if (category != null && category.isNotEmpty) 'category': category,
            if (handoff) 'handoff': true,
          }),
        )
        .timeout(timeout);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Create conversation failed: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return SupportConversation.fromJson(data);
  }

  static Future<List<SupportMessage>> listMessages({
    required String authToken,
    required int convId,
    int? afterId,
    String? since,
    int limit = 100,
  }) async {
    final params = <String, String>{
      'limit': '$limit',
      if (afterId != null) 'after_id': '$afterId',
      if (since != null && since.isNotEmpty) 'since': since,
    };
    final uri = Uri.parse('$baseUrl/support/conversations/$convId/messages')
        .replace(queryParameters: params);
    final res = await http
        .get(uri, headers: _headers(authToken))
        .timeout(timeout);
    if (res.statusCode != 200) {
      throw Exception('List messages failed: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body);
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => SupportMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<SupportMessage> sendMessage({
    required String authToken,
    required int convId,
    required String body,
    String? attachmentUrl,
  }) async {
    final uri = Uri.parse('$baseUrl/support/conversations/$convId/messages');
    final res = await http
        .post(
          uri,
          headers: _headers(authToken),
          body: jsonEncode({
            'body': body,
            if (attachmentUrl != null && attachmentUrl.isNotEmpty)
              'attachment_url': attachmentUrl,
          }),
        )
        .timeout(timeout);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Send message failed: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return SupportMessage.fromJson(data);
  }

  static Future<SupportMessage> uploadImageMessage({
    required String authToken,
    required int convId,
    required String filePath,
    required String filename,
    String contentType = 'image/jpeg',
  }) async {
    final uri = Uri.parse('$baseUrl/support/conversations/$convId/images');
    final req = http.MultipartRequest('POST', uri);
    req.headers['Authorization'] = 'Bearer $authToken';
    req.headers['Accept'] = 'application/json';
    // contentType kept for API compatibility; server also sniffs by filename.
    req.fields['content_type'] = contentType;
    req.files.add(
      await http.MultipartFile.fromPath(
        'file',
        filePath,
        filename: filename,
      ),
    );
    final streamed = await req.send().timeout(uploadTimeout);
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Upload image failed: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return SupportMessage.fromJson(data);
  }

  static Future<Uint8List> fetchMediaBytes({
    required String authToken,
    required String attachmentUrl,
  }) async {
    final uri = Uri.parse(resolveMediaUrl(attachmentUrl));
    final res = await http
        .get(
          uri,
          headers: {
            'Authorization': 'Bearer $authToken',
            'Accept': '*/*',
          },
        )
        .timeout(timeout);
    if (res.statusCode != 200) {
      throw Exception('Fetch media failed: ${res.statusCode}');
    }
    return res.bodyBytes;
  }

  static Future<SupportConversation> closeConversation({
    required String authToken,
    required int convId,
  }) async {
    final uri = Uri.parse('$baseUrl/support/conversations/$convId/close');
    final res = await http
        .post(uri, headers: _headers(authToken))
        .timeout(timeout);
    if (res.statusCode != 200) {
      throw Exception('Close conversation failed: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return SupportConversation.fromJson(data);
  }

  static Future<void> markRead({
    required String authToken,
    required int convId,
  }) async {
    final uri = Uri.parse('$baseUrl/support/conversations/$convId/read');
    final res = await http
        .post(uri, headers: _headers(authToken))
        .timeout(timeout);
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception('Mark read failed: ${res.statusCode} ${res.body}');
    }
  }

  static Future<int> unreadCount({required String authToken}) async {
    final uri = Uri.parse('$baseUrl/support/unread-count');
    final res = await http
        .get(uri, headers: _headers(authToken))
        .timeout(timeout);
    if (res.statusCode != 200) {
      throw Exception('Unread count failed: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final raw = data['unread_count'] ?? data['unreadCount'] ?? 0;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString()) ?? 0;
  }
}
