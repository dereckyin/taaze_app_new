import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http; // 暫時註解，使用假資料模式
// import 'dart:convert'; // 暫時註解，使用假資料模式
import '../models/book.dart';
import '../utils/debug_helper.dart';

class BookProvider with ChangeNotifier {
  List<Book> _books = [];
  List<Book> _featuredBooks = [];
  List<String> _categories = [];
  bool _isLoading = false;
  String? _error;

  // 新增的四個板塊資料
  List<Book> _todayDeals = [];
  List<Book> _bestsellers = [];
  List<Book> _newReleases = [];
  List<Book> _usedBooks = [];

  // 分頁相關
  int _currentPage = 1;
  final int _pageSize = 20;
  int _totalCount = 0;
  bool _hasMore = true;

  // API 配置（暫時註解，使用假資料模式）
  // static const String _baseUrl = 'https://api.taaze.tw/api/v1'; // 替換為實際的 API URL
  // static const String _booksEndpoint = '/api/books';
  // static const String _todayDealsEndpoint = '/api/books/today-deals';
  // static const String _bestsellersEndpoint = '/api/books/bestsellers';
  // static const String _newReleasesEndpoint = '/api/books/new-releases';
  // static const String _usedBooksEndpoint = '/api/books/used-books';
  // static const Duration _timeout = Duration(seconds: 10);

  List<Book> get books => _books;
  List<Book> get featuredBooks => _featuredBooks;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 新增的getter
  List<Book> get todayDeals => _todayDeals;
  List<Book> get bestsellers => _bestsellers;
  List<Book> get newReleases => _newReleases;
  List<Book> get usedBooks => _usedBooks;

  // 分頁相關getter
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalCount => _totalCount;
  bool get hasMore => _hasMore;

