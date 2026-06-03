import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/social_feed_item.dart';
import '../utils/debug_helper.dart';

class SocialFeedProvider with ChangeNotifier {
  List<SocialFeedItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<SocialFeedItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadForUser(String custId) async {
    if (custId.isEmpty) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/content/social/$custId');
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        throw Exception('社群動態 ${res.statusCode}');
      }
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      final list = decoded is List ? decoded : [];
      _items = list
          .map((e) => SocialFeedItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = '載入書友動態失敗';
      DebugHelper.log('$e', tag: 'SocialFeedProvider');
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _items = [];
    _error = null;
    notifyListeners();
  }
}
