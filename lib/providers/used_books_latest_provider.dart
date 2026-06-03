import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/book.dart';
import '../utils/api_response_parser.dart';
import '../utils/debug_helper.dart';

class UsedBooksLatestProvider with ChangeNotifier {
  List<Book> _usedBooks = [];
  bool _isLoading = false;
  String? _error;

  List<Book> get usedBooks => _usedBooks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const Duration _timeout = Duration(seconds: 20);
  static const int _defaultStart = 0;
  static const int _defaultEnd = 19;

  UsedBooksLatestProvider() {
    _loadUsedBooks();
  }

  Future<void> _loadUsedBooks() async {
    _isLoading = true;
    notifyListeners();

    DebugHelper.log(
      '開始載入最新上架二手書資料',
      tag: 'UsedBooksLatestProvider',
    );

    try {
      final apiBooks = await _fetchUsedBooksFromAPI(
        startNum: _defaultStart,
        endNum: _defaultEnd,
      );

      _usedBooks = apiBooks;
      _error = null;
      DebugHelper.log(
        '最新上架二手書資料已由API取得，共 ${_usedBooks.length} 筆',
        tag: 'UsedBooksLatestProvider',
      );
    } catch (e) {
      DebugHelper.log(
        '最新上架二手書 API 取得失敗: ${e.toString()}',
        tag: 'UsedBooksLatestProvider',
      );
      _error = '載入失敗：${e.toString()}';
      _usedBooks = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<Book>> _fetchUsedBooksFromAPI({
    required int startNum,
    required int endNum,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.usedBooksLatestEndpoint}',
    ).replace(
      queryParameters: {
        'startNum': startNum.toString(),
        'endNum': endNum.toString(),
      },
    );
    DebugHelper.logApiRequest('GET', uri.toString());

    final response = await http.get(uri).timeout(_timeout);
    DebugHelper.logApiResponse(response.statusCode, response.body);

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final dynamic decoded = json.decode(response.body);
    final listData = ApiResponseParser.extractList(decoded);
    return listData.map((e) => Book.fromJson(e)).toList();
  }

  Future<void> refreshUsedBooks() async {
    await _loadUsedBooks();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}







