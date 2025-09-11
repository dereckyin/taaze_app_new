import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/captcha_response.dart';
import '../config/api_config.dart';

/// 認證API服務
class AuthApiService {
  // 使用 ApiConfig 管理 API 端點
  static String get baseUrl => ApiConfig.baseUrl;

  static const Duration timeout = Duration(seconds: 30);

  /// 獲取當前 API 端點信息（用於調試）
  static String get currentApiInfo => ApiConfig.currentApiInfo;

  /// 登入API
  static Future<LoginResponse> login(LoginRequest request) async {
    try {
      final requestData = request.toJson();
      print('🔧 [AuthApiService] 登入請求數據: $requestData');
      print('🔧 [AuthApiService] 登入請求 URL: $baseUrl/auth/login');

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestData),
          )
          .timeout(timeout);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      print('🔧 [AuthApiService] 登入響應狀態: ${response.statusCode}');
      print('🔧 [AuthApiService] 登入響應內容: ${response.body}');
      print('🔧 [AuthApiService] 解析後的響應數據: $responseData');

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(responseData);
        print(
          '🔧 [AuthApiService] 解析後的登入響應: success=${loginResponse.success}, token=${loginResponse.token}, error=${loginResponse.error}',
        );
        return loginResponse;
      } else {
        return LoginResponse(
          success: false,
          error: responseData['message'] ?? '登入失敗',
          captchaRequired: responseData['captchaRequired'] ?? false,
          captcha: responseData['captcha'] != null
              ? CaptchaResponse.fromJson(responseData['captcha'])
              : null,
        );
      }
    } on SocketException {
      return LoginResponse(success: false, error: '網路連接失敗，請檢查網路設置');
    } on HttpException {
      return LoginResponse(success: false, error: 'HTTP請求失敗');
    } on FormatException {
      return LoginResponse(success: false, error: '響應格式錯誤');
    } catch (e) {
      return LoginResponse(success: false, error: '登入失敗：${e.toString()}');
    }
  }

  /// 獲取驗證碼
  static Future<CaptchaResponse> getCaptcha() async {
    try {
      print('🔧 [AuthApiService] 請求驗證碼: $baseUrl/auth/captcha');
      final response = await http
          .get(
            Uri.parse('$baseUrl/auth/captcha'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(timeout);

      print('🔧 [AuthApiService] 驗證碼響應狀態: ${response.statusCode}');
      print('🔧 [AuthApiService] 驗證碼響應內容: ${response.body}');

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final captcha = CaptchaResponse.fromJson(responseData);
        print('🔧 [AuthApiService] 驗證碼解析成功: ${captcha.captchaId}');
        return captcha;
      } else {
        throw Exception(responseData['message'] ?? '獲取驗證碼失敗');
      }
    } catch (e) {
      print('🔧 [AuthApiService] 驗證碼請求失敗: ${e.toString()}');
      throw Exception('獲取驗證碼失敗：${e.toString()}');
    }
  }

  /// 刷新驗證碼
  static Future<CaptchaResponse> refreshCaptcha(String captchaId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/captcha/refresh'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'captcha_id': captchaId}),
          )
          .timeout(timeout);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return CaptchaResponse.fromJson(responseData);
      } else {
        throw Exception(responseData['message'] ?? '刷新驗證碼失敗');
      }
    } catch (e) {
      throw Exception('刷新驗證碼失敗：${e.toString()}');
    }
  }

  /// 註冊API
  static Future<LoginResponse> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email,
              'password': password,
              'name': name,
            }),
          )
          .timeout(timeout);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201) {
        return LoginResponse.fromJson(responseData);
      } else {
        return LoginResponse(
          success: false,
          error: responseData['message'] ?? '註冊失敗',
        );
      }
    } catch (e) {
      return LoginResponse(success: false, error: '註冊失敗：${e.toString()}');
    }
  }

  /// 登出API
  static Future<bool> logout(String token) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/logout'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// 刷新令牌
  static Future<LoginResponse> refreshToken(String refreshToken) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/refresh'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(timeout);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(responseData);
      } else {
        return LoginResponse(
          success: false,
          error: responseData['message'] ?? '刷新令牌失敗',
        );
      }
    } catch (e) {
      return LoginResponse(success: false, error: '刷新令牌失敗：${e.toString()}');
    }
  }
}
