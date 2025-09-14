import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/banner.dart';
import '../utils/debug_helper.dart';
import '../config/api_config.dart';

class BannerProvider with ChangeNotifier {
  List<Banner> _banners = [];
  bool _isLoading = false;
  String? _error;

  List<Banner> get banners => _banners;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // API 配置
  static const Duration _timeout = Duration(seconds: 10);

  // 模擬橫幅資料
  final List<Banner> _mockBanners = [
    Banner(
      id: '1',
      title: '讀冊生活網路書店',
      subtitle: '探索數千本精彩書籍',
      description: '享受閱讀的美好時光，發現更多精彩內容',
      imageUrl: 'https://picsum.photos/800/400?random=1',
      actionUrl: '/search',
      actionText: '開始探索',
      type: BannerType.featured,
      displayOrder: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Banner(
      id: '2',
      title: '新會員優惠',
      subtitle: '首次購書享8折優惠',
      description: '立即註冊成為會員，享受專屬優惠價格',
      imageUrl: 'https://picsum.photos/800/400?random=2',
      actionUrl: '/register',
      actionText: '立即註冊',
      type: BannerType.promotion,
      displayOrder: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    ),
    Banner(
      id: '3',
      title: '滿額免運',
      subtitle: '滿\$500免運費',
      description: '購物滿額即可享受免費配送服務',
      imageUrl: 'https://picsum.photos/800/400?random=3',
      actionUrl: '/cart',
      actionText: '查看購物車',
      type: BannerType.promotion,
      displayOrder: 3,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      expiresAt: DateTime.now().add(const Duration(days: 15)),
    ),
    Banner(
      id: '4',
      title: '春季書展',
      subtitle: '精選好書特價中',
      description: '春季書展期間，精選書籍全面特價，錯過再等一年',
      imageUrl: 'https://picsum.photos/800/400?random=4',
      actionUrl: '/books/sale',
      actionText: '立即搶購',
      type: BannerType.event,
      displayOrder: 4,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      expiresAt: DateTime.now().add(const Duration(days: 20)),
    ),
    Banner(
      id: '5',
      title: '新書上架',
      subtitle: '最新出版書籍',
      description: '最新出版的熱門書籍，搶先閱讀最新內容',
      imageUrl: 'https://picsum.photos/800/400?random=5',
      actionUrl: '/books/new',
      actionText: '查看新書',
      type: BannerType.newRelease,
      displayOrder: 5,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Banner(
      id: '6',
      title: '系統維護通知',
      subtitle: '服務時間調整',
      description: '為了提供更好的服務，系統將於本週末進行維護',
      imageUrl: 'https://picsum.photos/800/400?random=6',
      actionUrl: null,
      actionText: null,
      type: BannerType.announcement,
      displayOrder: 6,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    ),
  ];

  BannerProvider() {
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    DebugHelper.log('開始載入橫幅資料', tag: 'BannerProvider');
    _isLoading = true;
    notifyListeners();

    try {
      // 首先嘗試從 API 獲取資料
      DebugHelper.log('嘗試從 API 獲取橫幅資料', tag: 'BannerProvider');
      final apiBanners = await _fetchBannersFromAPI();

      if (apiBanners.isNotEmpty) {
        _banners = apiBanners;
        _error = null; // 清除錯誤狀態
        DebugHelper.log(
          '成功從 API 載入 ${_banners.length} 個橫幅',
          tag: 'BannerProvider',
        );
      } else {
        // API 返回空資料，使用 mock data
        DebugHelper.log('API 返回空資料，使用 mock data', tag: 'BannerProvider');
        _loadMockData();
        _error = 'API 返回空資料，已載入模擬資料';
      }
    } catch (e) {
      // API 調用失敗，使用 mock data 作為 fallback
      DebugHelper.log(
        'API 調用失敗: ${e.toString()}，使用 mock data',
        tag: 'BannerProvider',
      );
      _loadMockData();
      _error = 'API 連接失敗，已載入模擬資料：${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  // 載入模擬資料
  void _loadMockData() {
    _banners = _mockBanners.where((banner) => banner.isValid).toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    DebugHelper.log('載入橫幅假資料: ${_banners.length} 個橫幅', tag: 'BannerProvider');
  }

  // 根據類型獲取橫幅
  List<Banner> getBannersByType(BannerType type) {
    return _banners.where((banner) => banner.type == type).toList();
  }

  // 獲取有效橫幅
  List<Banner> get activeBanners {
    return _banners.where((banner) => banner.isValid).toList();
  }

  // 獲取促銷橫幅
  List<Banner> get promotionBanners {
    return getBannersByType(BannerType.promotion);
  }

  // 獲取公告橫幅
  List<Banner> get announcementBanners {
    return getBannersByType(BannerType.announcement);
  }

  // 獲取精選橫幅
  List<Banner> get featuredBanners {
    return getBannersByType(BannerType.featured);
  }

  // 清除錯誤
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // 手動重新載入資料
  Future<void> refreshBanners() async {
    await _loadBanners();
  }

  // 強制重新載入（優先使用 API）
  Future<void> forceRefreshFromAPI() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 強制從 API 重新載入
      DebugHelper.log('強制從 API 重新載入橫幅資料', tag: 'BannerProvider');
      final apiBanners = await _fetchBannersFromAPI();

      if (apiBanners.isNotEmpty) {
        _banners = apiBanners;
        _error = null;
        DebugHelper.log(
          '強制重新載入成功，載入 ${_banners.length} 個橫幅',
          tag: 'BannerProvider',
        );
      } else {
        _loadMockData();
        _error = 'API 返回空資料，已載入模擬資料';
        DebugHelper.log('API 返回空資料，使用模擬資料', tag: 'BannerProvider');
      }
    } catch (e) {
      _loadMockData();
      _error = 'API 重新載入失敗，已載入模擬資料：${e.toString()}';
      DebugHelper.log('API 重新載入失敗，使用模擬資料', tag: 'BannerProvider');
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

  // 從 API 獲取橫幅資料
  Future<List<Banner>> _fetchBannersFromAPI() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.bannersEndpoint}');
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

        return jsonData.map((json) => Banner.fromJson(json)).toList();
      } else {
        throw Exception('API 返回錯誤狀態碼: ${response.statusCode}');
      }
    } catch (e) {
      DebugHelper.log('API調用異常: ${e.toString()}', tag: 'BannerProvider');
      throw Exception('API 調用失敗: ${e.toString()}');
    }
  }
}
