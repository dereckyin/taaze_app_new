import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/book.dart';
import '../utils/debug_helper.dart';

class BestsellersProvider with ChangeNotifier {
  List<Book> _bestsellers = [];
  bool _isLoading = false;
  String? _error;

  List<Book> get bestsellers => _bestsellers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const Duration _timeout = Duration(seconds: 10);
  final int _defaultStart = 0;
  final int _defaultEnd = 9;

  // 簡單的 fallback 假資料（僅在 API 無法取得時使用）
  final List<Book> _mockBestsellers = [
    Book(
      id: 'b1',
      title: '暢銷書 1',
      author: '作者 A',
      price: 450,
      imageUrl: 'https://picsum.photos/200/300?random=101',
      description: '暢銷書 1 描述',
      isbn: '9780000000001',
      publisher: '暢銷出版社',
      publishDate: DateTime.now().subtract(const Duration(days: 10)),
      category: '文學',
      rating: 4.8,
      reviewCount: 520,
      isAvailable: true,
      pages: 360,
    ),
    Book(
      id: 'b2',
      title: '暢銷書 2',
      author: '作者 B',
      price: 380,
      imageUrl: 'https://picsum.photos/200/300?random=102',
      description: '暢銷書 2 描述',
      isbn: '9780000000002',
      publisher: '暢銷出版社',
      publishDate: DateTime.now().subtract(const Duration(days: 20)),
      category: '商業',
      rating: 4.7,
      reviewCount: 410,
      isAvailable: true,
      pages: 320,
    ),
  ];

  BestsellersProvider() {
    _loadBestsellers();
  }

  Future<void> _loadBestsellers({int? startNum, int? endNum}) async {
    _isLoading = true;
    notifyListeners();
    final int start = startNum ?? _defaultStart;
    final int end = endNum ?? _defaultEnd;

    DebugHelper.log(
      '開始載入暢銷榜資料 (start=$start, end=$end)',
      tag: 'BestsellersProvider',
    );

    try {
      final apiBooks = await _fetchBestsellersFromAPI(startNum: start, endNum: end);
      if (apiBooks.isNotEmpty) {
        _bestsellers = apiBooks;
        _error = null;
        DebugHelper.log(
          '暢銷榜資料已由API取得，共 ${_bestsellers.length} 筆',
          tag: 'BestsellersProvider',
        );
      } else {
        DebugHelper.log('API 返回空資料，改用 mock', tag: 'BestsellersProvider');
        _useMockData('API 返回空資料');
      }
    } catch (e) {
      DebugHelper.log(
        '暢銷榜API取得失敗，改用 mock: ${e.toString()}',
        tag: 'BestsellersProvider',
      );
      _useMockData('API 連線失敗：${e.toString()}');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<Book>> _fetchBestsellersFromAPI({
    required int startNum,
    required int endNum,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/content/bestsellers?startNum=$startNum&endNum=$endNum',
    );
    DebugHelper.logApiRequest('GET', uri.toString());

    final response = await http.get(uri).timeout(_timeout);
    DebugHelper.logApiResponse(response.statusCode, response.body);

    if (response.statusCode != 200) {
      throw Exception('status ${response.statusCode}');
    }

    final dynamic decoded = json.decode(response.body);
    List<dynamic> listData;

    if (decoded is List) {
      listData = decoded;
    } else if (decoded is Map<String, dynamic>) {
      listData = (decoded['data'] ?? []) as List<dynamic>;
    } else {
      throw Exception('unexpected response format');
    }

    return listData.map((e) => Book.fromJson(e)).toList();
  }

  void _useMockData(String reason) {
    _bestsellers = List.from(_mockBestsellers);
    _error = reason;
  }

  Future<void> refreshBestsellers({int? startNum, int? endNum}) async {
    await _loadBestsellers(startNum: startNum, endNum: endNum);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

