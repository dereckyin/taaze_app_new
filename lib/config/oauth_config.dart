import 'dart:io' show Platform;

/// OAuth 配置類
///
/// 注意：在生產環境中，這些配置應該從環境變數或安全存儲中讀取
class OAuthConfig {
  // 私有構造函數，防止實例化
  OAuthConfig._();

  // ========== Apple 配置 ==========

  /// Sign in with Apple 的 Service ID（僅 Android / Web 流程需要）。
  /// iOS / macOS 原生流程使用 App 的 Bundle ID，不需要此值。
  static const String appleServiceId = 'tw.com.taaze.readlife.signin';

  /// Sign in with Apple 在 Android / Web 流程的重新導向 URI（後端轉接端點）。
  static const String appleRedirectUri =
      'https://www.taaze.tw/auth/apple/callback';

  // ========== Google 配置 ==========

  /// Google OAuth 2.0 客戶端 ID (iOS)
  /// 從 Google Cloud Console 獲取 iOS 類型的 OAuth Client ID
  static const String googleClientIdIOS =
      '742486726494-0hrekm20m41n75j1moucd5ag54d25da6.apps.googleusercontent.com';

  /// Google OAuth 2.0 客戶端 ID (Android)
  /// 從 Google Cloud Console 獲取 Android 類型的 OAuth Client ID
  static const String googleClientIdAndroid =
      '742486726494-gf7057p166hbtvlr4gq72dsvlvuqhuva.apps.googleusercontent.com';

  /// Google OAuth 2.0 客戶端密鑰
  /// 從 Google Cloud Console 獲取
  static const String googleClientSecret = 'YOUR_GOOGLE_CLIENT_SECRET';

  /// Google 登入範圍
  static const List<String> googleScopes = ['email', 'profile'];

  // ========== Facebook 配置 ==========

  /// Facebook 應用 ID
  /// 從 Facebook Developers Console 獲取
  static const String facebookAppId = '1556848302106102';

  /// Facebook 客戶端令牌
  /// 從 Facebook Developers Console 獲取
  static const String facebookClientToken = '952e7929a31122f148758c7c766bbd83';

  /// Facebook 登入權限
  static const List<String> facebookPermissions = ['email', 'public_profile'];

  // ========== LINE 配置 ==========

  /// LINE Channel ID
  /// 從 LINE Developers Console 獲取
  static const String lineChannelId = 'YOUR_LINE_CHANNEL_ID';

  /// LINE Channel Secret
  /// 從 LINE Developers Console 獲取
  static const String lineChannelSecret = 'YOUR_LINE_CHANNEL_SECRET';

  /// LINE 登入重定向 URI
  static const String lineRedirectUri = 'YOUR_LINE_REDIRECT_URI';

  /// LINE 登入範圍
  static const List<String> lineScopes = ['profile', 'openid', 'email'];

  // ========== 通用配置 ==========

  // 注意：API 端點現在由 ApiConfig 統一管理
  // 請使用 ApiConfig.baseUrl 來獲取當前 API 端點

  /// 請求超時時間
  static const Duration requestTimeout = Duration(seconds: 30);

  /// 是否啟用 OAuth 登入
  static const bool enableOAuth = true;

  /// 是否啟用 Google 登入
  static const bool enableGoogle = true;

  /// 是否啟用 Facebook 登入
  static const bool enableFacebook = true;

  /// 是否啟用 LINE 登入
  static const bool enableLine = true;

  /// 是否啟用 Sign in with Apple
  /// 依 App Store 審查指南 4.8，若提供第三方登入（Google/Facebook 等），
  /// 必須在 Apple 平台同時提供 Sign in with Apple。
  static const bool enableApple = true;

  // ========== 驗證方法 ==========

  /// 驗證 Google 配置（檢查 iOS 和 Android 是否至少有一個已配置）
  static bool isGoogleConfigured() {
    // 檢查 iOS 或 Android 是否至少有一個已配置
    final iosConfigured =
        googleClientIdIOS != 'YOUR_GOOGLE_CLIENT_ID_IOS' &&
        googleClientIdIOS.isNotEmpty;
    final androidConfigured =
        googleClientIdAndroid != 'YOUR_GOOGLE_CLIENT_ID_ANDROID' &&
        googleClientIdAndroid.isNotEmpty;
    return iosConfigured || androidConfigured;
  }

