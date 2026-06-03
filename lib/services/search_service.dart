import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/book.dart';
import '../utils/debug_helper.dart';
import '../config/api_config.dart';

class SearchService {
  static const Duration _timeout = Duration(seconds: 15);

  /// 向量搜尋 (Vector Search)
  static Future<SearchResultData> searchVector({
    required String keyword,
    int page = 1,
    int pageSize = 20,
    String? sort,
    String? order,
  }) async {
    return _searchViaApi(
      endpoint: ApiConfig.searchVectorEndpoint,
      keyword: keyword,
      page: page,
      pageSize: pageSize,
      sort: sort,
      order: order,
      logLabel: 'Vector Search Result',
    );
  }

  /// 搜尋書籍（透過後端 API，避免 Android 直接連線 www.taaze.tw 的 SSL 問題）
  static Future<SearchResultData> searchBooks({
    required String keyword,
    int page = 1,
    int pageSize = 24,
  }) async {
    return _searchViaApi(
      endpoint: ApiConfig.searchEndpoint,
      keyword: keyword,
      page: page,
      pageSize: pageSize,
      logLabel: 'Search Result',
    );
  }

  static Future<SearchResultData> _searchViaApi({
    required String endpoint,
    required String keyword,
    required int page,
    required int pageSize,
    String? sort,
    String? order,
    required String logLabel,
  }) async {
    if (keyword.trim().isEmpty) {
      return SearchResultData.empty();
    }

    final queryParams = {
      'q': keyword,
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (sort != null) 'sort': sort,
      if (order != null) 'order': order,
    };

    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint')
        .replace(queryParameters: queryParams);

    DebugHelper.logApiRequest('GET', uri.toString());

    try {
      final response = await http.get(uri).timeout(_timeout);

      DebugHelper.logApiResponse(response.statusCode, logLabel);

      if (response.statusCode != 200) {
        throw Exception('搜尋服務異常 (${response.statusCode})');
      }

      final Map<String, dynamic> decoded =
          jsonDecode(utf8.decoder.convert(response.bodyBytes));
      final List<dynamic> data = decoded['data'] ?? [];
      final books = data.map((item) => Book.fromJson(item)).toList();

      final pagination = decoded['pagination'] ?? {};
      final total = pagination['totalCount'] ?? pagination['total'] ?? books.length;
      final hasMore = pagination['hasMore'] ?? ((page * pageSize) < total);

      final message = decoded['message']?.toString();

      return SearchResultData(
        books: books,
        hasMore: hasMore,
        message: message,
      );
    } catch (e) {
      DebugHelper.log('搜尋API調用失敗: ${e.toString()}', tag: 'SearchService');
      rethrow;
    }
  }
}

class SearchResultData {
  final List<Book> books;
  final bool hasMore;
  final String? message;

  const SearchResultData({
    required this.books,
    required this.hasMore,
    this.message,
  });

  factory SearchResultData.empty() =>
      const SearchResultData(books: [], hasMore: false);

  String? get intentHint {
    final msg = message;
    if (msg == null || msg.isEmpty) return null;
    const labels = {
      'exact_search': 'ISBN／商品編號精確搜尋',
      'exact_search_fallback': '精確搜尋（備援）',
      'keyword_search': '關鍵字搜尋',
      'semantic_search': '語意搜尋',
      'nl_keyword_search': 'AI 理解後的關鍵字搜尋',
      'nl_ai_keyword_search': 'AI 擴展關鍵字搜尋',
    };
    return labels[msg] ?? msg;
  }
}
