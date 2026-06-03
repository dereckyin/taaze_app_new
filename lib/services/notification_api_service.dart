import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/notification.dart';

class NotificationApiService {
  static String get baseUrl => ApiConfig.baseUrl;
  static const Duration timeout = Duration(seconds: 15);

  static Future<void> registerToken({
    required String token,
    required String platform,
    required String appVersion,
    String? deviceModel,
    String? locale,
    required String authToken,
  }) async {
    final uri = Uri.parse('$baseUrl/notifications/register-token');
    final body = {
      'fcm_token': token,
      'platform': platform,
      'app_version': appVersion,
      if (deviceModel != null && deviceModel.isNotEmpty)
        'device_model': deviceModel,
      if (locale != null && locale.isNotEmpty) 'locale': locale,
    };
    final res = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode(body),
        )
        .timeout(timeout);
    if (res.statusCode == 204) {
      if (kDebugMode) {
        debugPrint(
          '[NotificationApi] register-token ok platform=$platform token=${token.substring(0, token.length > 10 ? 10 : token.length)}...',
        );
      }
    } else {
      throw Exception('Register token failed: ${res.statusCode} ${res.body}');
    }
  }

  static Future<void> revokeToken({
    required String token,
    String? authToken,
  }) async {
    final uri = Uri.parse('$baseUrl/notifications/revoke-token');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (authToken != null && authToken.isNotEmpty)
        'Authorization': 'Bearer $authToken',
    };
    final res = await http
        .post(uri, headers: headers, body: jsonEncode({'fcm_token': token}))
        .timeout(timeout);
    if (res.statusCode != 204) {
      throw Exception('Revoke token failed: ${res.statusCode} ${res.body}');
    }
  }

  static Future<void> subscribeTopic({
    required String token,
    required String topic,
    required String authToken,
  }) async {
    final uri = Uri.parse('$baseUrl/notifications/subscribe-topic');
    final res = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode({'fcm_token': token, 'topic': topic}),
        )
        .timeout(timeout);
    if (res.statusCode != 204) {
      throw Exception('Subscribe topic failed: ${res.statusCode} ${res.body}');
    }
  }

  static Future<void> unsubscribeTopic({
    required String token,
    required String topic,
    required String authToken,
  }) async {
    final uri = Uri.parse('$baseUrl/notifications/unsubscribe-topic');
    final res = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode({'fcm_token': token, 'topic': topic}),
        )
        .timeout(timeout);
    if (res.statusCode != 204) {
      throw Exception(
        'Unsubscribe topic failed: ${res.statusCode} ${res.body}',
      );
    }
  }

  static Future<List<AppNotification>> fetchInbox({
    required String authToken,
    int limit = 50,
  }) async {
    final uri = Uri.parse('$baseUrl/notifications/inbox').replace(
      queryParameters: {'limit': limit.toString()},
    );
    final res = await http
        .get(
          uri,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
        )
        .timeout(timeout);
    if (res.statusCode != 200) {
      throw Exception('Fetch inbox failed: ${res.statusCode} ${res.body}');
    }
    final decoded = jsonDecode(utf8.decoder.convert(res.bodyBytes));
    final items = decoded['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> markInboxRead({
    required String authToken,
    List<String>? notificationIds,
    bool markAll = false,
  }) async {
    final uri = Uri.parse('$baseUrl/notifications/inbox/read');
    final body = <String, dynamic>{
      if (markAll) 'mark_all': true,
      if (notificationIds != null && notificationIds.isNotEmpty)
        'notification_ids': notificationIds,
    };
    final res = await http
        .patch(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode(body),
        )
        .timeout(timeout);
    if (res.statusCode != 204) {
      throw Exception('Mark read failed: ${res.statusCode} ${res.body}');
    }
  }

  static Future<void> deleteInboxItem({
    required String authToken,
    required String notificationId,
  }) async {
    final uri = Uri.parse('$baseUrl/notifications/inbox/$notificationId');
    final res = await http
        .delete(
          uri,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
        )
        .timeout(timeout);
    if (res.statusCode != 204) {
      throw Exception('Delete inbox failed: ${res.statusCode} ${res.body}');
    }
  }
}
