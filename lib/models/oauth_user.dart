// 導入必要的依賴
import 'user.dart';
import 'captcha_response.dart';

/// OAuth 用戶數據模型
class OAuthUser {
  final String id;
  final String email;
  final String name;
  final String? avatar;
  final String provider; // 'google', 'facebook', 'line'
  final String? accessToken;
  final String? idToken;
  final String? refreshToken;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  const OAuthUser({
    required this.id,
    required this.email,
    required this.name,
    this.avatar,
    required this.provider,
    this.accessToken,
    this.idToken,
    this.refreshToken,
    this.createdAt,
    this.lastLoginAt,
  });

  factory OAuthUser.fromJson(Map<String, dynamic> json) {
    return OAuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      provider: json['provider'] as String,
      accessToken: json['access_token'] as String?,
      idToken: json['id_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar': avatar,
      'provider': provider,
      'access_token': accessToken,
      'id_token': idToken,
      'refresh_token': refreshToken,
      'created_at': createdAt?.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }

  /// 轉換為標準 User 模型
  User toUser() {
    return User(
      id: id,
      email: email,
      name: name,
      avatar: avatar,
      createdAt: createdAt ?? DateTime.now(),
      lastLoginAt: lastLoginAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'OAuthUser(id: $id, email: $email, name: $name, provider: $provider)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OAuthUser &&
        other.id == id &&
        other.email == email &&
        other.provider == provider;
  }

  @override
  int get hashCode {
    return id.hashCode ^ email.hashCode ^ provider.hashCode;
  }
}

/// OAuth 登入請求
class OAuthLoginRequest {
  final String provider;
  final String accessToken;
  final String? idToken;
  final Map<String, dynamic>? userInfo;

  const OAuthLoginRequest({
    required this.provider,
    required this.accessToken,
    this.idToken,
    this.userInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'access_token': accessToken,
      'id_token': idToken,
      'user_info': userInfo,
    };
  }
}

/// OAuth 登入響應
class OAuthLoginResponse {
  final bool success;
  final String? token;
  final String? refreshToken;
  final OAuthUser? user;
  final String? error;
  final bool captchaRequired;
  final CaptchaResponse? captcha;

  const OAuthLoginResponse({
    required this.success,
    this.token,
    this.refreshToken,
    this.user,
    this.error,
    this.captchaRequired = false,
    this.captcha,
  });

  factory OAuthLoginResponse.fromJson(Map<String, dynamic> json) {
    return OAuthLoginResponse(
      success: json['success'] as bool,
      token: json['token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      user: json['user'] != null
          ? OAuthUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      error: json['error'] as String?,
      captchaRequired: json['captcha_required'] as bool? ?? false,
      captcha: json['captcha'] != null
          ? CaptchaResponse.fromJson(json['captcha'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// OAuth 提供商枚舉
enum OAuthProvider {
  google('google', 'Google'),
  facebook('facebook', 'Facebook'),
  line('line', 'LINE');

  const OAuthProvider(this.value, this.displayName);

  final String value;
  final String displayName;

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
}
