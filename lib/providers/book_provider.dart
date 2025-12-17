import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/book.dart';
import '../utils/debug_helper.dart';
import '../config/api_config.dart';

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

  static const String taazeNewArrivalsEndpoint =
      'https://www.taaze.tw/beta/actAllBooksDataAgent.jsp?t=11&a=02&d=00&l=0&c=00&k=01';

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
    // 注目新品 - 最近30天內出版
    Book(
      id: '13',
      title: 'Vue.js 3.0 完全指南',
      author: '張新星',
      description: 'Vue.js 3.0 的最新特性與實戰應用，從基礎到進階的完整學習路徑。',
      price: 599.0,
      imageUrl: 'https://picsum.photos/300/400?random=13',
      category: '程式設計',
      rating: 4.8,
      reviewCount: 45,
      isAvailable: true,
      publishDate: DateTime.now().subtract(const Duration(days: 5)),
      isbn: '9781234567902',
      pages: 420,
      publisher: '前端新星出版社',
    ),
    Book(
      id: '14',
      title: 'SwiftUI 設計模式',
      author: '李蘋果',
      description: '使用 SwiftUI 開發 iOS 應用的最佳實踐和設計模式。',
      price: 699.0,
      imageUrl: 'https://picsum.photos/300/400?random=14',
      category: '程式設計',
      rating: 4.7,
      reviewCount: 32,
      isAvailable: true,
      publishDate: DateTime.now().subtract(const Duration(days: 12)),
      isbn: '9781234567903',
      pages: 380,
      publisher: '蘋果開發出版社',
    ),
    Book(
      id: '15',
      title: 'Figma 設計系統',
      author: '王設計師',
      description: '使用 Figma 建立企業級設計系統的完整指南。',
      price: 499.0,
      imageUrl: 'https://picsum.photos/300/400?random=15',
      category: '設計',
      rating: 4.6,
      reviewCount: 28,
      isAvailable: true,
      publishDate: DateTime.now().subtract(const Duration(days: 8)),
      isbn: '9781234567904',
      pages: 320,
      publisher: '設計工具出版社',
    ),
    Book(
      id: '16',
      title: 'ChatGPT 應用開發',
      author: '陳AI',
      description: '使用 ChatGPT API 開發智能應用的實戰教程。',
      price: 799.0,
      imageUrl: 'https://picsum.photos/300/400?random=16',
      category: '人工智慧',
      rating: 4.9,
      reviewCount: 67,
      isAvailable: true,
      publishDate: DateTime.now().subtract(const Duration(days: 3)),
      isbn: '9781234567905',
      pages: 450,
      publisher: 'AI應用出版社',
    ),
    Book(
      id: '17',
      title: 'Kubernetes 實戰',
      author: '趙雲端',
      description: 'Kubernetes 容器編排的實戰應用和最佳實踐。',
      price: 649.0,
      imageUrl: 'https://picsum.photos/300/400?random=17',
      category: '雲端運算',
      rating: 4.5,
      reviewCount: 41,
      isAvailable: true,
      publishDate: DateTime.now().subtract(const Duration(days: 15)),
      isbn: '9781234567906',
      pages: 480,
      publisher: '雲端技術出版社',
    ),
    Book(
      id: '18',
      title: 'TypeScript 進階',
      author: '孫類型',
      description: 'TypeScript 進階特性與大型專案開發實戰。',
      price: 549.0,
      imageUrl: 'https://picsum.photos/300/400?random=18',
      category: '程式設計',
      rating: 4.7,
      reviewCount: 38,
      isAvailable: true,
      publishDate: DateTime.now().subtract(const Duration(days: 20)),
      isbn: '9781234567907',
      pages: 360,
      publisher: '類型安全出版社',
    ),
    // 二手書 - 價格較低
    Book(
      id: '19',
      title: 'Java 基礎教程',
      author: '周咖啡',
      description: 'Java 程式設計基礎教程，適合初學者學習。',
      price: 199.0,
      imageUrl: 'https://picsum.photos/300/400?random=19',
      category: '程式設計',
      rating: 4.2,
      reviewCount: 156,
      isAvailable: true,
      publishDate: DateTime(2023, 8, 15),
      isbn: '9781234567908',
      pages: 280,
      publisher: '咖啡豆出版社',
    ),
    Book(
      id: '20',
      title: 'HTML5 與 CSS3',
      author: '吳網頁',
      description: 'HTML5 和 CSS3 的基礎知識與實戰應用。',
      price: 179.0,
      imageUrl: 'https://picsum.photos/300/400?random=20',
      category: '程式設計',
      rating: 4.1,
      reviewCount: 89,
      isAvailable: true,
      publishDate: DateTime(2023, 6, 20),
      isbn: '9781234567909',
      pages: 240,
      publisher: '網頁技術出版社',
    ),
    Book(
      id: '21',
      title: 'Photoshop 入門',
      author: '鄭美工',
      description: 'Photoshop 基礎操作與圖片處理技巧。',
      price: 159.0,
      imageUrl: 'https://picsum.photos/300/400?random=21',
      category: '設計',
      rating: 4.0,
      reviewCount: 124,
      isAvailable: true,
      publishDate: DateTime(2023, 5, 10),
      isbn: '9781234567910',
      pages: 200,
      publisher: '美工設計出版社',
    ),
    Book(
      id: '22',
      title: 'Excel 進階應用',
      author: '劉表格',
      description: 'Excel 進階功能與數據分析技巧。',
      price: 129.0,
      imageUrl: 'https://picsum.photos/300/400?random=22',
      category: '辦公軟體',
      rating: 3.9,
      reviewCount: 78,
      isAvailable: true,
      publishDate: DateTime(2023, 4, 25),
      isbn: '9781234567911',
      pages: 180,
      publisher: '辦公軟體出版社',
    ),
    Book(
      id: '23',
      title: 'Word 文書處理',
      author: '陳文書',
      description: 'Microsoft Word 文書處理與排版技巧。',
      price: 149.0,
      imageUrl: 'https://picsum.photos/300/400?random=23',
      category: '辦公軟體',
      rating: 3.8,
      reviewCount: 65,
      isAvailable: true,
      publishDate: DateTime(2023, 3, 18),
      isbn: '9781234567912',
      pages: 160,
      publisher: '文書處理出版社',
    ),
    Book(
      id: '24',
      title: 'PowerPoint 簡報設計',
      author: '林簡報',
      description: 'PowerPoint 簡報設計與製作技巧。',
      price: 139.0,
      imageUrl: 'https://picsum.photos/300/400?random=24',
      category: '辦公軟體',
      rating: 3.7,
      reviewCount: 52,
      isAvailable: true,
      publishDate: DateTime(2023, 2, 28),
      isbn: '9781234567913',
      pages: 140,
      publisher: '簡報設計出版社',
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
  // 從 API 取得資料（指定 endpoint 與範圍），失敗時拋出例外
  Future<List<Book>> _fetchBooksFromAPI({
    required String endpoint,
    int startNum = 0,
    int endNum = 19,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}$endpoint?startNum=$startNum&endNum=$endNum',
      );
      DebugHelper.logApiRequest('GET', uri.toString());

      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      DebugHelper.logApiResponse(response.statusCode, response.body);

      if (response.statusCode != 200) {
        throw Exception('status ${response.statusCode}');
      }

      final dynamic decoded = json.decode(response.body);
      List<dynamic> jsonList;

      if (decoded is Map && decoded['data'] is List) {
        jsonList = decoded['data'] as List<dynamic>;
        _totalCount = decoded['total_count'] ??
            decoded['totalCount'] ??
            decoded['total'] ??
            jsonList.length;
      } else if (decoded is List) {
        jsonList = decoded;
        _totalCount = jsonList.length;
      } else {
        throw Exception('unexpected response format');
      }

      return jsonList.map((json) => _bookFromJson(json)).toList();
    } catch (e) {
      DebugHelper.log('API調用異常: ${e.toString()}', tag: 'BookProvider');
      rethrow;
    }
  }

  // 從 JSON 創建 Book 物件（暫時註解，使用假資料模式）
  Book _bookFromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['imageUrl']?.toString() ??
          json['coverImage']?.toString() ??
          '',
      category: json['category']?.toString() ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? json['reviews'] ?? 0,
      isAvailable: json['isAvailable'] ?? json['stock'] != 0,
      publishDate: json['publishDate'] != null
          ? DateTime.tryParse(json['publishDate']) ?? DateTime.now()
          : DateTime.now(),
      isbn: json['isbn']?.toString() ?? '',
      pages: json['pages'] ?? 0,
      publisher: json['publisher']?.toString() ?? '',
    );
  }

  // 載入模擬資料
  void _loadMockData() {
    _books = List.from(_mockBooks);
    _featuredBooks = _books.take(4).toList();
    _categories = _books.map((book) => book.category).toSet().toList();

    // 同時載入四個板塊的模擬資料
    _todayDeals = _mockBooks.where((book) => book.price < 500).take(6).toList();
    
    // 暢銷排行榜 - 按評分降序排序
    _bestsellers = _mockBooks.where((book) => book.rating > 4.5).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating))
      ..take(6).toList();
    
    // 注目新品 - 最近30天內出版的書籍，按出版日期降序排序
    _newReleases = _mockBooks
        .where(
          (book) => book.publishDate.isAfter(
            DateTime.now().subtract(const Duration(days: 30)),
          ),
        )
        .toList()
      ..sort((a, b) => b.publishDate.compareTo(a.publishDate))
      ..take(6).toList();
    
    // 最新上架二手書 - 價格較低的書籍，按出版日期降序排序
    _usedBooks = _mockBooks.where((book) => book.price < 300).toList()
      ..sort((a, b) => b.publishDate.compareTo(a.publishDate))
      ..take(6).toList();
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

  // 根據endpoint載入對應的假資料，可附帶起迄索引；append可累加資料
  Future<void> loadBooksByEndpoint(
    String endpoint, {
    int startNum = 0,
    int endNum = 19,
    bool append = false,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      DebugHelper.log('根據endpoint載入資料: $endpoint', tag: 'BookProvider');

      if (_isTaazeActEndpoint(endpoint)) {
        final chunk = await _fetchTaazeActBooks(
          url: endpoint,
          startNum: startNum,
          endNum: endNum,
        );
        _updateBooksFromEndpointChunk(chunk, append);
        return;
      }

      // 根據endpoint載入對應的假資料
      List<Book> filteredBooks;
      switch (endpoint) {
        case '/content/deals/today':
        case '/api/books/today-deals':
          filteredBooks = _mockBooks.where((book) => book.price < 500).toList();
          break;
        case '/content/bestsellers':
        case '/api/books/bestsellers':
          // 先嘗試 API，失敗再回落 mock，並記錄 log
          try {
            filteredBooks = await _fetchBooksFromAPI(
              endpoint: endpoint,
              startNum: startNum,
              endNum: endNum,
            );
            DebugHelper.log('暢銷榜資料已由API取得', tag: 'BookProvider');
          } catch (e) {
            DebugHelper.log(
              '暢銷榜API取得失敗，改用mock資料: ${e.toString()}',
              tag: 'BookProvider',
            );
            filteredBooks =
                _mockBooks.where((book) => book.rating > 4.5).toList();
          }
          break;
        case '/api/books/new-releases':
          filteredBooks = _mockBooks
              .where(
                (book) => book.publishDate.isAfter(
                  DateTime.now().subtract(const Duration(days: 30)),
                ),
              )
              .toList()
            ..sort((a, b) => b.publishDate.compareTo(a.publishDate));
          break;
        case ApiConfig.newArrivalsEndpoint:
        case ApiConfig.ebookNewArrivalsEndpoint:
          filteredBooks = await _fetchBooksFromAPI(
            endpoint: endpoint,
            startNum: startNum,
            endNum: endNum,
          );
          break;
        case '/api/books/used-books':
          filteredBooks = _mockBooks.where((book) => book.price < 300).toList()
            ..sort((a, b) => b.publishDate.compareTo(a.publishDate));
          break;
        default:
          filteredBooks = List.from(_mockBooks);
      }

      _totalCount = filteredBooks.length;

      // 套用起迄索引（endNum 包含），避免越界
      final safeStart = startNum < 0 ? 0 : startNum;
      final safeEndExclusive =
          (endNum + 1).clamp(safeStart, filteredBooks.length).toInt();
      final chunk = filteredBooks
          .skip(safeStart)
          .take(safeEndExclusive - safeStart)
          .toList();

      _updateBooksFromEndpointChunk(chunk, append);

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

  bool _isTaazeActEndpoint(String endpoint) {
    return endpoint.contains('actAllBooksDataAgent.jsp');
  }

  Future<List<Book>> _fetchTaazeActBooks({
    required String url,
    required int startNum,
    required int endNum,
  }) async {
    try {
      final uri = Uri.parse(url);
      final params = Map<String, String>.from(uri.queryParameters);
      params['startNum'] = startNum.toString();
      params['endNum'] = endNum.toString();
      final finalUri = uri.replace(queryParameters: params);

      DebugHelper.logApiRequest('GET', finalUri.toString());
      final response = await http
          .get(finalUri)
          .timeout(const Duration(seconds: 10));

      final encoding = Encoding.getByName('big5') ?? utf8;
      final body = encoding.decode(response.bodyBytes);
      DebugHelper.logApiResponse(response.statusCode, body);

      if (response.statusCode != 200) {
        throw Exception('status ${response.statusCode}');
      }

      final decoded = json.decode(body);
      final List<dynamic> items =
          (decoded['result1'] as List?) ?? (decoded['result'] as List?) ?? [];
      final totalValue =
          decoded['totalsize'] ?? decoded['totalSize'] ?? decoded['total'];
      _totalCount =
          int.tryParse(totalValue?.toString() ?? '') ?? items.length;

      return items
          .map(
            (item) =>
                _bookFromTaazeJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } catch (e) {
      DebugHelper.log('Taaze API 調用異常: ${e.toString()}', tag: 'BookProvider');
      rethrow;
    }
  }

  Book _bookFromTaazeJson(Map<String, dynamic> json) {
    final prodId = json['prodId']?.toString() ??
        json['orgProdId']?.toString() ??
        '';
    final salePrice = double.tryParse(json['salePrice']?.toString() ?? '') ??
        double.tryParse(json['listPrice']?.toString() ?? '') ??
        0.0;
    final publishDate = DateTime.tryParse(
          json['publishDate']?.toString() ?? '',
        ) ??
        DateTime.now();
    final isOutOfPrint =
        (json['outOfPrint']?.toString().toUpperCase() ?? 'N') == 'Y';

    final description =
        (json['prodPf']?.toString() ?? '').replaceAll('<br>', '\n');
    final imageUrl = prodId.isNotEmpty
        ? 'https://media.taaze.tw/showThumbnail.html?sc=$prodId&height=400&width=310'
        : '';

    return Book(
      id: prodId,
      title: json['titleMain']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      description: description,
      price: salePrice,
      imageUrl: imageUrl,
      category: json['prodCatNm']?.toString() ?? '',
      rating: double.tryParse(json['starLevel']?.toString() ?? '') ?? 0,
      reviewCount: int.tryParse(json['seekNum']?.toString() ?? '') ?? 0,
      isAvailable: !isOutOfPrint,
      publishDate: publishDate,
      isbn: json['isbn']?.toString() ?? '',
      pages: 0,
      publisher: json['pubNmMain']?.toString() ?? '',
    );
  }

  void _updateBooksFromEndpointChunk(List<Book> chunk, bool append) {
    if (append) {
      _books.addAll(chunk);
    } else {
      _books = chunk;
    }

    _hasMore = _books.length < _totalCount;
    _currentPage = 1;
    _error = null;
  }
}
