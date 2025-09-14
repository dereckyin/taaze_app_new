import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/book.dart';
import '../utils/debug_helper.dart';
import '../config/api_config.dart';

class TodayDealsProvider with ChangeNotifier {
  List<Book> _todayDeals = [];
  bool _isLoading = false;
  String? _error;

  List<Book> get todayDeals => _todayDeals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // API 配置
  static const Duration _timeout = Duration(seconds: 10);

  // 模擬今日特價資料
  final List<Book> _mockTodayDeals = [
    Book(
      id: '1',
      title: '特價書籍 1',
      author: '作者 1',
      price: 199,
      imageUrl: 'https://picsum.photos/200/300?random=1',
      description: '這是一本特價書籍的描述',
      isbn: '9781234567890',
      publisher: '出版社 1',
      publishDate: DateTime.now().subtract(const Duration(days: 30)),
      category: '文學',
      rating: 4.5,
      reviewCount: 128,
      isAvailable: true,
      pages: 320,
    ),
    Book(
      id: '2',
      title: '特價書籍 2',
      author: '作者 2',
      price: 149,
      imageUrl: 'https://picsum.photos/200/300?random=2',
      description: '這是一本特價書籍的描述',
      isbn: '9781234567891',
      publisher: '出版社 2',
      publishDate: DateTime.now().subtract(const Duration(days: 60)),
      category: '科技',
      rating: 4.2,
      reviewCount: 89,
      isAvailable: true,
      pages: 280,
    ),
    Book(
      id: '3',
      title: '特價書籍 3',
      author: '作者 3',
      price: 99,
      imageUrl: 'https://picsum.photos/200/300?random=3',
      description: '這是一本特價書籍的描述',
      isbn: '9781234567892',
      publisher: '出版社 3',
      publishDate: DateTime.now().subtract(const Duration(days: 90)),
      category: '歷史',
      rating: 4.8,
      reviewCount: 256,
      isAvailable: true,
      pages: 450,
    ),
    Book(
      id: '4',
      title: '特價書籍 4',
      author: '作者 4',
      price: 179,
      imageUrl: 'https://picsum.photos/200/300?random=4',
      description: '這是一本特價書籍的描述',
      isbn: '9781234567893',
      publisher: '出版社 4',
      publishDate: DateTime.now().subtract(const Duration(days: 45)),
      category: '藝術',
      rating: 4.3,
      reviewCount: 67,
      isAvailable: true,
      pages: 200,
    ),
    Book(
      id: '5',
      title: '特價書籍 5',
      author: '作者 5',
      price: 129,
      imageUrl: 'https://picsum.photos/200/300?random=5',
      description: '這是一本特價書籍的描述',
      isbn: '9781234567894',
      publisher: '出版社 5',
      publishDate: DateTime.now().subtract(const Duration(days: 75)),
      category: '教育',
      rating: 4.6,
      reviewCount: 142,
      isAvailable: true,
      pages: 350,
    ),
  ];

  TodayDealsProvider() {
    _loadTodayDeals();
  }

  Future<void> _loadTodayDeals() async {
    DebugHelper.log('開始載入今日特價資料', tag: 'TodayDealsProvider');
    _isLoading = true;
    notifyListeners();

    try {
      // 首先嘗試從 API 獲取資料
      DebugHelper.log('嘗試從 API 獲取今日特價資料', tag: 'TodayDealsProvider');
      final apiBooks = await _fetchTodayDealsFromAPI();

      if (apiBooks.isNotEmpty) {
        _todayDeals = apiBooks;
        _error = null; // 清除錯誤狀態
        DebugHelper.log(
          '成功從 API 載入 ${_todayDeals.length} 個今日特價商品',
          tag: 'TodayDealsProvider',
        );
      } else {
        // API 返回空資料，使用 mock data
        DebugHelper.log('API 返回空資料，使用 mock data', tag: 'TodayDealsProvider');
        _loadMockData();
        _error = 'API 返回空資料，已載入模擬資料';
      }
    } catch (e) {
      // API 調用失敗，使用 mock data 作為 fallback
      DebugHelper.log(
        'API 調用失敗: ${e.toString()}，使用 mock data',
        tag: 'TodayDealsProvider',
      );
      _loadMockData();
      _error = 'API 連接失敗，已載入模擬資料：${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  // 載入模擬資料
  void _loadMockData() {
    _todayDeals = _mockTodayDeals.where((book) => book.isAvailable).toList();
    DebugHelper.log(
      '載入今日特價假資料: ${_todayDeals.length} 個商品',
      tag: 'TodayDealsProvider',
    );
  }

  // 從 API 獲取今日特價資料
  Future<List<Book>> _fetchTodayDealsFromAPI() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/content/deals/today');
      DebugHelper.logApiRequest('GET', uri.toString());

      final response = await http.get(uri).timeout(_timeout);
      DebugHelper.logApiResponse(response.statusCode, response.body);

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        List<dynamic> jsonData;
        if (responseData is List) {
          // API 直接返回 List
          jsonData = responseData;
        } else if (responseData is Map<String, dynamic>) {
          // API 返回包含 data 字段的 Map
          jsonData = responseData['data'] ?? [];
        } else {
          throw Exception('API 返回格式不正確');
        }

        return jsonData.map((json) => Book.fromJson(json)).toList();
      } else {
        throw Exception('API 返回錯誤狀態碼: ${response.statusCode}');
      }
    } catch (e) {
      DebugHelper.log('API調用異常: ${e.toString()}', tag: 'TodayDealsProvider');
      throw Exception('API 調用失敗: ${e.toString()}');
    }
  }

  // 清除錯誤
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // 手動重新載入資料
  Future<void> refreshTodayDeals() async {
    await _loadTodayDeals();
  }

  // 強制重新載入（優先使用 API）
  Future<void> forceRefreshFromAPI() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 強制從 API 重新載入
      DebugHelper.log('強制從 API 重新載入今日特價資料', tag: 'TodayDealsProvider');
      final apiBooks = await _fetchTodayDealsFromAPI();

      if (apiBooks.isNotEmpty) {
        _todayDeals = apiBooks;
        _error = null;
        DebugHelper.log(
          '強制重新載入成功，載入 ${_todayDeals.length} 個今日特價商品',
          tag: 'TodayDealsProvider',
        );
      } else {
        _loadMockData();
        _error = 'API 返回空資料，已載入模擬資料';
        DebugHelper.log('API 返回空資料，使用模擬資料', tag: 'TodayDealsProvider');
      }
    } catch (e) {
      _loadMockData();
      _error = 'API 重新載入失敗，已載入模擬資料：${e.toString()}';
      DebugHelper.log('API 重新載入失敗，使用模擬資料', tag: 'TodayDealsProvider');
    }

    _isLoading = false;
    notifyListeners();
  }

  // 切換到離線模式（使用模擬資料）
  void switchToOfflineMode() {
    _loadMockData();
    _error = '離線模式 - 顯示模擬資料';
    notifyListeners();
  }

  // 檢查是否為離線模式
  bool get isOfflineMode => _error?.contains('離線模式') ?? false;
}
