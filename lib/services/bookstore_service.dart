import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/bookstore.dart';
import '../utils/debug_helper.dart';

/// 實體書店專區 API。價格、庫存、付款狀態都以伺服器為準，App 只送商品與數量。
class BookstoreService {
  static const Duration _timeout = Duration(seconds: 12);

  static Future<List<BookstoreStore>> listStores(String token) async {
    final data = await _send('GET', ApiConfig.bookstoreStoresEndpoint, token);
    return (data as List)
        .whereType<Map<String, dynamic>>()
        .map(BookstoreStore.fromJson)
        .toList();
  }

  static Future<PresenceSession> resolveDoorQr(String token, String content) async {
    final data = await _send('POST', ApiConfig.bookstoreDoorQrEndpoint, token,
        body: {'content': content});
    return PresenceSession.fromJson(data as Map<String, dynamic>);
  }

  static Future<List<BookstoreCategory>> listCategories(String token, String storeId) async {
    final data = await _send(
        'GET', '${ApiConfig.bookstoreStoresEndpoint}/$storeId/categories', token);
    return (data as List)
        .whereType<Map<String, dynamic>>()
        .map(BookstoreCategory.fromJson)
        .toList();
  }

  static Future<BookstoreProductPage> listProducts(
    String token,
    String storeId, {
    String? query,
    String? categoryId,
    String sort = 'new',
    int page = 1,
    int pageSize = 20,
  }) async {
    final data = await _send(
      'GET',
      '${ApiConfig.bookstoreStoresEndpoint}/$storeId/products',
      token,
      query: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (categoryId != null) 'category_id': categoryId,
        'sort': sort,
        'page': '$page',
        'page_size': '$pageSize',
      },
    );
    return BookstoreProductPage.fromJson(data as Map<String, dynamic>);
  }

  static Future<BookstoreProduct> getProduct(
      String token, String storeId, String productId) async {
    final data = await _send('GET',
        '${ApiConfig.bookstoreStoresEndpoint}/$storeId/products/$productId', token);
    return BookstoreProduct.fromJson(data as Map<String, dynamic>);
  }

  static Future<BookstoreProduct> lookup(String token, String storeId, String code) async {
    final data = await _send(
        'GET', '${ApiConfig.bookstoreStoresEndpoint}/$storeId/lookup', token,
        query: {'code': code});
    return BookstoreProduct.fromJson(data as Map<String, dynamic>);
  }

  static Future<MemberWallet> getWallet(String token) async {
    final data = await _send('GET', ApiConfig.bookstoreWalletEndpoint, token);
    return MemberWallet.fromJson(data as Map<String, dynamic>);
  }

  static Future<BookstoreCheckout> createCheckout(
    String token, {
    required String storeId,
    required String presenceToken,
    required String clientRequestId,
    required Map<String, int> lines,
    InvoiceChoice? invoice,
    int redeemBonus = 0,
    int redeemAcc = 0,
  }) async {
    final data = await _send('POST', ApiConfig.bookstoreCheckoutsEndpoint, token, body: {
      'store_id': storeId,
      'presence_token': presenceToken,
      'client_request_id': clientRequestId,
      'lines': [
        for (final e in lines.entries) {'product_id': e.key, 'qty': e.value},
      ],
      if (invoice?.toJson() != null) 'invoice': invoice!.toJson(),
      if (redeemBonus > 0) 'redeem_bonus': redeemBonus,
      if (redeemAcc > 0) 'redeem_acc': redeemAcc,
    });
    return BookstoreCheckout.fromJson(data as Map<String, dynamic>);
  }

  /// 收現後把已結案訂單回寫讀冊；失敗不影響出門憑證（POS 也會回呼）。
  static Future<void> settleCheckout(String token, String id) async {
    await _send('POST', '${ApiConfig.bookstoreCheckoutsEndpoint}/$id/settle', token);
  }

  static Future<List<BookstoreCheckout>> listCheckouts(String token) async {
    final data = await _send('GET', ApiConfig.bookstoreCheckoutsEndpoint, token);
    return (data as List)
        .whereType<Map<String, dynamic>>()
        .map(BookstoreCheckout.fromJson)
        .toList();
  }

  static Future<BookstoreCheckout> getCheckout(String token, String id) async {
    final data =
        await _send('GET', '${ApiConfig.bookstoreCheckoutsEndpoint}/$id', token);
    return BookstoreCheckout.fromJson(data as Map<String, dynamic>);
  }

  static Future<BookstoreCheckout> cancelCheckout(String token, String id) async {
    final data = await _send(
        'POST', '${ApiConfig.bookstoreCheckoutsEndpoint}/$id/cancel', token);
    return BookstoreCheckout.fromJson(data as Map<String, dynamic>);
  }

  /// 選擇現金（櫃台付款）；伺服器套用門市現金折扣並回傳櫃台付款碼
  static Future<BookstoreCheckout> chooseCash(String token, String id) async {
    final data = await _send(
        'POST', '${ApiConfig.bookstoreCheckoutsEndpoint}/$id/cash', token);
    return BookstoreCheckout.fromJson(data as Map<String, dynamic>);
  }

  static Future<Uri> startPayment(String token, String id) async {
    final data =
        await _send('POST', '${ApiConfig.bookstoreCheckoutsEndpoint}/$id/pay', token);
    final url = (data as Map<String, dynamic>)['payment_url']?.toString();
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'https' && !ApiConfig.isTestEnvironment)) {
      throw BookstoreException('付款連結異常，請稍後再試');
    }
    return uri;
  }

  static Future<dynamic> _send(
    String method,
    String path,
    String token, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path')
        .replace(queryParameters: query?.isEmpty ?? true ? null : query);
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    DebugHelper.logApiRequest(method, uri.toString());

    http.Response response;
    try {
      response = await (method == 'POST'
              ? http.post(uri, headers: headers, body: json.encode(body ?? {}))
              : http.get(uri, headers: headers))
          .timeout(_timeout);
    } catch (e) {
      DebugHelper.log('BookstoreService network error: $e', tag: 'Bookstore');
      throw BookstoreException('網路連線不穩，請稍後再試');
    }
    DebugHelper.logApiResponse(response.statusCode, response.body);

    dynamic decoded;
    try {
      decoded = json.decode(utf8.decode(response.bodyBytes));
    } catch (_) {
      decoded = null;
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded == null) throw BookstoreException('資料格式錯誤，請稍後再試');
      return decoded;
    }
    throw BookstoreException.fromResponse(response.statusCode, decoded);
  }
}

class BookstoreException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  BookstoreException(this.message, {this.code, this.statusCode});

  factory BookstoreException.fromResponse(int status, dynamic body) {
    final detail = body is Map<String, dynamic> ? body['detail'] : null;
    if (detail is Map && detail['message'] is String) {
      return BookstoreException(detail['message'] as String,
          code: detail['code']?.toString(), statusCode: status);
    }
    final fallback = switch (status) {
      401 => '登入狀態已過期，請重新登入',
      404 => '找不到資料',
      409 => '狀態已變更，請重新整理',
      422 => '資料格式不正確',
      429 => '操作太頻繁，請稍後再試',
      _ => '實體書店服務暫時無法使用，請稍後再試',
    };
    return BookstoreException(fallback, statusCode: status);
  }

  bool get needsPresence => code == 'presence_required';
  bool get isAuthError => statusCode == 401;

  @override
  String toString() => message;
}
