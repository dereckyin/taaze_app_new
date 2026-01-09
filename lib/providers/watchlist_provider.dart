import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/book_identification_service.dart';

class WatchlistProvider with ChangeNotifier {
  static const String _storageKey = 'local_watchlist';
  List<String> _localIds = [];
  List<dynamic> _remoteItems = [];
  bool _isSyncing = false;
  bool _isLoading = false;

  List<String> get localIds => _localIds;
  List<dynamic> get remoteItems => _remoteItems;
  List<String> get allIds {
    final Set<String> ids = {..._localIds};
    for (var item in _remoteItems) {
      if (item is String) {
        ids.add(item);
      } else if (item is Map && item.containsKey('prod_id')) {
        ids.add(item['prod_id'].toString());
      }
    }
    return ids.toList();
  }

  bool get isSyncing => _isSyncing;
  bool get isLoading => _isLoading;

  WatchlistProvider() {
    _loadFromPrefs();
  }

  /// 獲取遠端暫存清單
  Future<void> fetchRemoteWatchlist(String authToken) async {
    _isLoading = true;
    notifyListeners();

    try {
      final items = await BookIdentificationService.getWatchlist(authToken: authToken);
      _remoteItems = items;
    } catch (e) {
      debugPrint('Error fetching remote watchlist: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_storageKey);
      if (savedJson != null) {
        final decoded = json.decode(savedJson);
        if (decoded is List) {
          _localIds = List<String>.from(decoded);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading watchlist from prefs: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, json.encode(_localIds));
    } catch (e) {
      debugPrint('Error saving watchlist to prefs: $e');
    }
  }

  /// 加入暫存
  Future<bool> addToWatchlist(String id, {String? authToken}) async {
    if (id.isEmpty) return false;

    // 如果已登入，直接打 API
    if (authToken != null && authToken.isNotEmpty) {
      final success = await BookIdentificationService.addToWatchlist(
        [id],
        authToken: authToken,
      );
      return success;
    }

    // 未登入，存本機
    if (!_localIds.contains(id)) {
      _localIds.add(id);
      await _saveToPrefs();
      notifyListeners();
    }
    return true;
  }

  /// 登入後同步本機暫存到後端
  Future<void> syncLocalToBackend(String authToken) async {
    if (_localIds.isEmpty || _isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final success = await BookIdentificationService.addToWatchlist(
        _localIds,
        authToken: authToken,
      );

      if (success) {
        // 同步成功，清空本機暫存
        _localIds.clear();
        await _saveToPrefs();
      }
    } catch (e) {
      debugPrint('Error syncing watchlist to backend: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// 清空本機暫存
  Future<void> clearLocal() async {
    _localIds.clear();
    await _saveToPrefs();
    notifyListeners();
  }
}
