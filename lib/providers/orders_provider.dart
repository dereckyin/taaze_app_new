import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/order.dart';
import '../utils/debug_helper.dart';

class OrdersProvider with ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;
  int? _lastStatusCode;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _orders.isNotEmpty;
  int? get lastStatusCode => _lastStatusCode;

  static const Duration _timeout = Duration(seconds: 10);

  Future<OrdersFetchResult> fetchOrders({required String token}) async {
    _isLoading = true;
    _error = null;
    _lastStatusCode = null;
    notifyListeners();

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.ordersEndpoint}',
    );

    DebugHelper.logApiRequest('GET', uri.toString());

    try {
      final response = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);

      _lastStatusCode = response.statusCode;
      DebugHelper.logApiResponse(response.statusCode, response.body);

      if (response.statusCode != 200) {
        throw OrdersHttpException(
          statusCode: response.statusCode,
          message: _mapStatusMessage(response.statusCode),
        );
      }

      final decoded = json.decode(response.body);
      if (decoded is! List) {
        throw OrdersHttpException(
          statusCode: response.statusCode,
          message: '訂單資料格式錯誤',
        );
      }

      _orders = decoded
          .map((orderJson) => Order.fromJson(orderJson as Map<String, dynamic>))
          .toList();

      _error = null;
      return OrdersFetchResult.success(statusCode: response.statusCode);
    } on OrdersHttpException catch (e) {
      DebugHelper.log('OrdersProvider http error: ${e.message}',
          tag: 'OrdersProvider');
      _error = e.message;
      _lastStatusCode = e.statusCode;
      return OrdersFetchResult.failure(
        statusCode: e.statusCode,
        message: e.message,
      );
    } catch (e) {
      DebugHelper.log('OrdersProvider error: $e', tag: 'OrdersProvider');
      _error = e.toString();
      _lastStatusCode = null;
      return OrdersFetchResult.failure(message: e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _orders = [];
    _error = null;
    _lastStatusCode = null;
    notifyListeners();
  }

  String _mapStatusMessage(int statusCode) {
    switch (statusCode) {
      case 401:
        return '登入已失效或缺少授權資訊';
      case 403:
        // TODO: 未來支援多個 Oracle 帳號時，改為導向 cust_id 選擇流程並重新簽發 token。
        return '帳號權限不足或會員不符';
      default:
        return '訂單查詢失敗 (status $statusCode)';
    }
  }
}

class OrdersFetchResult {
  final bool success;
  final int? statusCode;
  final String? message;

  const OrdersFetchResult({
    required this.success,
    this.statusCode,
    this.message,
  });

  factory OrdersFetchResult.success({int? statusCode}) =>
      OrdersFetchResult(success: true, statusCode: statusCode);

  factory OrdersFetchResult.failure({int? statusCode, String? message}) =>
      OrdersFetchResult(
        success: false,
        statusCode: statusCode,
        message: message,
      );
}

class OrdersHttpException implements Exception {
  final int statusCode;
  final String message;

  OrdersHttpException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() => 'OrdersHttpException($statusCode): $message';
}

