/// API 配置管理
class ApiConfig {
  // API 端點配置
  static const String productionUrl = 'https://api.taaze.tw/api/v1';
  static const String testUrl = 'http://192.168.0.229:8000/api/v1';
  //static const String testUrl = 'https://api.taaze.tw/api/v1';

  // 當前使用的 API 端點
  static String _currentBaseUrl = productionUrl; // 預設使用測試環境

  /// 獲取當前 API 端點
  static String get baseUrl => _currentBaseUrl;

  /// 設置 API 端點
  static void setBaseUrl(String url) {
    _currentBaseUrl = url;
  }

  /// 切換到生產環境
  static void useProduction() {
    _currentBaseUrl = productionUrl;
  }

  /// 切換到測試環境
  static void useTest() {
    _currentBaseUrl = testUrl;
  }

  /// 獲取當前環境名稱
  static String get environmentName {
    if (_currentBaseUrl == productionUrl) {
      return '生產環境';
    } else if (_currentBaseUrl == testUrl) {
      return '測試環境';
    } else {
      return '自定義環境';
    }
  }

  /// 獲取當前 API 信息
  static String get currentApiInfo =>
      '當前 API: $environmentName ($_currentBaseUrl)';

  /// 檢查是否為測試環境
  static bool get isTestEnvironment => _currentBaseUrl == testUrl;

  /// 檢查是否為生產環境
  static bool get isProductionEnvironment => _currentBaseUrl == productionUrl;

  /// API 端點路徑
  static const String bannersEndpoint = '/content/banner';
  static const String bestsellersEndpoint = '/content/bestsellers';
  static const String newArrivalsEndpoint = '/book/latest';
  static const String ebookNewArrivalsEndpoint = '/book/e-book/latest';
  static const String usedBooksLatestEndpoint = '/book/second-hand/latest';
  static const String aiTalkToBooksEndpoint = '/ai/talk-to-the-books/chat';
  static const String ordersEndpoint = '/orders';
  static const String orderItemsEndpoint = '/orders/items';

  /// 獲取所有可用的 API 端點
  static List<ApiEndpoint> get availableEndpoints => [
    ApiEndpoint(name: '生產環境', url: productionUrl, description: '正式環境 API'),
    ApiEndpoint(name: '測試環境', url: testUrl, description: '本地測試 API'),
  ];
}

/// API 端點信息
class ApiEndpoint {
  final String name;
  final String url;
  final String description;

  const ApiEndpoint({
    required this.name,
    required this.url,
    required this.description,
  });

  @override
  String toString() => '$name: $url';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiEndpoint &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          url == other.url &&
          description == other.description;

  @override
  int get hashCode => name.hashCode ^ url.hashCode ^ description.hashCode;
}