  // 模擬書籍資料
  final List<Book> _mockBooks = [
    Book(
      id: '1',
      title: 'Flutter開發實戰',
      author: '張三',
      description: '這是一本關於Flutter開發的實戰指南，涵蓋了從基礎到進階的所有內容。適合想要學習跨平台開發的開發者。',
      price: 599.0,
      imageUrl: 'https://picsum.photos/300/400?random=1',
      category: '程式設計',
      rating: 4.8,
      reviewCount: 128,
      isAvailable: true,
      publishDate: DateTime(2024, 1, 15),
      isbn: '9781234567890',
      pages: 350,
      publisher: '科技出版社',
    ),
    Book(
      id: '2',
      title: 'Dart語言入門',
      author: '李四',
      description: '學習Dart程式語言的完整指南，適合初學者。從基礎語法到進階概念，全面掌握Dart開發。',
      price: 399.0,
      imageUrl: 'https://picsum.photos/300/400?random=2',
      category: '程式設計',
      rating: 4.5,
      reviewCount: 89,
      isAvailable: true,
      publishDate: DateTime(2024, 2, 10),
      isbn: '9781234567891',
      pages: 280,
      publisher: '程式設計出版社',
    ),
    Book(
      id: '3',
      title: '移動應用設計',
      author: '王五',
      description: '現代移動應用UI/UX設計的最佳實踐。學習如何設計出用戶喜愛的應用程式界面。',
      price: 699.0,
      imageUrl: 'https://picsum.photos/300/400?random=3',
      category: '設計',
      rating: 4.7,
      reviewCount: 156,
      isAvailable: true,
      publishDate: DateTime(2024, 1, 20),
      isbn: '9781234567892',
      pages: 420,
      publisher: '設計出版社',
    ),
    Book(
      id: '4',
      title: '人工智慧基礎',
      author: '趙六',
      description: '人工智慧的基本概念和應用實例。從機器學習到深度學習，全面了解AI技術。',
      price: 799.0,
      imageUrl: 'https://picsum.photos/300/400?random=4',
      category: '人工智慧',
      rating: 4.9,
      reviewCount: 203,
      isAvailable: true,
      publishDate: DateTime(2024, 3, 5),
      isbn: '9781234567893',
      pages: 500,
      publisher: 'AI出版社',
    ),
    Book(
      id: '5',
      title: '資料庫設計',
      author: '孫七',
      description: '現代資料庫設計和優化技術。學習如何設計高效能的資料庫系統。',
      price: 549.0,
      imageUrl: 'https://picsum.photos/300/400?random=5',
      category: '資料庫',
      rating: 4.6,
      reviewCount: 94,
      isAvailable: true,
      publishDate: DateTime(2024, 2, 28),
      isbn: '9781234567894',
      pages: 320,
      publisher: '資料科技出版社',
    ),
    Book(
      id: '6',
      title: '網路安全實務',
      author: '周八',
      description: '網路安全的基本概念和防護措施。保護您的系統免受網路威脅。',
      price: 649.0,
      imageUrl: 'https://picsum.photos/300/400?random=6',
      category: '網路安全',
      rating: 4.4,
      reviewCount: 78,
      isAvailable: true,
      publishDate: DateTime(2024, 1, 10),
      isbn: '9781234567895',
      pages: 380,
      publisher: '安全出版社',
    ),
    Book(
      id: '7',
      title: 'React Native開發指南',
      author: '陳九',
      description: '使用React Native開發跨平台移動應用的完整指南。',
      price: 599.0,
      imageUrl: 'https://picsum.photos/300/400?random=7',
      category: '程式設計',
      rating: 4.6,
      reviewCount: 142,
      isAvailable: true,
      publishDate: DateTime(2024, 3, 15),
      isbn: '9781234567896',
      pages: 380,
      publisher: '前端出版社',
    ),
    Book(
      id: '8',
      title: 'Python機器學習',
      author: '林十',
      description: '使用Python進行機器學習的實用教程，包含豐富的實例和案例。',
      price: 699.0,
      imageUrl: 'https://picsum.photos/300/400?random=8',
      category: '人工智慧',
      rating: 4.8,
      reviewCount: 189,
      isAvailable: true,
      publishDate: DateTime(2024, 2, 20),
      isbn: '9781234567897',
      pages: 450,
      publisher: 'AI科技出版社',
    ),
    Book(
      id: '9',
      title: 'UI設計原則',
      author: '黃十一',
      description: '現代UI設計的核心原則和最佳實踐，提升用戶體驗設計能力。',
      price: 499.0,
      imageUrl: 'https://picsum.photos/300/400?random=9',
      category: '設計',
      rating: 4.5,
      reviewCount: 95,
      isAvailable: true,
      publishDate: DateTime(2024, 1, 25),
      isbn: '9781234567898',
      pages: 320,
      publisher: '設計學院出版社',
    ),
    Book(
      id: '10',
      title: '雲端運算架構',
      author: '吳十二',
      description: '現代雲端運算架構設計和部署策略，掌握雲端技術核心。',
      price: 799.0,
      imageUrl: 'https://picsum.photos/300/400?random=10',
      category: '雲端運算',
      rating: 4.7,
      reviewCount: 167,
      isAvailable: true,
      publishDate: DateTime(2024, 3, 1),
      isbn: '9781234567899',
      pages: 480,
      publisher: '雲端科技出版社',
    ),
    Book(
      id: '11',
      title: 'JavaScript進階',
      author: '鄭十三',
      description: '深入學習JavaScript進階概念，包括ES6+、非同步程式設計等。',
      price: 549.0,
      imageUrl: 'https://picsum.photos/300/400?random=11',
      category: '程式設計',
      rating: 4.6,
      reviewCount: 134,
      isAvailable: true,
      publishDate: DateTime(2024, 2, 15),
      isbn: '9781234567900',
      pages: 360,
      publisher: '前端開發出版社',
    ),
    Book(
      id: '12',
      title: '區塊鏈技術',
      author: '劉十四',
      description: '區塊鏈技術原理與應用，了解數位貨幣和智能合約的基礎。',
      price: 649.0,
      imageUrl: 'https://picsum.photos/300/400?random=12',
      category: '區塊鏈',
      rating: 4.3,
      reviewCount: 87,
      isAvailable: true,
      publishDate: DateTime(2024, 1, 30),
      isbn: '9781234567901',
      pages: 400,
      publisher: '區塊鏈出版社',
    ),
  ];

