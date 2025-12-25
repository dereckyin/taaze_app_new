import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../utils/debug_helper.dart';

class CheckoutService {
  static const Duration _timeout = Duration(seconds: 10);

  static Future<CheckoutTicket> requestCheckoutTicket({
    required String token,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.checkoutTicketEndpoint}',
    );

    DebugHelper.logApiRequest('POST', uri.toString());

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          )
          .timeout(_timeout);

      DebugHelper.logApiResponse(response.statusCode, response.body);

      if (response.statusCode != 200) {
        throw CheckoutException(
          _mapStatusMessage(response.statusCode),
          statusCode: response.statusCode,
        );
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw CheckoutException('結帳票證格式錯誤，請稍後再試');
      }

      final checkoutUrl = decoded['checkout_url']?.toString();
      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        throw CheckoutException('伺服器未回傳結帳連結，請稍後再試');
      }

      return CheckoutTicket(
        checkoutUrl: checkoutUrl,
        ticket: decoded['ticket']?.toString(),
        expiresAt: decoded['expires_at']?.toString(),
      );
    } on CheckoutException {
      rethrow;
    } catch (e) {
      DebugHelper.log('CheckoutService error: $e', tag: 'Checkout');
      throw CheckoutException('建立結帳連結時發生錯誤，請稍後再試');
    }
  }

  static String _mapStatusMessage(int statusCode) {
    switch (statusCode) {
      case 401:
        return '登入狀態已過期，請重新登入後再試';
      case 403:
        return '您沒有權限執行此結帳操作';
      case 404:
        return '找不到結帳服務，請稍後再試';
      case 500:
        return '結帳服務暫時不可用，請稍後再試';
      default:
        return '結帳請求失敗 (HTTP $statusCode)';
    }
  }
}

class CheckoutTicket {
  final String checkoutUrl;
  final String? ticket;
  final String? expiresAt;

  const CheckoutTicket({
    required this.checkoutUrl,
    this.ticket,
    this.expiresAt,
  });
}

class CheckoutException implements Exception {
  final String message;
  final int? statusCode;

  CheckoutException(this.message, {this.statusCode});

  @override
  String toString() => 'CheckoutException($statusCode): $message';
}

