# API整合指南

## 概述
本指南說明如何將應用從模擬模式切換到真實的API模式，實現完整的後端驗證碼驗證。

## 架構對比

### 模擬模式（當前）
```
App端 → 本地驗證 → 模擬結果
```

### API模式（推薦）
```
App端 → API端 → 數據庫驗證 → 返回結果
```

## 切換步驟

### 1. 更新API配置

#### 1.1 修改API服務配置
```dart
// lib/services/auth_api_service.dart
class AuthApiService {
  // 更新為您的實際API地址
  static const String baseUrl = 'https://api.taaze.tw/api/v1';
  // 或者使用環境變量
  // static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000/api');
}
```

#### 1.2 添加環境配置
```dart
// lib/config/api_config.dart
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.taaze.tw/api/v1',
  );
  
  static const Duration timeout = Duration(seconds: 30);
  
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
```

### 2. 更新AuthProvider

#### 2.1 切換到API模式
```dart
// lib/providers/auth_provider.dart
class AuthProvider with ChangeNotifier {
  // 添加API模式開關
  static const bool useApiMode = true; // 設為true啟用API模式
  
  Future<bool> login(String email, String password, {String? captchaCode}) async {
    if (useApiMode) {
      return await _loginWithApi(email, password, captchaCode);
    } else {
      return await _loginWithMock(email, password, captchaCode);
    }
  }
  
  Future<bool> _loginWithApi(String email, String password, String? captchaCode) async {
    // 使用真實API的登入邏輯
    final loginRequest = LoginRequest(
      email: email,
      password: password,
      captchaId: _currentCaptcha?.captchaId,
      captchaCode: captchaCode,
    );

    final loginResponse = await AuthApiService.login(loginRequest);
    // ... 處理響應
  }
  
  Future<bool> _loginWithMock(String email, String password, String? captchaCode) async {
    // 原有的模擬登入邏輯
    // ... 模擬邏輯
  }
}
```

### 3. 添加HTTP依賴

#### 3.1 更新pubspec.yaml
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0  # 添加HTTP客戶端
  # 其他依賴...
```

#### 3.2 安裝依賴
```bash
flutter pub get
```

### 4. 實現錯誤處理

#### 4.1 網路錯誤處理
```dart
// lib/services/auth_api_service.dart
static Future<LoginResponse> login(LoginRequest request) async {
  try {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/login'),
          headers: defaultHeaders,
          body: jsonEncode(request.toJson()),
        )
        .timeout(timeout);

    // 處理不同狀態碼
    switch (response.statusCode) {
      case 200:
        return LoginResponse.fromJson(jsonDecode(response.body));
      case 400:
        return LoginResponse(
          success: false,
          error: '請求參數錯誤',
          captchaRequired: true,
        );
      case 401:
        return LoginResponse(
          success: false,
          error: '認證失敗',
        );
      case 429:
        return LoginResponse(
          success: false,
          error: '請求過於頻繁',
        );
      default:
        return LoginResponse(
          success: false,
          error: '服務器錯誤',
        );
    }
  } on SocketException {
    return const LoginResponse(
      success: false,
      error: '網路連接失敗',
    );
  } on TimeoutException {
    return const LoginResponse(
      success: false,
      error: '請求超時',
    );
  } catch (e) {
    return LoginResponse(
      success: false,
      error: '未知錯誤：${e.toString()}',
    );
  }
}
```

### 5. 添加令牌管理

#### 5.1 令牌存儲
```dart
// lib/services/token_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  
  static Future<void> saveTokens(String token, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }
  
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }
  
  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
  }
}
```

#### 5.2 自動令牌刷新
```dart
// lib/services/http_interceptor.dart
import 'package:http/http.dart' as http;

class HttpInterceptor {
  static Future<http.Response> authenticatedRequest(
    String method,
    String url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final token = await TokenService.getToken();
    
    final requestHeaders = {
      ...?headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
    
    http.Response response;
    
    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(Uri.parse(url), headers: requestHeaders);
        break;
      case 'POST':
        response = await http.post(
          Uri.parse(url),
          headers: requestHeaders,
          body: body,
        );
        break;
      // 其他HTTP方法...
      default:
        throw UnsupportedError('不支持的HTTP方法：$method');
    }
    
    // 檢查是否需要刷新令牌
    if (response.statusCode == 401) {
      final refreshed = await _refreshTokenIfNeeded();
      if (refreshed) {
        // 重試請求
        return await authenticatedRequest(method, url, headers: headers, body: body);
      }
    }
    
    return response;
  }
  
  static Future<bool> _refreshTokenIfNeeded() async {
    final refreshToken = await TokenService.getRefreshToken();
    if (refreshToken == null) return false;
    
    try {
      final response = await AuthApiService.refreshToken(refreshToken);
      if (response.success) {
        await TokenService.saveTokens(response.token!, response.refreshToken!);
        return true;
      }
    } catch (e) {
      // 刷新失敗，清除令牌
      await TokenService.clearTokens();
    }
    
    return false;
  }
}
```

### 6. 環境配置

#### 6.1 開發環境配置
```dart
// lib/config/environment.dart
class Environment {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );
  
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
  static const bool enableLogging = !isProduction;
}
```

#### 6.2 運行配置
```bash
# 開發環境
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api

# 生產環境
flutter run --dart-define=API_BASE_URL=https://api.taaze.tw/api/v1 --dart-define=dart.vm.product=true
```

### 7. 測試配置

#### 7.1 單元測試
```dart
// test/services/auth_api_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;

void main() {
  group('AuthApiService', () {
    test('should return success response for valid login', () async {
      // 模擬HTTP響應
      final mockResponse = http.Response(
        jsonEncode({
          'success': true,
          'token': 'mock-token',
          'user': {
            'id': '1',
            'email': 'test@example.com',
            'name': 'Test User',
          }
        }),
        200,
      );
      
      // 測試邏輯...
    });
  });
}
```

#### 7.2 集成測試
```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Login Flow', () {
    testWidgets('should login successfully with valid credentials', (tester) async {
      // 測試登入流程
    });
    
    testWidgets('should show captcha after failed attempts', (tester) async {
      // 測試驗證碼顯示
    });
  });
}
```

### 8. 部署配置

#### 8.1 構建配置
```bash
# 開發版本
flutter build apk --dart-define=API_BASE_URL=http://localhost:3000/api

# 生產版本
flutter build apk --release --dart-define=API_BASE_URL=https://api.taaze.tw/api/v1
```

#### 8.2 CI/CD配置
```yaml
# .github/workflows/build.yml
name: Build and Deploy
on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      
      - name: Build APK
        run: flutter build apk --release --dart-define=API_BASE_URL=${{ secrets.API_BASE_URL }}
```

## 安全考慮

### 1. HTTPS使用
- 生產環境必須使用HTTPS
- 配置SSL證書
- 實現證書固定

### 2. 令牌安全
- 使用JWT令牌
- 設置適當的過期時間
- 實現令牌刷新機制

### 3. 數據加密
- 敏感數據加密傳輸
- 本地存儲加密
- API響應加密

### 4. 錯誤處理
- 不暴露敏感信息
- 統一的錯誤格式
- 適當的日誌記錄

## 監控和維護

### 1. 性能監控
- API響應時間監控
- 錯誤率監控
- 用戶體驗指標

### 2. 安全監控
- 異常登入檢測
- 暴力破解監控
- 安全事件警報

### 3. 日誌管理
- 結構化日誌
- 日誌聚合
- 日誌分析

這個指南提供了完整的API整合方案，確保了安全性和可維護性。
