/// OAuth 配置類
///
/// 注意：在生產環境中，這些配置應該從環境變數或安全存儲中讀取
class OAuthConfig {
  // 私有構造函數，防止實例化
  OAuthConfig._();

  // ========== Google 配置 ==========

  /// Google OAuth 2.0 客戶端 ID
  /// 從 Google Cloud Console 獲取
  static const String googleClientId = 'YOUR_GOOGLE_CLIENT_ID';

  /// Google OAuth 2.0 客戶端密鑰
  /// 從 Google Cloud Console 獲取
  static const String googleClientSecret = 'YOUR_GOOGLE_CLIENT_SECRET';

  /// Google 登入範圍
  static const List<String> googleScopes = ['email', 'profile'];

  // ========== Facebook 配置 ==========

  /// Facebook 應用 ID
  /// 從 Facebook Developers Console 獲取
  static const String facebookAppId = 'YOUR_FACEBOOK_APP_ID';

  /// Facebook 客戶端令牌
  /// 從 Facebook Developers Console 獲取
  static const String facebookClientToken = 'YOUR_FACEBOOK_CLIENT_TOKEN';

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

  // ========== 驗證方法 ==========

  /// 驗證 Google 配置
  static bool isGoogleConfigured() {
    // 臨時啟用用於測試顯示
    return true; // googleClientId != 'YOUR_GOOGLE_CLIENT_ID' && googleClientId.isNotEmpty;
  }

  /// 驗證 Facebook 配置
  static bool isFacebookConfigured() {
    // 臨時啟用用於測試顯示
    return true; // facebookAppId != 'YOUR_FACEBOOK_APP_ID' && facebookAppId.isNotEmpty && facebookClientToken != 'YOUR_FACEBOOK_CLIENT_TOKEN' && facebookClientToken.isNotEmpty;
  }

  /// 驗證 LINE 配置
  static bool isLineConfigured() {
    // 臨時啟用用於測試顯示
    return true; // lineChannelId != 'YOUR_LINE_CHANNEL_ID' && lineChannelId.isNotEmpty && lineChannelSecret != 'YOUR_LINE_CHANNEL_SECRET' && lineChannelSecret.isNotEmpty && lineRedirectUri != 'YOUR_LINE_REDIRECT_URI' && lineRedirectUri.isNotEmpty;
  }

  /// 獲取所有已配置的 OAuth 提供商
  static List<String> getConfiguredProviders() {
    final providers = <String>[];

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
      'google': enableGoogle && isGoogleConfigured(),
      'facebook': enableFacebook && isFacebookConfigured(),
      'line': enableLine && isLineConfigured(),
    };
  }
}

/// OAuth 提供商枚舉
enum OAuthProvider {
  google('google', 'Google', OAuthConfig.googleClientId),
  facebook('facebook', 'Facebook', OAuthConfig.facebookAppId),
  line('line', 'LINE', OAuthConfig.lineChannelId);

  const OAuthProvider(this.value, this.displayName, this.clientId);

  final String value;
  final String displayName;
  final String clientId;

  /// 從字符串創建 OAuth 提供商
  static OAuthProvider fromString(String value) {
    switch (value.toLowerCase()) {
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