  BookProvider() {
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    DebugHelper.log('開始載入書籍資料（使用假資料模式）', tag: 'BookProvider');
    _isLoading = true;
    notifyListeners();

    try {
      // 直接使用假資料，不調用API
      DebugHelper.log('使用假資料模式，跳過API調用', tag: 'BookProvider');
      _loadMockData();
      _error = null; // 清除錯誤狀態

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // 如果假資料載入失敗
      DebugHelper.log('假資料載入失敗: ${e.toString()}', tag: 'BookProvider');
      _error = '資料載入失敗：${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // 從 API 獲取書籍資料（暫時註解，使用假資料模式）
  /*
  Future<List<Book>> _fetchBooksFromAPI([String? endpoint]) async {
    try {
      final url = endpoint ?? _booksEndpoint;
      final uri = Uri.parse('$_baseUrl$url');
      DebugHelper.logApiRequest('GET', uri.toString());

      final response = await http.get(uri).timeout(_timeout);
      DebugHelper.logApiResponse(response.statusCode, response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // 處理分頁響應格式
        if (responseData.containsKey('data')) {
          final List<dynamic> jsonData = responseData['data'];
          _totalCount = responseData['total_count'] ?? 0;
          _hasMore = responseData['has_more'] ?? false;
          return jsonData.map((json) => _bookFromJson(json)).toList();
        } else {
          // 處理簡單數組格式
          final List<dynamic> jsonData = responseData as List<dynamic>;
          return jsonData.map((json) => _bookFromJson(json)).toList();
        }
      } else {
        throw Exception('API 返回錯誤狀態碼: ${response.statusCode}');
      }
    } catch (e) {
      DebugHelper.log('API調用異常: ${e.toString()}', tag: 'BookProvider');
      throw Exception('API 調用失敗: ${e.toString()}');
    }
  }
  */

  // 從 JSON 創建 Book 物件（暫時註解，使用假資料模式）
  /*
  Book _bookFromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['imageUrl']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      isAvailable: json['isAvailable'] ?? true,
      publishDate: json['publishDate'] != null
          ? DateTime.parse(json['publishDate'])
          : DateTime.now(),
      isbn: json['isbn']?.toString() ?? '',
      pages: json['pages'] ?? 0,
      publisher: json['publisher']?.toString() ?? '',
    );
  }
  */

  // 載入模擬資料
  void _loadMockData() {
    _books = List.from(_mockBooks);
    _featuredBooks = _books.take(4).toList();
    _categories = _books.map((book) => book.category).toSet().toList();

    // 同時載入四個板塊的模擬資料
    _todayDeals = _mockBooks.where((book) => book.price < 500).take(6).toList();
    _bestsellers = _mockBooks.where((book) => book.rating > 4.5).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating)) // 按評分降序排序
      ..take(6).toList();
    _newReleases = _mockBooks
        .where(
          (book) => book.publishDate.isAfter(
            DateTime.now().subtract(const Duration(days: 30)),
          ),
        )
        .take(6)
        .toList();
    _usedBooks = _mockBooks.where((book) => book.price < 300).take(6).toList();
  }

  List<Book> getBooksByCategory(String category) {
    return _books.where((book) => book.category == category).toList();
  }

