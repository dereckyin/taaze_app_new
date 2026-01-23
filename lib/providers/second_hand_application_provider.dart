import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/second_hand_application.dart';
import '../utils/debug_helper.dart';

class SecondHandApplicationProvider with ChangeNotifier {
  List<SecondHandBookApplicationItem> _draftItems = [];
  List<SecondHandBookApplication> _applications = [];
  SecondHandBookApplication? _currentApplication;
  List<SecondHandBookApplicationItem> _currentApplicationItems = [];
  List<Map<String, dynamic>> _watchlistItems = [];
  
  bool _isLoading = false;
  String? _error;

  List<SecondHandBookApplicationItem> get draftItems => _draftItems;
  List<SecondHandBookApplication> get applications => _applications;
  SecondHandBookApplication? get currentApplication => _currentApplication;
  List<SecondHandBookApplicationItem> get currentApplicationItems => _currentApplicationItems;
  List<Map<String, dynamic>> get watchlistItems => _watchlistItems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const Duration _timeout = Duration(seconds: 30);

  /// 獲取草稿列表
  Future<void> fetchDraftItems(String? authToken) async {
    if (authToken == null || authToken.isEmpty) {
      _error = '請先登入';
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/applications/second-hand-book/draft');
      DebugHelper.logApiRequest('GET', uri.toString());

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      ).timeout(_timeout);

      DebugHelper.logApiResponse(response.statusCode, response.body);

      if (response.statusCode == 200) {
        final List<dynamic> decoded = json.decode(response.body);
        _draftItems = decoded
            .map((item) => SecondHandBookApplicationItem.fromJson(item as Map<String, dynamic>))
            .toList();
        _error = null;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _error = '載入草稿失敗：${e.toString()}';
      DebugHelper.log('載入草稿失敗: ${e.toString()}', tag: 'SecondHandApplicationProvider');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 創建申請單
  Future<SecondHandBookApplication?> createApplication({
    required String? authToken,
    required SecondHandBookApplication application,
    required List<SecondHandBookApplicationItem> items,
  }) async {
    if (authToken == null || authToken.isEmpty) {
      _error = '請先登入';
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/applications/second-hand-book');
      DebugHelper.logApiRequest('POST', uri.toString());

      final requestBody = {
        'application': application.toJson(),
        'item_list': items.map((item) => item.toJson()).toList(),
      };

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(_timeout);

      DebugHelper.logApiResponse(response.statusCode, response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        final created = SecondHandBookApplication.fromJson(decoded as Map<String, dynamic>);
        _error = null;
        return created;
      } else {
        final errorBody = json.decode(response.body);
        final errorMsg = errorBody['detail'] ?? '創建申請單失敗';
        throw Exception(errorMsg);
      }
    } catch (e) {
      _error = '創建申請單失敗：${e.toString()}';
      DebugHelper.log('創建申請單失敗: ${e.toString()}', tag: 'SecondHandApplicationProvider');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 自動填充草稿
  Future<bool> autoFillDraft({
    required String? authToken,
    required List<String> orgProdIds,
  }) async {
    if (authToken == null || authToken.isEmpty) {
      _error = '請先登入';
      return false;
    }

    if (orgProdIds.isEmpty) {
      _error = '缺少商品編號';
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/applications/second-hand-book/draft/auto-fill');
      DebugHelper.logApiRequest('POST', uri.toString());

      final requestBody = {
        'org_prod_ids': orgProdIds,
      };

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(_timeout);

      DebugHelper.logApiResponse(response.statusCode, response.body);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final success = decoded['success'] ?? false;
        _error = null;
        return success;
      } else {
        final errorBody = json.decode(response.body);
        final errorMsg = errorBody['detail'] ?? '自動填充失敗';
        throw Exception(errorMsg);
      }
    } catch (e) {
      _error = '自動填充失敗：${e.toString()}';
      DebugHelper.log('自動填充失敗: ${e.toString()}', tag: 'SecondHandApplicationProvider');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 自動填充暫存
  Future<bool> autoFillWatchlist({
    required String? authToken,
    required List<String> prodIds,
  }) async {
    if (authToken == null || authToken.isEmpty) {
      _error = '請先登入';
      return false;
    }

    if (prodIds.isEmpty) {
      _error = '缺少商品編號';
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/applications/watchlist/auto-fill');
      DebugHelper.logApiRequest('POST', uri.toString());

      final requestBody = {
        'prod_ids': prodIds,
      };

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(_timeout);

      DebugHelper.logApiResponse(response.statusCode, response.body);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final success = decoded['success'] ?? false;
        _error = null;
        return success;
      } else {
        final errorBody = json.decode(response.body);
        final errorMsg = errorBody['detail'] ?? '自動填充失敗';
        throw Exception(errorMsg);
      }
    } catch (e) {
      _error = '自動填充失敗：${e.toString()}';
      DebugHelper.log('自動填充失敗: ${e.toString()}', tag: 'SecondHandApplicationProvider');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 獲取暫存列表
  Future<void> fetchWatchlist({
    required String? authToken,
    int months = 3,
  }) async {
    if (authToken == null || authToken.isEmpty) {
      _error = '請先登入';
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/applications/watchlist').replace(
        queryParameters: {'months': months.toString()},
      );
      DebugHelper.logApiRequest('GET', uri.toString());

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      ).timeout(_timeout);

      DebugHelper.logApiResponse(response.statusCode, response.body);

      if (response.statusCode == 200) {
        final List<dynamic> decoded = json.decode(response.body);
        _watchlistItems = decoded.map((item) => item as Map<String, dynamic>).toList();
        _error = null;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _error = '載入暫存失敗：${e.toString()}';
      DebugHelper.log('載入暫存失敗: ${e.toString()}', tag: 'SecondHandApplicationProvider');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 根據ID獲取申請單
  Future<SecondHandBookApplication?> getApplicationById({
    required String? authToken,
    required String id,
  }) async {
    if (authToken == null || authToken.isEmpty) {
      _error = '請先登入';
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/applications/second-hand-book/$id');
      DebugHelper.logApiRequest('GET', uri.toString());

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      ).timeout(_timeout);

      DebugHelper.logApiResponse(response.statusCode, response.body);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final application = SecondHandBookApplication.fromJson(decoded as Map<String, dynamic>);
        _currentApplication = application;
        _error = null;
        return application;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _error = '載入申請單失敗：${e.toString()}';
      DebugHelper.log('載入申請單失敗: ${e.toString()}', tag: 'SecondHandApplicationProvider');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 獲取客戶的申請單列表（分頁）
  Future<PaginatedResponse<SecondHandBookApplication>?> getApplicationsByCustomer({
    required String? authToken,
    int page = 1,
    int pageSize = 10,
    bool append = false,
  }) async {
    if (authToken == null || authToken.isEmpty) {
      _error = '請先登入';
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/applications/second-hand-book/customer').replace(
        queryParameters: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );
      DebugHelper.logApiRequest('GET', uri.toString());

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      ).timeout(_timeout);

      DebugHelper.logApiResponse(response.statusCode, response.body);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final paginated = PaginatedResponse<SecondHandBookApplication>.fromJson(
          decoded as Map<String, dynamic>,
          (json) => SecondHandBookApplication.fromJson(json),
        );
        
        // If append is true, add to existing list; otherwise replace
        if (append && page > 1) {
          _applications.addAll(paginated.items);
        } else {
          _applications = paginated.items;
        }
        
        _error = null;
        return paginated;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _error = '載入申請單列表失敗：${e.toString()}';
      DebugHelper.log('載入申請單列表失敗: ${e.toString()}', tag: 'SecondHandApplicationProvider');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 獲取申請單的項目列表
  Future<List<SecondHandBookApplicationItem>> getApplicationItems({
    required String? authToken,
    required String applicationId,
  }) async {
    if (authToken == null || authToken.isEmpty) {
      _error = '請先登入';
      return [];
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/applications/second-hand-book/item/$applicationId');
      DebugHelper.logApiRequest('GET', uri.toString());

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      ).timeout(_timeout);

      DebugHelper.logApiResponse(response.statusCode, response.body);

      if (response.statusCode == 200) {
        final List<dynamic> decoded = json.decode(response.body);
        final items = decoded
            .map((item) => SecondHandBookApplicationItem.fromJson(item as Map<String, dynamic>))
            .toList();
        _currentApplicationItems = items;
        _error = null;
        return items;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _error = '載入申請單項目失敗：${e.toString()}';
      DebugHelper.log('載入申請單項目失敗: ${e.toString()}', tag: 'SecondHandApplicationProvider');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 清除錯誤
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 清除當前申請單
  void clearCurrentApplication() {
    _currentApplication = null;
    _currentApplicationItems = [];
    notifyListeners();
  }
}
