import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/book.dart';
import '../models/theme_activity.dart';
import '../utils/debug_helper.dart';

class ThemeContentProvider with ChangeNotifier {
  List<ThemeActivity> _themeActivities = [];
  List<Book> _hotProducts = [];
  bool _isLoading = false;
  String? _error;

  List<ThemeActivity> get themeActivities => _themeActivities;
  List<Book> get hotProducts => _hotProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ThemeContentProvider() {
    load();
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _fetchThemeActivities(),
        _fetchHotProducts(),
      ]);
      _themeActivities = results[0] as List<ThemeActivity>;
      _hotProducts = results[1] as List<Book>;
      if (_themeActivities.isEmpty && _hotProducts.isEmpty) {
        _error = '暫無活動內容';
      }
    } catch (e) {
      _error = '載入失敗：${e.toString()}';
      DebugHelper.log(_error!, tag: 'ThemeContentProvider');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<ThemeActivity>> _fetchThemeActivities() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/content/theme-activities');
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw Exception('主題活動 ${res.statusCode}');
    }
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    final list = decoded is List ? decoded : (decoded['data'] as List? ?? []);
    return list
        .map((e) => ThemeActivity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Book>> _fetchHotProducts() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/content/hot-products');
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw Exception('百貨熱門 ${res.statusCode}');
    }
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    final list = decoded is List ? decoded : (decoded['data'] as List? ?? []);
    return list.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
  }
}
