import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class UsedBookMarketSummary {
  final String isbn;
  final int count;
  final double? minPrice;
  final double? medianPrice;
  final double? maxPrice;

  const UsedBookMarketSummary({
    required this.isbn,
    required this.count,
    this.minPrice,
    this.medianPrice,
    this.maxPrice,
  });

  factory UsedBookMarketSummary.fromJson(Map<String, dynamic> json) {
    double? asDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return UsedBookMarketSummary(
      isbn: (json['isbn'] ?? '').toString(),
      count: (json['count'] is num)
          ? (json['count'] as num).toInt()
          : int.tryParse('${json['count']}') ?? 0,
      minPrice: asDouble(json['minPrice']),
      medianPrice: asDouble(json['medianPrice']),
      maxPrice: asDouble(json['maxPrice']),
    );
  }

  bool get hasPrices =>
      count > 0 && minPrice != null && medianPrice != null && maxPrice != null;
}

class UsedBookMarketService {
  static const Duration _timeout = Duration(seconds: 15);

  static Future<UsedBookMarketSummary> fetchByIsbn(String isbn) async {
    final digits = isbn.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.usedBookMarketEndpoint}',
    ).replace(queryParameters: {'isbn': digits});

    final response = await http.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('二手行情查詢失敗 (${response.statusCode})');
    }
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw Exception('二手行情回應格式錯誤');
    }
    return UsedBookMarketSummary.fromJson(body);
  }
}
