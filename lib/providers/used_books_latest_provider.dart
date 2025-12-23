import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/book.dart';
import '../utils/debug_helper.dart';

class UsedBooksLatestProvider with ChangeNotifier {
  List<Book> _usedBooks = [];
  bool _isLoading = false;
  String? _error;

  List<Book> get usedBooks => _usedBooks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const Duration _timeout = Duration(seconds: 10);
  final int _defaultStart = 0;
  final int _defaultEnd = 19;

  final List<Book> _mockUsedBooks = [
    Book(
      id: 'ub1',
      title: '二手書 1',
      author: '作者 U1',
      price: 220,
      imageUrl: 'https://picsum.photos/200/300?random=401',
      description: '最新上架二手書 1 描述',
      isbn: '9780000000211',
      publisher: '二手出版社',
      publishDate: DateTime.now().subtract(const Duration(days: 12)),
      category: '二手書',
      rating: 4.3,
      reviewCount: 40,
      isAvailable: true,
      pages: 280,
    ),
    Book(
      id: 'ub2',
      title: '二手書 2',
      author: '作者 U2',
      price: 180,
      imageUrl: 'https://picsum.photos/200/300?random=402',
      description: '最新上架二手書 2 描述',
      isbn: '9780000000212',
      publisher: '二手出版社',
      publishDate: DateTime.now().subtract(const Duration(days: 18)),
      category: '二手書',
      rating: 4.1,
      reviewCount: 28,
      isAvailable: true,
      pages: 250,
    ),
  ];

  UsedBooksLatestProvider() {
    _loadUsedBooks();
  }

  Future<void> _loadUsedBooks({int? startNum, int? endNum}) async {
    _isLoading = true;
    notifyListeners();

    final int start = startNum ?? _defaultStart;
    final int end = endNum ?? _defaultEnd;

    DebugHelper.log(
      '開始載入最新上架二手書資料 (start=$start, end=$end)',
      tag: 'UsedBooksLatestProvider',
    );

    try {
      final apiBooks = await _fetchUsedBooksFromAPI(
        startNum: start,
        endNum: end,
      );

      if (apiBooks.isNotEmpty) {
        _usedBooks = apiBooks;
        _error = null;
        DebugHelper.log(
          '最新上架二手書資料已由API取得，共 ${_usedBooks.length} 筆',
          tag: 'UsedBooksLatestProvider',
        );
      } else {
        DebugHelper.log('API 返回空資料，改用 mock', tag: 'UsedBooksLatestProvider');
        _useMockData('API 返回空資料');
      }
    } catch (e) {
      DebugHelper.log(
        '最新上架二手書 API 取得失敗，改用 mock: ${e.toString()}',
        tag: 'UsedBooksLatestProvider',
      );
      _useMockData('API 連線失敗：${e.toString()}');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<Book>> _fetchUsedBooksFromAPI({
    required int startNum,
    required int endNum,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.usedBooksLatestEndpoint}?startNum=$startNum&endNum=$endNum',
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
    _usedBooks = List.from(_mockUsedBooks);
    _error = reason;
  }

  Future<void> refreshUsedBooks({int? startNum, int? endNum}) async {
    await _loadUsedBooks(startNum: startNum, endNum: endNum);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}





