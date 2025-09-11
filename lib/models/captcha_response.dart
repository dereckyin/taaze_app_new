/// 驗證碼響應模型
class CaptchaResponse {
  final String captchaId;
  final String captchaImage; // Base64編碼的圖片或文字
  final String? captchaText; // 文字驗證碼（用於測試）
  final bool required;
  final String? message;

  CaptchaResponse({
    required this.captchaId,
    required this.captchaImage,
    this.captchaText,
    required this.required,
    this.message,
  });

  factory CaptchaResponse.fromJson(Map<String, dynamic> json) {
    return CaptchaResponse(
      captchaId: json['captcha_id'] ?? json['captchaId'] ?? '',
      captchaImage: json['captcha_image'] ?? json['captchaImage'] ?? '',
      captchaText: json['captchaText'],
      required: json['required'] ?? false,
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'captchaId': captchaId,
      'captchaImage': captchaImage,
      'captchaText': captchaText,
      'required': required,
      'message': message,
    };
  }
}

/// 登入請求模型
class LoginRequest {
  final String email;
  final String password;
  final String? captchaId;
  final String? captchaCode;

  LoginRequest({
    required this.email,
    required this.password,
    this.captchaId,
    this.captchaCode,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'email': email, 'password': password};

    // 只添加非空的驗證碼字段，使用下劃線命名
    if (captchaId != null && captchaId!.isNotEmpty) {
      data['captcha_id'] = captchaId;
    }
    if (captchaCode != null && captchaCode!.isNotEmpty) {
      data['captcha_code'] = captchaCode;
    }

    return data;
  }
}

/// 登入響應模型
class LoginResponse {
  final bool success;
  final String? token;
  final String? refreshToken;
  final UserData? user;
  final String? error;
  final bool captchaRequired;
  final CaptchaResponse? captcha;

  LoginResponse({
    required this.success,
    this.token,
    this.refreshToken,
    this.user,
    this.error,
    this.captchaRequired = false,
    this.captcha,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      token: json['token'],
      refreshToken: json['refresh_token'] ?? json['refreshToken'],
      user: json['user'] != null ? UserData.fromJson(json['user']) : null,
      error: json['error'],
      captchaRequired:
          json['captcha_required'] ?? json['captchaRequired'] ?? false,
      captcha: json['captcha'] != null
          ? CaptchaResponse.fromJson(json['captcha'])
          : null,
    );
  }
}

/// 用戶數據模型
class UserData {
  final String id;
  final String email;
  final String name;
  final String? avatar;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  UserData({
    required this.id,
    required this.email,
    required this.name,
    this.avatar,
    required this.createdAt,
    required this.lastLoginAt,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      lastLoginAt: DateTime.parse(
        json['lastLoginAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
