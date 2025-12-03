import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';
import '../utils/debug_helper.dart';
import '../config/api_config.dart';

class SearchService {
  static String get baseUrl => ApiConfig.baseUrl;
  static const Duration _timeout = Duration(seconds: 10);

  /// 搜尋書籍
  ///
  /// [keyword] 搜尋關鍵字
  /// [page] 頁碼，從1開始
  /// [pageSize] 每頁數量，預設20
  /// [sort] 排序方式，可選值：title, author, price, rating, publishDate
  /// [order] 排序順序，可選值：asc, desc
  ///
  /// 返回搜尋結果列表
  static Future<List<Book>> searchBooks({
    required String keyword,
    int page = 1,
    int pageSize = 20,
    String? sort,
    String? order,
  }) async {
    try {
      // 構建查詢參數
      final queryParams = <String, String>{
        'q': keyword,
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

      // 添加可選的排序參數
      if (sort != null) {
        queryParams['sort'] = sort;
      }
      if (order != null) {
        queryParams['order'] = order;
      }

      final uri = Uri.parse(
        '$baseUrl/search',
      ).replace(queryParameters: queryParams);
      DebugHelper.logApiRequest('GET', uri.toString());

      final response = await http.get(uri).timeout(_timeout);
      DebugHelper.logApiResponse(response.statusCode, response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // 處理API響應格式
        List<dynamic> booksData;
        if (responseData.containsKey('data')) {
          booksData = responseData['data'];
        } else if (responseData.containsKey('books')) {
          booksData = responseData['books'];
        } else if (responseData.containsKey('results')) {
          booksData = responseData['results'];
        } else {
          // 如果直接是數組格式
          booksData = responseData as List<dynamic>;
        }

        final books = booksData.map((json) => _bookFromJson(json)).toList();

        DebugHelper.log('搜尋成功，找到 ${books.length} 本書籍', tag: 'SearchService');
        return books;
      } else {
        throw Exception('搜尋API返回錯誤狀態碼: ${response.statusCode}');
      }
    } catch (e) {
      DebugHelper.log('搜尋API調用失敗: ${e.toString()}', tag: 'SearchService');

      // 如果API調用失敗，返回模擬搜尋結果
      return getMockSearchResults(
        keyword,
        page: page,
        pageSize: pageSize,
        sort: sort,
        order: order,
      );
    }
  }

  /// 從JSON創建Book物件
  static Book _bookFromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] ?? 0).toDouble(),
      imageUrl:
          json['imageUrl']?.toString() ?? json['cover_url']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? json['review_count'] ?? 0,
      isAvailable: json['isAvailable'] ?? json['is_available'] ?? true,
      publishDate: json['publishDate'] != null
          ? DateTime.parse(json['publishDate'])
          : json['publish_date'] != null
          ? DateTime.parse(json['publish_date'])
          : DateTime.now(),
      isbn: json['isbn']?.toString() ?? '',
      pages: json['pages'] ?? 0,
      publisher: json['publisher']?.toString() ?? '',
    );
  }

  /// 獲取模擬搜尋結果（當API不可用時使用）
  static List<Book> getMockSearchResults(
    String keyword, {
    int page = 1,
    int pageSize = 20,
    String? sort,
    String? order,
  }) {
    final mockBooks = [
      // 程式設計類書籍
      Book(
        id: 'search_1',
        title: 'Flutter開發實戰指南',
        author: '張三',
        description: '這是一本關於Flutter開發的實戰指南，涵蓋了從基礎到進階的所有內容。適合想要學習跨平台開發的開發者。',
        price: 599.0,
        imageUrl: 'https://picsum.photos/300/400?random=101',
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
        id: 'search_2',
        title: 'Dart語言入門與實戰',
        author: '李四',
        description: '學習Dart程式語言的完整指南，適合初學者。從基礎語法到進階概念，全面掌握Dart開發。',
        price: 399.0,
        imageUrl: 'https://picsum.photos/300/400?random=102',
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
        id: 'search_5',
        title: 'React Native跨平台開發',
        author: '陳九',
        description: '使用React Native開發跨平台移動應用的完整指南。從基礎到進階，掌握跨平台開發技巧。',
        price: 599.0,
        imageUrl: 'https://picsum.photos/300/400?random=105',
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
        id: 'search_8',
        title: 'JavaScript進階程式設計',
        author: '鄭十三',
        description: '深入學習JavaScript進階概念，包括ES6+、非同步程式設計等。適合有一定基礎的開發者。',
        price: 549.0,
        imageUrl: 'https://picsum.photos/300/400?random=108',
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
        id: 'search_9',
        title: 'Java核心技術',
        author: '劉十五',
        description: 'Java程式設計的核心技術和最佳實踐，從基礎語法到企業級應用開發。',
        price: 649.0,
        imageUrl: 'https://picsum.photos/300/400?random=109',
        category: '程式設計',
        rating: 4.7,
        reviewCount: 178,
        isAvailable: true,
        publishDate: DateTime(2024, 1, 30),
        isbn: '9781234567902',
        pages: 520,
        publisher: 'Java出版社',
      ),
      Book(
        id: 'search_10',
        title: 'Python程式設計入門',
        author: '吳十六',
        description: 'Python程式語言的完整學習指南，從基礎語法到實際應用，適合初學者。',
        price: 499.0,
        imageUrl: 'https://picsum.photos/300/400?random=110',
        category: '程式設計',
        rating: 4.4,
        reviewCount: 156,
        isAvailable: true,
        publishDate: DateTime(2024, 2, 5),
        isbn: '9781234567903',
        pages: 380,
        publisher: 'Python出版社',
      ),
      Book(
        id: 'search_11',
        title: 'C++程式設計實戰',
        author: '許十七',
        description: 'C++程式設計的實戰指南，涵蓋物件導向程式設計和STL使用。',
        price: 579.0,
        imageUrl: 'https://picsum.photos/300/400?random=111',
        category: '程式設計',
        rating: 4.5,
        reviewCount: 98,
        isAvailable: true,
        publishDate: DateTime(2024, 3, 1),
        isbn: '9781234567904',
        pages: 420,
        publisher: 'C++出版社',
      ),
      Book(
        id: 'search_12',
        title: 'Swift iOS開發指南',
        author: '蔡十八',
        description: '使用Swift開發iOS應用的完整指南，從基礎到App Store上架。',
        price: 699.0,
        imageUrl: 'https://picsum.photos/300/400?random=112',
        category: '程式設計',
        rating: 4.8,
        reviewCount: 167,
        isAvailable: true,
        publishDate: DateTime(2024, 1, 20),
        isbn: '9781234567905',
        pages: 480,
        publisher: 'iOS出版社',
      ),

      // 設計類書籍
      Book(
        id: 'search_3',
        title: '移動應用UI設計',
        author: '王五',
        description: '現代移動應用UI/UX設計的最佳實踐。學習如何設計出用戶喜愛的應用程式界面。',
        price: 699.0,
        imageUrl: 'https://picsum.photos/300/400?random=103',
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
        id: 'search_7',
        title: '現代UI設計原則',
        author: '黃十一',
        description: '現代UI設計的核心原則和最佳實踐，提升用戶體驗設計能力。適合設計師和開發者閱讀。',
        price: 499.0,
        imageUrl: 'https://picsum.photos/300/400?random=107',
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
        id: 'search_13',
        title: '平面設計基礎',
        author: '謝十九',
        description: '平面設計的基本原理和技巧，從色彩搭配到版面設計的完整指南。',
        price: 429.0,
        imageUrl: 'https://picsum.photos/300/400?random=113',
        category: '設計',
        rating: 4.3,
        reviewCount: 87,
        isAvailable: true,
        publishDate: DateTime(2024, 2, 12),
        isbn: '9781234567906',
        pages: 280,
        publisher: '平面設計出版社',
      ),
      Book(
        id: 'search_14',
        title: '網頁設計與開發',
        author: '羅二十',
        description: '現代網頁設計的完整指南，從HTML/CSS到響應式設計。',
        price: 599.0,
        imageUrl: 'https://picsum.photos/300/400?random=114',
        category: '設計',
        rating: 4.6,
        reviewCount: 134,
        isAvailable: true,
        publishDate: DateTime(2024, 1, 8),
        isbn: '9781234567907',
        pages: 380,
        publisher: '網頁設計出版社',
      ),

      // 人工智慧類書籍
      Book(
        id: 'search_4',
        title: '人工智慧基礎與應用',
        author: '趙六',
        description: '人工智慧的基本概念和應用實例。從機器學習到深度學習，全面了解AI技術。',
        price: 799.0,
        imageUrl: 'https://picsum.photos/300/400?random=104',
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
        id: 'search_6',
        title: 'Python機器學習實戰',
        author: '林十',
        description: '使用Python進行機器學習的實用教程，包含豐富的實例和案例。適合想要學習機器學習的開發者。',
        price: 699.0,
        imageUrl: 'https://picsum.photos/300/400?random=106',
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
        id: 'search_15',
        title: '深度學習入門',
        author: '江二十一',
        description: '深度學習的基本概念和實作方法，從神經網路到卷積神經網路。',
        price: 749.0,
        imageUrl: 'https://picsum.photos/300/400?random=115',
        category: '人工智慧',
        rating: 4.7,
        reviewCount: 145,
        isAvailable: true,
        publishDate: DateTime(2024, 2, 28),
        isbn: '9781234567908',
        pages: 460,
        publisher: '深度學習出版社',
      ),
      Book(
        id: 'search_16',
        title: '自然語言處理實務',
        author: '何二十二',
        description: '自然語言處理技術的實際應用，從文本分析到聊天機器人開發。',
        price: 679.0,
        imageUrl: 'https://picsum.photos/300/400?random=116',
        category: '人工智慧',
        rating: 4.5,
        reviewCount: 112,
        isAvailable: true,
        publishDate: DateTime(2024, 1, 12),
        isbn: '9781234567909',
        pages: 390,
        publisher: 'NLP出版社',
      ),

      // 資料庫類書籍
      Book(
        id: 'search_17',
        title: 'MySQL資料庫管理',
        author: '孫二十三',
        description: 'MySQL資料庫的安裝、配置和管理，從基礎到進階的完整指南。',
        price: 529.0,
        imageUrl: 'https://picsum.photos/300/400?random=117',
        category: '資料庫',
        rating: 4.4,
        reviewCount: 98,
        isAvailable: true,
        publishDate: DateTime(2024, 2, 18),
        isbn: '9781234567910',
        pages: 340,
        publisher: '資料庫出版社',
      ),
      Book(
        id: 'search_18',
        title: 'MongoDB實戰指南',
        author: '周二十四',
        description: 'NoSQL資料庫MongoDB的實戰應用，從基礎操作到進階查詢。',
        price: 579.0,
        imageUrl: 'https://picsum.photos/300/400?random=118',
        category: '資料庫',
        rating: 4.6,
        reviewCount: 76,
        isAvailable: true,
        publishDate: DateTime(2024, 1, 25),
        isbn: '9781234567911',
        pages: 360,
        publisher: 'NoSQL出版社',
      ),

      // 網路安全類書籍
      Book(
        id: 'search_19',
        title: '網路安全基礎',
        author: '吳二十五',
        description: '網路安全的基本概念和防護措施，保護系統免受網路威脅。',
        price: 649.0,
        imageUrl: 'https://picsum.photos/300/400?random=119',
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
        id: 'search_20',
        title: '密碼學與資訊安全',
        author: '鄭二十六',
        description: '密碼學的基本原理和資訊安全技術，從對稱加密到公開金鑰系統。',
        price: 729.0,
        imageUrl: 'https://picsum.photos/300/400?random=120',
        category: '網路安全',
        rating: 4.8,
        reviewCount: 89,
        isAvailable: true,
        publishDate: DateTime(2024, 3, 8),
        isbn: '9781234567912',
        pages: 420,
        publisher: '密碼學出版社',
      ),

      // 雲端運算類書籍
      Book(
        id: 'search_21',
        title: 'AWS雲端服務實戰',
        author: '林二十七',
        description: 'Amazon Web Services的實戰應用，從基礎服務到進階架構設計。',
        price: 799.0,
        imageUrl: 'https://picsum.photos/300/400?random=121',
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
        id: 'search_22',
        title: 'Docker容器技術',
        author: '陳二十八',
        description: 'Docker容器化技術的完整指南，從基礎概念到生產環境部署。',
        price: 549.0,
        imageUrl: 'https://picsum.photos/300/400?random=122',
        category: '雲端運算',
        rating: 4.5,
        reviewCount: 123,
        isAvailable: true,
        publishDate: DateTime(2024, 2, 14),
        isbn: '9781234567913',
        pages: 320,
        publisher: '容器技術出版社',
      ),

      // 區塊鏈類書籍
      Book(
        id: 'search_23',
        title: '區塊鏈技術原理',
        author: '劉二十九',
        description: '區塊鏈技術原理與應用，了解數位貨幣和智能合約的基礎。',
        price: 649.0,
        imageUrl: 'https://picsum.photos/300/400?random=123',
        category: '區塊鏈',
        rating: 4.3,
        reviewCount: 87,
        isAvailable: true,
        publishDate: DateTime(2024, 1, 30),
        isbn: '9781234567901',
        pages: 400,
        publisher: '區塊鏈出版社',
      ),
      Book(
        id: 'search_24',
        title: '以太坊智能合約開發',
        author: '黃三十',
        description: '以太坊平台上的智能合約開發，從Solidity語言到DApp開發。',
        price: 699.0,
        imageUrl: 'https://picsum.photos/300/400?random=124',
        category: '區塊鏈',
        rating: 4.6,
        reviewCount: 95,
        isAvailable: true,
        publishDate: DateTime(2024, 2, 22),
        isbn: '9781234567914',
        pages: 380,
        publisher: '以太坊出版社',
      ),

      // 更多程式設計書籍
      Book(
        id: 'search_25',
        title: 'Vue.js前端開發',
        author: '王三十一',
        description: 'Vue.js框架的完整學習指南，從基礎到進階的前端開發技術。',
        price: 579.0,
        imageUrl: 'https://picsum.photos/300/400?random=125',
        category: '程式設計',
        rating: 4.5,
        reviewCount: 134,
        isAvailable: true,
        publishDate: DateTime(2024, 1, 18),
        isbn: '9781234567915',
        pages: 360,
        publisher: 'Vue出版社',
      ),
      Book(
        id: 'search_26',
        title: 'Node.js後端開發',
        author: '李三十二',
        description: '使用Node.js開發後端服務的完整指南，從Express到微服務架構。',
        price: 629.0,
        imageUrl: 'https://picsum.photos/300/400?random=126',
        category: '程式設計',
        rating: 4.6,
        reviewCount: 156,
        isAvailable: true,
        publishDate: DateTime(2024, 2, 8),
        isbn: '9781234567916',
        pages: 420,
        publisher: 'Node.js出版社',
      ),
      Book(
        id: 'search_27',
        title: 'Go語言程式設計',
        author: '張三十三',
        description: 'Go語言的高效程式設計，從基礎語法到並發程式設計。',
        price: 549.0,
        imageUrl: 'https://picsum.photos/300/400?random=127',
        category: '程式設計',
        rating: 4.7,
        reviewCount: 98,
        isAvailable: true,
        publishDate: DateTime(2024, 3, 12),
        isbn: '9781234567917',
        pages: 340,
        publisher: 'Go語言出版社',
      ),
      Book(
        id: 'search_28',
        title: 'Rust系統程式設計',
        author: '陳三十四',
        description: 'Rust語言的系統程式設計，從記憶體安全到高效能應用開發。',
        price: 679.0,
        imageUrl: 'https://picsum.photos/300/400?random=128',
        category: '程式設計',
        rating: 4.8,
        reviewCount: 76,
        isAvailable: true,
        publishDate: DateTime(2024, 1, 28),
        isbn: '9781234567918',
        pages: 400,
        publisher: 'Rust出版社',
      ),

      // 更多設計書籍
      Book(
        id: 'search_29',
        title: '品牌設計策略',
        author: '劉三十五',
        description: '品牌設計的策略思維和實作方法，從視覺識別到品牌體驗。',
        price: 599.0,
        imageUrl: 'https://picsum.photos/300/400?random=129',
        category: '設計',
        rating: 4.4,
        reviewCount: 89,
        isAvailable: true,
        publishDate: DateTime(2024, 2, 16),
        isbn: '9781234567919',
        pages: 320,
        publisher: '品牌設計出版社',
      ),
      Book(
        id: 'search_30',
        title: '互動設計原理',
        author: '黃三十六',
        description: '互動設計的基本原理和實作技巧，提升用戶體驗設計能力。',
        price: 529.0,
        imageUrl: 'https://picsum.photos/300/400?random=130',
        category: '設計',
        rating: 4.5,
        reviewCount: 112,
        isAvailable: true,
        publishDate: DateTime(2024, 1, 22),
        isbn: '9781234567920',
        pages: 300,
        publisher: '互動設計出版社',
      ),
    ];

    // 根據關鍵字篩選模擬結果
    List<Book> filteredBooks;
    if (keyword.isEmpty) {
      filteredBooks = List.from(mockBooks);
    } else {
      filteredBooks = mockBooks.where((book) {
        return book.title.toLowerCase().contains(keyword.toLowerCase()) ||
            book.author.toLowerCase().contains(keyword.toLowerCase()) ||
            book.description.toLowerCase().contains(keyword.toLowerCase()) ||
            book.category.toLowerCase().contains(keyword.toLowerCase());
      }).toList();
    }

    // 應用排序
    if (sort != null) {
      filteredBooks.sort((a, b) {
        int comparison = 0;
        switch (sort) {
          case 'title':
            comparison = a.title.compareTo(b.title);
            break;
          case 'author':
            comparison = a.author.compareTo(b.author);
            break;
          case 'price':
            comparison = a.price.compareTo(b.price);
            break;
          case 'rating':
            comparison = a.rating.compareTo(b.rating);
            break;
          case 'publishDate':
            comparison = a.publishDate.compareTo(b.publishDate);
            break;
          default:
            comparison = 0;
        }

        // 根據排序順序決定是否反轉
        if (order == 'desc') {
          comparison = -comparison;
        }

        return comparison;
      });
    }

    // 模擬分頁
    final startIndex = (page - 1) * pageSize;

    if (startIndex >= filteredBooks.length) {
      return []; // 沒有更多資料
    }

    return filteredBooks.skip(startIndex).take(pageSize).toList();
  }
}