  List<Book> searchBooks(String query) {
    if (query.isEmpty) return _books;

    return _books.where((book) {
      return book.title.toLowerCase().contains(query.toLowerCase()) ||
          book.author.toLowerCase().contains(query.toLowerCase()) ||
          book.description.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  Book? getBookById(String id) {
    try {
      return _books.firstWhere((book) => book.id == id);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // 手動重新載入資料
  Future<void> refreshBooks() async {
    await _loadBooks();
  }

  // 強制重新載入（假資料模式）
  Future<void> forceRefreshFromAPI() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 在假資料模式下，重新載入模擬資料
      _loadMockData();
      _error = null;
      DebugHelper.log('強制重新載入假資料完成', tag: 'BookProvider');
    } catch (e) {
      _error = '重新載入失敗：${e.toString()}';
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

  // 載入分頁資料（假資料模式）
  Future<void> loadBooksWithPagination({
    String? category,
    String? searchQuery,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      DebugHelper.log('載入分頁資料（假資料模式）- 第 $page 頁', tag: 'BookProvider');

      // 使用假資料進行分頁
      List<Book> filteredBooks = List.from(_mockBooks);

      // 根據分類篩選
      if (category != null && category.isNotEmpty) {
        filteredBooks = filteredBooks
            .where((book) => book.category == category)
            .toList();
      }

      // 根據搜尋關鍵字篩選
      if (searchQuery != null && searchQuery.isNotEmpty) {
        filteredBooks = filteredBooks.where((book) {
          return book.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
              book.author.toLowerCase().contains(searchQuery.toLowerCase()) ||
              book.description.toLowerCase().contains(
                searchQuery.toLowerCase(),
              );
        }).toList();
      }

      // 計算分頁
      final startIndex = (page - 1) * pageSize;
      final endIndex = startIndex + pageSize;
      final newBooks = filteredBooks.skip(startIndex).take(pageSize).toList();

      if (page == 1) {
        _books = newBooks;
      } else {
        _books.addAll(newBooks);
      }

      _currentPage = page;
      _totalCount = filteredBooks.length;
      _hasMore = endIndex < filteredBooks.length;

      DebugHelper.log(
        '假資料分頁載入完成 - 第 $page 頁，共 ${newBooks.length} 本書籍，總計 $_totalCount 本',
        tag: 'BookProvider',
      );
    } catch (e) {
      DebugHelper.log('假資料分頁載入失敗: ${e.toString()}', tag: 'BookProvider');
      _error = '載入失敗：${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 載入更多資料（假資料模式）
  Future<void> loadMoreBooks({String? category, String? searchQuery}) async {
    if (!_hasMore || _isLoading) return;

    await loadBooksWithPagination(
      category: category,
      searchQuery: searchQuery,
      page: _currentPage + 1,
      pageSize: _pageSize,
    );
  }

  // 重置分頁狀態
  void resetPagination() {
    _currentPage = 1;
    _totalCount = 0;
    _hasMore = true;
    _books.clear();
  }

  // 根據endpoint載入對應的假資料
  Future<void> loadBooksByEndpoint(String endpoint) async {
    try {
      _isLoading = true;
      notifyListeners();

      DebugHelper.log('根據endpoint載入假資料: $endpoint', tag: 'BookProvider');

      // 根據endpoint載入對應的假資料
      switch (endpoint) {
        case '/api/books/today-deals':
          _books = _mockBooks.where((book) => book.price < 500).toList();
          break;
        case '/api/books/bestsellers':
          _books = _mockBooks.where((book) => book.rating > 4.5).toList();
          break;
        case '/api/books/new-releases':
          _books = _mockBooks
              .where(
                (book) => book.publishDate.isAfter(
                  DateTime.now().subtract(const Duration(days: 30)),
                ),
              )
              .toList();
          break;
        case '/api/books/used-books':
          _books = _mockBooks.where((book) => book.price < 300).toList();
          break;
        default:
          _books = List.from(_mockBooks);
      }

      _totalCount = _books.length;
      _hasMore = false; // 假資料模式下，一次性載入所有資料
      _currentPage = 1;
      _error = null;

      DebugHelper.log(
        'endpoint假資料載入完成: $endpoint，共 ${_books.length} 本書籍',
        tag: 'BookProvider',
      );
    } catch (e) {
      DebugHelper.log('endpoint假資料載入失敗: ${e.toString()}', tag: 'BookProvider');
      _error = '載入失敗：${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