  /// 獲取當前平台的 Google Client ID
  static String? getGoogleClientIdForPlatform() {
    // 使用 dart:io 來檢測平台
    try {
      if (identical(0, 0.0)) {
        // 這是一個編譯時檢查，無法在運行時檢測平台
        // 所以我們需要在 OAuthService 中根據平台動態選擇
        return null;
      }
    } catch (_) {}
    return null;
  }

  /// 驗證 Facebook 配置
  static bool isFacebookConfigured() {
    // 若未正確填入 appId / clientToken，視為未配置
    return facebookAppId.isNotEmpty && facebookClientToken.isNotEmpty;
  }

  /// 驗證 Apple 配置
  ///
  /// Sign in with Apple 僅在 Apple 平台（iOS / macOS）提供原生流程，
  /// 在這些平台上一律視為已配置（系統內建支援）。
  static bool isAppleConfigured() {
    try {
      return Platform.isIOS || Platform.isMacOS;
    } catch (_) {
      // 非原生平台（例如測試環境）預設為未配置
      return false;
    }
  }

  /// 驗證 LINE 配置
  static bool isLineConfigured() {
    // 需要有 channelId / channelSecret / redirectUri 才視為已配置
    return lineChannelId != 'YOUR_LINE_CHANNEL_ID' &&
        lineChannelSecret != 'YOUR_LINE_CHANNEL_SECRET' &&
        lineRedirectUri != 'YOUR_LINE_REDIRECT_URI' &&
        lineChannelId.isNotEmpty &&
        lineChannelSecret.isNotEmpty &&
        lineRedirectUri.isNotEmpty;
  }

  /// 獲取所有已配置的 OAuth 提供商
  static List<String> getConfiguredProviders() {
    final providers = <String>[];

    // 依 Apple Human Interface Guidelines，Sign in with Apple 應優先顯示
    if (enableApple && isAppleConfigured()) {
      providers.add('apple');
    }

    if (enableGoogle && isGoogleConfigured()) {
      providers.add('google');
    }

    if (enableFacebook && isFacebookConfigured()) {
      providers.add('facebook');
    }

    if (enableLine && isLineConfigured()) {
      providers.add('line');
    }

    return providers;
  }

  /// 檢查是否至少有一個 OAuth 提供商已配置
  static bool hasAnyProviderConfigured() {
    return getConfiguredProviders().isNotEmpty;
  }

  /// 獲取配置狀態摘要
  static Map<String, bool> getConfigurationStatus() {
    return {
      'apple': enableApple && isAppleConfigured(),
      'google': enableGoogle && isGoogleConfigured(),
      'facebook': enableFacebook && isFacebookConfigured(),
      'line': enableLine && isLineConfigured(),
    };
  }
}

/// OAuth 提供商枚舉
enum OAuthProvider {
  apple('apple', 'Apple', ''),
  google('google', 'Google', OAuthConfig.googleClientIdIOS),
  facebook('facebook', 'Facebook', OAuthConfig.facebookAppId),
  line('line', 'LINE', OAuthConfig.lineChannelId);

  const OAuthProvider(this.value, this.displayName, this.clientId);

  final String value;
  final String displayName;
  final String clientId;

  /// 從字符串創建 OAuth 提供商
  static OAuthProvider fromString(String value) {
    switch (value.toLowerCase()) {
      case 'apple':
        return OAuthProvider.apple;
      case 'google':
        return OAuthProvider.google;
      case 'facebook':
        return OAuthProvider.facebook;
      case 'line':
        return OAuthProvider.line;
      default:
        throw ArgumentError('Unknown OAuth provider: $value');
    }
  }

  /// 檢查提供商是否已配置
  bool get isConfigured {
    switch (this) {
      case OAuthProvider.apple:
        return OAuthConfig.isAppleConfigured();
      case OAuthProvider.google:
        return OAuthConfig.isGoogleConfigured();
      case OAuthProvider.facebook:
        return OAuthConfig.isFacebookConfigured();
      case OAuthProvider.line:
        return OAuthConfig.isLineConfigured();
    }
  }

  /// 檢查提供商是否啟用
  bool get isEnabled {
    switch (this) {
      case OAuthProvider.apple:
        return OAuthConfig.enableApple;
      case OAuthProvider.google:
        return OAuthConfig.enableGoogle;
      case OAuthProvider.facebook:
        return OAuthConfig.enableFacebook;
      case OAuthProvider.line:
        return OAuthConfig.enableLine;
    }
  }

  /// 檢查提供商是否可用（啟用且已配置）
  bool get isAvailable => isEnabled && isConfigured;
}
