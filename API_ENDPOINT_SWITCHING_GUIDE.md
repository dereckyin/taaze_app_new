# API 端點切換指南

## 概述

現在你可以輕鬆地在兩個 API 端點之間切換：
- **生產環境**: `https://api.taaze.tw/api/v1`
- **測試環境**: `http://192.168.0.229/api/v1`

## 配置方式

### 1. 程式碼切換

```dart
import 'package:my_app/config/api_config.dart';

// 切換到測試環境
ApiConfig.useTest();

// 切換到生產環境
ApiConfig.useProduction();

// 自定義 API 端點
ApiConfig.setBaseUrl('http://your-custom-api.com/api/v1');

// 獲取當前 API 信息
print(ApiConfig.currentApiInfo);
```

### 2. 使用調試助手

```dart
import 'package:my_app/utils/api_debug_helper.dart';

// 快速切換到測試環境
ApiDebugHelper.switchToTest();

// 快速切換到生產環境
ApiDebugHelper.switchToProduction();

// 顯示切換對話框
ApiDebugHelper.showApiSwitchDialog(context);

// 輸出當前 API 信息到控制台
ApiDebugHelper.logCurrentApiInfo();
```

### 3. 編譯時切換

在運行 Flutter 應用時使用環境變量：

```bash
# 使用測試環境
flutter run --dart-define=USE_TEST_API=true

# 使用生產環境
flutter run --dart-define=USE_TEST_API=false
```

## 檔案結構

```
lib/
├── config/
│   ├── api_config.dart          # API 端點配置管理
│   └── oauth_config.dart        # OAuth 配置（已更新）
├── services/
│   ├── auth_api_service.dart    # 認證 API 服務（已更新）
│   └── oauth_service.dart       # OAuth 服務（已更新）
├── utils/
│   └── api_debug_helper.dart    # API 調試助手
└── screens/
    └── api_debug_screen.dart    # API 調試頁面
```

## 使用範例

### 在登入頁面顯示當前 API 信息

```dart
import 'package:my_app/config/api_config.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('登入 - ${ApiConfig.environmentName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              ApiDebugHelper.showApiSwitchDialog(context);
            },
          ),
        ],
      ),
      // ... 其他內容
    );
  }
}
```

### 在開發模式下自動切換

```dart
import 'package:flutter/foundation.dart';
import 'package:my_app/config/api_config.dart';

void main() {
  // 在調試模式下自動使用測試環境
  if (kDebugMode) {
    ApiConfig.useTest();
  } else {
    ApiConfig.useProduction();
  }
  
  runApp(MyApp());
}
```

## 當前設定

### 預設配置
- **預設環境**: 測試環境 (`http://192.168.0.229/api/v1`)
- **切換方式**: 程式碼切換或調試助手
- **持久化**: 當前會話期間有效

### 可用的 API 端點

| 環境 | URL | 描述 |
|------|-----|------|
| 生產環境 | `https://api.taaze.tw/api/v1` | 正式環境 API |
| 測試環境 | `http://192.168.0.229/api/v1` | 本地測試 API |

## 調試功能

### 1. API 調試頁面
- 路徑: `lib/screens/api_debug_screen.dart`
- 功能: 顯示當前 API 狀態、快速切換、測試連接

### 2. 控制台輸出
```dart
// 輸出當前 API 信息
ApiDebugHelper.logCurrentApiInfo();

// 輸出範例:
// 🔧 當前 API: 測試環境 (http://192.168.0.229/api/v1)
// 🔧 AuthApiService: 當前 API: 測試環境 (http://192.168.0.229/api/v1)
```

### 3. API 狀態檢查
```dart
// 獲取詳細的 API 狀態
Map<String, dynamic> status = ApiDebugHelper.getApiStatus();
print(status);

// 輸出範例:
// {
//   currentUrl: http://192.168.0.229/api/v1,
//   environment: 測試環境,
//   isTest: true,
//   isProduction: false,
//   availableEndpoints: [生產環境: https://api.taaze.tw/api/v1, 測試環境: http://192.168.0.229/api/v1]
// }
```

## 注意事項

### 1. 安全性
- 測試環境的 API 端點包含在程式碼中，請確保不會洩露敏感信息
- 在生產環境中，建議使用環境變量或配置文件

### 2. 網路連接
- 測試環境 (`192.168.0.229`) 需要確保設備與該 IP 在同一網路中
- 生產環境需要網路連接

### 3. API 兼容性
- 確保兩個 API 端點具有相同的接口結構
- 測試時注意 API 版本差異

## 故障排除

### 1. 無法連接到測試 API
- 檢查設備是否與 `192.168.0.229` 在同一網路
- 確認測試 API 服務正在運行
- 檢查防火牆設定

### 2. API 切換不生效
- 確認已正確導入 `ApiConfig`
- 檢查是否有其他地方硬編碼了 API 端點
- 重新啟動應用

### 3. OAuth 功能異常
- 確認 OAuth 配置適用於當前 API 環境
- 檢查 OAuth 重定向 URI 設定

## 進階配置

### 1. 添加新的 API 端點
```dart
// 在 ApiConfig 中添加
static const String stagingUrl = 'https://staging-api.taaze.tw/api/v1';

// 在 availableEndpoints 中添加
static List<ApiEndpoint> get availableEndpoints => [
  // ... 現有端點
  ApiEndpoint(
    name: '預發布環境',
    url: stagingUrl,
    description: '預發布環境 API',
  ),
];
```

### 2. 環境變量配置
```dart
// 從環境變量讀取 API 端點
static String get baseUrl {
  const String? envUrl = String.fromEnvironment('API_BASE_URL');
  if (envUrl != null && envUrl.isNotEmpty) {
    return envUrl;
  }
  return _currentBaseUrl;
}
```

### 3. 配置文件支持
```dart
// 從配置文件讀取 API 端點
static Future<void> loadFromConfig() async {
  final prefs = await SharedPreferences.getInstance();
  final String? savedUrl = prefs.getString('api_base_url');
  if (savedUrl != null && savedUrl.isNotEmpty) {
    _currentBaseUrl = savedUrl;
  }
}
```

## 總結

現在你可以：
1. ✅ 輕鬆在兩個 API 端點之間切換
2. ✅ 使用調試助手快速切換環境
3. ✅ 在開發和生產環境之間無縫切換
4. ✅ 監控當前 API 狀態
5. ✅ 測試 API 連接

預設情況下，應用會使用測試環境 (`http://192.168.0.229/api/v1`)，你可以隨時切換到生產環境或使用調試工具進行管理。
