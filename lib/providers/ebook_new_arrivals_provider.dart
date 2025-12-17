import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/book.dart';
import '../utils/debug_helper.dart';

class EbookNewArrivalsProvider with ChangeNotifier {
  List<Book> _ebooks = [];
  bool _isLoading = false;
  String? _error;

  List<Book> get ebooks => _ebooks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const Duration _timeout = Duration(seconds: 10);
  final int _defaultStart = 0;
  final int _defaultEnd = 19;

  final List<Book> _mockEbooks = [
    Book(
      id: 'e1',
      title: '電子書 1',
      author: '作者 X',
      price: 320,
      imageUrl: 'https://picsum.photos/200/300?random=301',
      description: '電子書注目新品 1 描述',
      isbn: '9780000000111',
      publisher: '數位出版社',
      publishDate: DateTime.now().subtract(const Duration(days: 1)),
      category: '電子書',
      rating: 4.6,
      reviewCount: 80,
      isAvailable: true,
      pages: 0,
    ),
    Book(
      id: 'e2',
      title: '電子書 2',
      author: '作者 Y',
      price: 280,
      imageUrl: 'https://picsum.photos/200/300?random=302',
      description: '電子書注目新品 2 描述',
      isbn: '9780000000112',
      publisher: '數位出版社',
      publishDate: DateTime.now().subtract(const Duration(days: 4)),
      category: '電子書',
      rating: 4.5,
      reviewCount: 65,
      isAvailable: true,
      pages: 0,
    ),
  ];

  EbookNewArrivalsProvider() {
    _loadEbooks();
  }

  Future<void> _loadEbooks({int? startNum, int? endNum}) async {
    _isLoading = true;
    notifyListeners();

    final int start = startNum ?? _defaultStart;
    final int end = endNum ?? _defaultEnd;

    DebugHelper.log(
      '開始載入電子書注目新品資料 (start=$start, end=$end)',
      tag: 'EbookNewArrivalsProvider',
    );

    try {
      final apiBooks = await _fetchEbooksFromAPI(
        startNum: start,
        endNum: end,
      );

      if (apiBooks.isNotEmpty) {
        _ebooks = apiBooks;
        _error = null;
        DebugHelper.log(
          '電子書注目新品資料已由API取得，共 ${_ebooks.length} 筆',
          tag: 'EbookNewArrivalsProvider',
        );
      } else {
        DebugHelper.log('API 返回空資料，改用 mock', tag: 'EbookNewArrivalsProvider');
        _useMockData('API 返回空資料');
      }
    } catch (e) {
      DebugHelper.log(
        '電子書注目新品 API 取得失敗，改用 mock: ${e.toString()}',
        tag: 'EbookNewArrivalsProvider',
      );
      _useMockData('API 連線失敗：${e.toString()}');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<Book>> _fetchEbooksFromAPI({
    required int startNum,
    required int endNum,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.ebookNewArrivalsEndpoint}?startNum=$startNum&endNum=$endNum',
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
    _ebooks = List.from(_mockEbooks);
    _error = reason;
  }

  Future<void> refreshEbooks({int? startNum, int? endNum}) async {
    await _loadEbooks(startNum: startNum, endNum: endNum);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}


