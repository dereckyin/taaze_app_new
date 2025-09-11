import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/oauth_user.dart';
import '../models/captcha_response.dart';
import '../config/oauth_config.dart';
import '../config/api_config.dart';

/// OAuth 認證服務
class OAuthService {
  // 使用 ApiConfig 管理 API 端點
  static String get baseUrl => ApiConfig.baseUrl;
  static const Duration timeout = OAuthConfig.requestTimeout;

  // Google Sign-In 配置
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: OAuthConfig.googleScopes,
  );

  // Facebook 配置
  static const List<String> _facebookPermissions =
      OAuthConfig.facebookPermissions;

  /// Google 登入
  static Future<OAuthLoginResponse> signInWithGoogle() async {
    try {
      // 檢查 Google 配置
      if (!OAuthConfig.isGoogleConfigured()) {
        return const OAuthLoginResponse(
          success: false,
          error: 'Google 登入未正確配置，請聯繫開發者',
        );
      }

      // 執行 Google 登入
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return const OAuthLoginResponse(success: false, error: 'Google 登入被取消');
      }

      // 獲取認證詳情
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null) {
        return const OAuthLoginResponse(
          success: false,
          error: '無法獲取 Google 存取權杖',
        );
      }

      // 創建 OAuth 用戶資料
      final oauthUser = OAuthUser(
        id: googleUser.id,
        email: googleUser.email,
        name: googleUser.displayName ?? '',
        avatar: googleUser.photoUrl,
        provider: 'google',
        accessToken: googleAuth.accessToken,
        refreshToken: googleAuth.idToken,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      // 發送到後端驗證
      return await _sendOAuthToBackend(oauthUser);
    } catch (e) {
      return OAuthLoginResponse(
        success: false,
        error: 'Google 登入失敗：${e.toString()}',
      );
    }
  }

  /// Facebook 登入
  static Future<OAuthLoginResponse> signInWithFacebook() async {
    try {
      // 檢查 Facebook 配置
      if (!OAuthConfig.isFacebookConfigured()) {
        return const OAuthLoginResponse(
          success: false,
          error: 'Facebook 登入未正確配置，請聯繫開發者',
        );
      }

      // 執行 Facebook 登入
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: _facebookPermissions,
      );

      if (result.status != LoginStatus.success) {
        return OAuthLoginResponse(
          success: false,
          error: 'Facebook 登入失敗：${result.message}',
        );
      }

      // 獲取用戶資料
      final userData = await FacebookAuth.instance.getUserData();

      if (userData['email'] == null) {
        return const OAuthLoginResponse(
          success: false,
          error: '無法獲取 Facebook 用戶電子郵件',
        );
      }

      // 創建 OAuth 用戶資料
      final oauthUser = OAuthUser(
        id: userData['id'] as String,
        email: userData['email'] as String,
        name: userData['name'] as String? ?? '',
        avatar: userData['picture']?['data']?['url'] as String?,
        provider: 'facebook',
        accessToken: result.accessToken?.token,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      // 發送到後端驗證
      return await _sendOAuthToBackend(oauthUser);
    } catch (e) {
      return OAuthLoginResponse(
        success: false,
        error: 'Facebook 登入失敗：${e.toString()}',
      );
    }
  }

  /// LINE 登入
  static Future<OAuthLoginResponse> signInWithLine() async {
    try {
      // 檢查 LINE 配置
      if (!OAuthConfig.isLineConfigured()) {
        return const OAuthLoginResponse(
          success: false,
          error: 'LINE 登入未正確配置，請聯繫開發者',
        );
      }

      // LINE 登入需要通過 WebView 或外部瀏覽器
      // 這裡使用 URL Launcher 打開 LINE 登入頁面
      final String lineLoginUrl =
          'https://access.line.me/oauth2/v2.1/authorize?'
          'response_type=code&'
          'client_id=${OAuthConfig.lineChannelId}&'
          'redirect_uri=${Uri.encodeComponent(OAuthConfig.lineRedirectUri)}&'
          'state=random_state&'
          'scope=${OAuthConfig.lineScopes.join('%20')}';

      final Uri uri = Uri.parse(lineLoginUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        // 注意：實際實現中需要處理回調 URL 來獲取授權碼
        // 這裡返回一個提示訊息
        return const OAuthLoginResponse(
          success: false,
          error: 'LINE 登入功能需要完整的回調處理，請聯繫開發者',
        );
      } else {
        return const OAuthLoginResponse(
          success: false,
          error: '無法打開 LINE 登入頁面',
        );
      }
    } catch (e) {
      return OAuthLoginResponse(
        success: false,
        error: 'LINE 登入失敗：${e.toString()}',
      );
    }
  }

  /// 發送 OAuth 資料到後端驗證
  static Future<OAuthLoginResponse> _sendOAuthToBackend(
    OAuthUser oauthUser,
  ) async {
    try {
      final request = OAuthLoginRequest(
        provider: oauthUser.provider,
        accessToken: oauthUser.accessToken!,
        userInfo: oauthUser.toJson(),
      );

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/oauth'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(timeout);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return OAuthLoginResponse.fromJson(responseData);
      } else {
        return OAuthLoginResponse(
          success: false,
          error: responseData['message'] ?? 'OAuth 登入失敗',
          captchaRequired: responseData['captcha_required'] ?? false,
          captcha: responseData['captcha'] != null
              ? CaptchaResponse.fromJson(
                  responseData['captcha'] as Map<String, dynamic>,
                )
              : null,
        );
      }
    } on SocketException {
      return const OAuthLoginResponse(success: false, error: '網路連接失敗，請檢查網路設置');
    } on HttpException {
      return const OAuthLoginResponse(success: false, error: 'HTTP請求失敗');
    } on FormatException {
      return const OAuthLoginResponse(success: false, error: '響應格式錯誤');
    } catch (e) {
      return OAuthLoginResponse(
        success: false,
        error: 'OAuth 登入失敗：${e.toString()}',
      );
    }
  }

  /// 登出所有 OAuth 提供商
  static Future<void> signOutAll() async {
    try {
      // Google 登出
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Facebook 登出
      await FacebookAuth.instance.logOut();

      // LINE 登出（如果需要）
      // 注意：LINE 登出通常由後端處理
    } catch (e) {
      // 登出失敗不應該阻止應用繼續運行
      print('OAuth 登出時發生錯誤：$e');
    }
  }

  /// 檢查是否已登入
  static Future<bool> isSignedIn() async {
    try {
      final googleSignedIn = await _googleSignIn.isSignedIn();
      final facebookAccessToken = await FacebookAuth.instance.accessToken;

      return googleSignedIn || facebookAccessToken != null;
    } catch (e) {
      return false;
    }
  }

  /// 獲取當前登入的用戶資料
  static Future<OAuthUser?> getCurrentUser() async {
    try {
      // 檢查 Google
      if (await _googleSignIn.isSignedIn()) {
        final googleUser = _googleSignIn.currentUser;
        if (googleUser != null) {
          final googleAuth = await googleUser.authentication;
          return OAuthUser(
            id: googleUser.id,
            email: googleUser.email,
            name: googleUser.displayName ?? '',
            avatar: googleUser.photoUrl,
            provider: 'google',
            accessToken: googleAuth.accessToken,
            refreshToken: googleAuth.idToken,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          );
        }
      }

      // 檢查 Facebook
      final facebookAccessToken = await FacebookAuth.instance.accessToken;
      if (facebookAccessToken != null) {
        final userData = await FacebookAuth.instance.getUserData();
        return OAuthUser(
          id: userData['id'] as String,
          email: userData['email'] as String,
          name: userData['name'] as String? ?? '',
          avatar: userData['picture']?['data']?['url'] as String?,
          provider: 'facebook',
          accessToken: facebookAccessToken.token,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
