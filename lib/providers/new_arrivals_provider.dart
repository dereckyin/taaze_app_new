import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/book.dart';
import '../utils/debug_helper.dart';

class NewArrivalsProvider with ChangeNotifier {
  List<Book> _newArrivals = [];
  bool _isLoading = false;
  String? _error;

  List<Book> get newArrivals => _newArrivals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const Duration _timeout = Duration(seconds: 10);
  final int _defaultStart = 0;
  final int _defaultEnd = 19;

  final List<Book> _mockNewArrivals = [
    Book(
      id: 'n1',
      title: '新書 1',
      author: '作者 Alpha',
      price: 520,
      imageUrl: 'https://picsum.photos/200/300?random=201',
      description: '注目新品 1 描述',
      isbn: '9780000000011',
      publisher: '新書出版社',
      publishDate: DateTime.now().subtract(const Duration(days: 2)),
      category: '文學',
      rating: 4.9,
      reviewCount: 120,
      isAvailable: true,
      pages: 320,
    ),
    Book(
      id: 'n2',
      title: '新書 2',
      author: '作者 Beta',
      price: 480,
      imageUrl: 'https://picsum.photos/200/300?random=202',
      description: '注目新品 2 描述',
      isbn: '9780000000012',
      publisher: '新書出版社',
      publishDate: DateTime.now().subtract(const Duration(days: 5)),
      category: '商業',
      rating: 4.7,
      reviewCount: 95,
      isAvailable: true,
      pages: 280,
    ),
  ];

  NewArrivalsProvider() {
    _loadNewArrivals();
  }

  Future<void> _loadNewArrivals({int? startNum, int? endNum}) async {
    _isLoading = true;
    notifyListeners();

    final int start = startNum ?? _defaultStart;
    final int end = endNum ?? _defaultEnd;

    DebugHelper.log(
      '開始載入注目新品資料 (start=$start, end=$end)',
      tag: 'NewArrivalsProvider',
    );

    try {
      final apiBooks = await _fetchNewArrivalsFromAPI(
        startNum: start,
        endNum: end,
      );

      if (apiBooks.isNotEmpty) {
        _newArrivals = apiBooks;
        _error = null;
        DebugHelper.log(
          '注目新品資料已由API取得，共 ${_newArrivals.length} 筆',
          tag: 'NewArrivalsProvider',
        );
      } else {
        DebugHelper.log('API 返回空資料，改用 mock', tag: 'NewArrivalsProvider');
        _useMockData('API 返回空資料');
      }
    } catch (e) {
      DebugHelper.log(
        '注目新品 API 取得失敗，改用 mock: ${e.toString()}',
        tag: 'NewArrivalsProvider',
      );
      _useMockData('API 連線失敗：${e.toString()}');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<Book>> _fetchNewArrivalsFromAPI({
    required int startNum,
    required int endNum,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/book/latest?startNum=$startNum&endNum=$endNum',
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
    _newArrivals = List.from(_mockNewArrivals);
    _error = reason;
  }

  Future<void> refreshNewArrivals({int? startNum, int? endNum}) async {
    await _loadNewArrivals(startNum: startNum, endNum: endNum);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}


