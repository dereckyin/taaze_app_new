import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/cart_item.dart';
import '../utils/debug_helper.dart';

class CheckoutService {
  static const Duration _timeout = Duration(seconds: 10);

  static Future<void> syncCartItems({
    required String token,
    required List<CartItem> items,
  }) async {
    if (items.isEmpty) {
      throw CheckoutException('購物車目前沒有商品，請先加入商品後再結帳');
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.syncCartEndpoint}',
    );

    final payload = {
      'items': items
          .map(
            (item) => {
              'prod_id': item.book.id,
              'org_prod_id': item.book.orgProdId,
              'title': item.book.title,
              'price': item.book.price,
              'quantity': item.quantity,
              'unit_price': item.book.price,
              'total_price': item.totalPrice,
            },
          )
          .toList(),
      'total_quantity': items.fold<int>(
        0,
        (sum, item) => sum + item.quantity,
      ),
      'total_price': items.fold<double>(
        0,
        (sum, item) => sum + item.totalPrice,
      ),
      'synced_at': DateTime.now().toIso8601String(),
    };

    DebugHelper.logApiRequest('POST', uri.toString(), body: payload);

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: json.encode(payload),
          )
          .timeout(_timeout);

      DebugHelper.logApiResponse(response.statusCode, response.body);

      if (response.statusCode != 200) {
        throw CheckoutException(
          _mapStatusMessage(response.statusCode),
          statusCode: response.statusCode,
        );
      }
    } on CheckoutException {
      rethrow;
    } catch (e) {
      DebugHelper.log('CheckoutService sync error: $e', tag: 'Checkout');
      throw CheckoutException('同步購物車商品失敗，請稍後再試');
    }
  }

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



