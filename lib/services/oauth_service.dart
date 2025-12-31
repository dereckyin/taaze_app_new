import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;
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

  // Google Sign-In 配置（根據平台使用不同的 Client ID）
  static GoogleSignIn get _googleSignIn {
    if (Platform.isIOS) {
      // iOS 使用 iOS 專用的 Client ID
      return GoogleSignIn(
        clientId: OAuthConfig.googleClientIdIOS,
        scopes: OAuthConfig.googleScopes,
      );
    } else {
      // Android 使用 Android 專用的 Client ID
      return GoogleSignIn(
        serverClientId: OAuthConfig.googleClientIdAndroid,
        scopes: OAuthConfig.googleScopes,
      );
    }
  }

  // Facebook 配置
  static const List<String> _facebookPermissions =
      OAuthConfig.facebookPermissions;

  static void _log(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('[OAuthService] $message');
      if (error != null) {
        debugPrint('  error: $error');
      }
      if (stackTrace != null) {
        debugPrint('  stackTrace: $stackTrace');
      }
      developer.log(
        message,
        name: 'OAuthService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  // #region agent log helper (sync; NDJSON)
  static void _agentDebugLogSync({
    required String hypothesisId,
    required String location,
    required String message,
    Map<String, Object?> data = const {},
    required String runId,
  }) {
    const String logPath = '/Users/yinteming/my_app/.cursor/debug.log';
    try {
      final logEntry = {
        'sessionId': 'debug-session',
        'runId': runId,
        'hypothesisId': hypothesisId,
        'location': location,
        'message': message,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      File(logPath).writeAsStringSync('${jsonEncode(logEntry)}\n',
          mode: FileMode.append, flush: true);
    } catch (_) {
      // ignore
    }
  }
  // #endregion

  /// Google 登入
  static Future<OAuthLoginResponse> signInWithGoogle() async {
    try {
      _log('Start Google sign-in');
      // #region agent log
      _agentDebugLogSync(
        hypothesisId: 'G1',
        location: 'OAuthService.signInWithGoogle:START',
        message: 'Enter signInWithGoogle',
        data: {
          'platform': Platform.operatingSystem,
          'iosClientId': OAuthConfig.googleClientIdIOS,
          'derivedUrlScheme': 'com.googleusercontent.apps.${OAuthConfig.googleClientIdIOS.split('.apps.googleusercontent.com').first}',
        },
        runId: 'g-pre-1',
      );
      // #endregion
      // 檢查 Google 配置
      if (!OAuthConfig.isGoogleConfigured()) {
        _log('Google sign-in blocked: config disabled');
        return const OAuthLoginResponse(
          success: false,
          error: 'Google 登入未正確配置，請聯繫開發者',
        );
      }

      // 執行 Google 登入
      // #region agent log
      _agentDebugLogSync(
        hypothesisId: 'G2',
        location: 'OAuthService.signInWithGoogle:BEFORE_SIGNIN',
        message: 'Before GoogleSignIn.signIn',
        data: {},
        runId: 'g-pre-1',
      );
      // #endregion
      bool timedOut = false;
      final GoogleSignInAccount? googleUser = await _googleSignIn
          .signIn()
          .timeout(const Duration(seconds: 20), onTimeout: () async {
        timedOut = true;
        // #region agent log
        _agentDebugLogSync(
          hypothesisId: 'G2',
          location: 'OAuthService.signInWithGoogle:SIGNIN_TIMEOUT',
          message: 'GoogleSignIn.signIn timed out',
          data: {'timeoutSeconds': 20},
          runId: 'g-pre-1',
        );
        // #endregion
        return null;
      });
      _log('Google sign-in result: user=${googleUser?.email ?? 'null'}');
      // #region agent log
      _agentDebugLogSync(
        hypothesisId: 'G2',
        location: 'OAuthService.signInWithGoogle:AFTER_SIGNIN',
        message: 'After GoogleSignIn.signIn',
        data: {'hasUser': googleUser != null, 'timedOut': timedOut},
        runId: 'g-pre-1',
      );
      // #endregion

      if (googleUser == null) {
        _log('Google sign-in cancelled by user');
        return OAuthLoginResponse(
          success: false,
          error: timedOut ? 'Google 登入逾時（可能卡在授權頁/回呼）' : 'Google 登入被取消',
        );
      }

      // 獲取認證詳情
      // #region agent log
      _agentDebugLogSync(
        hypothesisId: 'G3',
        location: 'OAuthService.signInWithGoogle:BEFORE_AUTH',
        message: 'Before googleUser.authentication',
        data: {},
        runId: 'g-pre-1',
      );
      // #endregion
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      _log(
        'Google authentication fetched '
        '(accessToken? ${googleAuth.accessToken != null}, idToken? ${googleAuth.idToken != null})',
      );
      // #region agent log
      _agentDebugLogSync(
        hypothesisId: 'G3',
        location: 'OAuthService.signInWithGoogle:AFTER_AUTH',
        message: 'After googleUser.authentication (presence only)',
        data: {
          'hasAccessToken': googleAuth.accessToken != null,
          'hasIdToken': googleAuth.idToken != null,
        },
        runId: 'g-pre-1',
      );
      // #endregion

      // 在部分 Android 環境下可能拿不到 accessToken；改以 idToken 作為後端驗證回退
      final String? accessToken = googleAuth.accessToken ?? googleAuth.idToken;
      final String? idToken = googleAuth.idToken;

      if (accessToken == null) {
        _log('Google tokens missing (both null)');
        return const OAuthLoginResponse(
          success: false,
          error: '無法獲取 Google 憑證（accessToken/idToken 皆為空）',
        );
      }

      // 創建 OAuth 用戶資料
      final oauthUser = OAuthUser(
        id: googleUser.id,
        email: googleUser.email,
        name: googleUser.displayName ?? '',
        avatar: googleUser.photoUrl,
        provider: 'google',
        accessToken: accessToken,
        idToken: idToken,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      // 發送到後端驗證
      final response = await _sendOAuthToBackend(oauthUser);
      _log('Google sign-in backend response success=${response.success}');
      return response;
    } catch (e, stackTrace) {
      _log('Google sign-in exception', error: e, stackTrace: stackTrace);
      return OAuthLoginResponse(
        success: false,
        error: 'Google 登入失敗：${e.toString()}',
      );
    }
  }

  /// Facebook 登入
  static Future<OAuthLoginResponse> signInWithFacebook() async {
    try {
      _log('Start Facebook sign-in');
      // 檢查 Facebook 配置
      if (!OAuthConfig.isFacebookConfigured()) {
        _log('Facebook sign-in blocked: config disabled');
        return const OAuthLoginResponse(
          success: false,
          error: 'Facebook 登入未正確配置，請聯繫開發者',
        );
      }

      // 執行 Facebook 登入
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: _facebookPermissions,
      );
      _log('Facebook login status: ${result.status}');

      if (result.status != LoginStatus.success) {
        return OAuthLoginResponse(
          success: false,
          error: 'Facebook 登入失敗：${result.message}',
        );
      }

      final accessToken = result.accessToken?.token;
      if (accessToken == null || accessToken.isEmpty) {
        _log('Facebook access token missing');
        return const OAuthLoginResponse(
          success: false,
          error: '無法取得 Facebook 憑證，請稍後再試',
        );
      }

      // 獲取用戶資料
      final userData = await FacebookAuth.instance.getUserData(
        fields: 'id,name,email,picture.width(320).height(320)',
      );

      if (userData['email'] == null) {
        return const OAuthLoginResponse(
          success: false,
          error: '無法獲取 Facebook 用戶電子郵件',
        );
      }

      // 創建 OAuth 用戶資料
      final picture = userData['picture'] as Map<String, dynamic>?;
      final pictureData = picture?['data'] as Map<String, dynamic>?;
      final avatarUrl = pictureData?['url'] as String?;

      final oauthUser = OAuthUser(
        id: userData['id'] as String,
        email: userData['email'] as String,
        name: userData['name'] as String? ?? '',
        avatar: avatarUrl,
        provider: 'facebook',
        accessToken: accessToken,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      // 發送到後端驗證
      final response = await _sendOAuthToBackend(oauthUser);
      _log('Facebook sign-in backend response success=${response.success}');
      return response;
    } catch (e, stackTrace) {
      _log('Facebook sign-in exception', error: e, stackTrace: stackTrace);
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
      _log(
        'Send OAuth user to backend: provider=${oauthUser.provider}, email=${oauthUser.email}',
      );
      final request = OAuthLoginRequest(
        provider: oauthUser.provider,
        accessToken: oauthUser.accessToken!,
        idToken: oauthUser.idToken,
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
        _log('OAuth backend success');
        return OAuthLoginResponse.fromJson(responseData);
      } else {
        _log(
          'OAuth backend failed: status=${response.statusCode}, body=$responseData',
        );
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
    } on SocketException catch (e, stackTrace) {
      _log('OAuth backend SocketException', error: e, stackTrace: stackTrace);
      return const OAuthLoginResponse(success: false, error: '網路連接失敗，請檢查網路設置');
    } on HttpException catch (e, stackTrace) {
      _log('OAuth backend HttpException', error: e, stackTrace: stackTrace);
      return const OAuthLoginResponse(success: false, error: 'HTTP請求失敗');
    } on FormatException catch (e, stackTrace) {
      _log('OAuth backend FormatException', error: e, stackTrace: stackTrace);
      return const OAuthLoginResponse(success: false, error: '響應格式錯誤');
    } catch (e, stackTrace) {
      _log('OAuth backend unknown exception', error: e, stackTrace: stackTrace);
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
            accessToken: googleAuth.accessToken ?? googleAuth.idToken,
            idToken: googleAuth.idToken,
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
