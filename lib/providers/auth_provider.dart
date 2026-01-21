import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import '../models/user.dart';
import '../models/captcha_response.dart';
import '../models/oauth_user.dart';
import '../services/auth_api_service.dart';
import '../services/oauth_service.dart';
import '../services/notification_service.dart';
import '../config/test_config.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  // 安全相關屬性
  int _loginAttempts = 0;
  DateTime? _lastFailedAttempt;
  bool _isAccountLocked = false;
  DateTime? _lockoutUntil;
  String? _lockedEmail;
  final List<String> _blockedIPs = [];

  // API相關屬性
  CaptchaResponse? _currentCaptcha;
  String? _authToken;
  String? _refreshToken;

  // OAuth相關屬性
  OAuthUser? _oauthUser;
  String? _oauthProvider;

  // 安全設定
  static const int maxLoginAttempts = 5;
  static const int lockoutDurationMinutes = 15;
  static const int maxAttemptsPerMinute = 3;
  static const int attemptResetHours = 24; // 登入嘗試次數重置時間（小時）

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isAccountLocked => _isAccountLocked;
  int get remainingAttempts {
    return maxLoginAttempts - _loginAttempts;
  }

  CaptchaResponse? get currentCaptcha => _currentCaptcha;
  String? get authToken => _authToken;
  OAuthUser? get oauthUser => _oauthUser;
  String? get oauthProvider => _oauthProvider;

  Future<bool> login(
    String email,
    String password, {
    String? captchaCode,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 測試模式檢查
      if (TestConfig.enableTestMode) {
        print('🔧 [AuthProvider] ${TestConfig.testModeInfo}');
        print(
          '🔧 [AuthProvider] 跳過的檢查: ${TestConfig.skippedChecks.join(', ')}',
        );
      }

      // 1. 檢查帳戶是否被鎖定
      if (!TestConfig.skipAccountLockCheck &&
          await _isAccountLockedForEmail(email)) {
        _error = '帳戶已被鎖定，請稍後再試';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 2. 檢查登入嘗試次數
      if (!TestConfig.skipLoginAttemptLimit &&
          _loginAttempts >= maxLoginAttempts) {
        await _lockAccount(email);
        _error = '登入嘗試次數過多，帳戶已被鎖定15分鐘';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 3. 檢查速率限制
      if (!TestConfig.skipRateLimitCheck && !_checkRateLimit()) {
        _error = '嘗試次數過於頻繁，請稍後再試';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 4. 驗證輸入
      if (!_validateLoginInput(email, password)) {
        _error = '請輸入有效的電子郵件和密碼';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 5. 檢查驗證碼（強制要求）
      if (captchaCode == null || captchaCode.isEmpty) {
        _error = '請輸入驗證碼';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (_currentCaptcha?.captchaId == null) {
        _error = '驗證碼已過期，請刷新後重試';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 6. 調用真實的API進行登入驗證
      print('🔧 [AuthProvider] 準備登入請求:');
      print('🔧 [AuthProvider] Email: $email');
      print('🔧 [AuthProvider] CaptchaId: ${_currentCaptcha!.captchaId}');
      print('🔧 [AuthProvider] CaptchaCode: $captchaCode');

      final loginRequest = LoginRequest(
        email: email,
        password: password,
        captchaId: _currentCaptcha!.captchaId,
        captchaCode: captchaCode,
      );

      final loginResponse = await AuthApiService.login(loginRequest);

      print('🔧 [AuthProvider] 登入響應處理:');
      print('🔧 [AuthProvider] Success: ${loginResponse.success}');
      print('🔧 [AuthProvider] Token: ${loginResponse.token}');
      print('🔧 [AuthProvider] Error: ${loginResponse.error}');
      print('🔧 [AuthProvider] User: ${loginResponse.user}');

      if (loginResponse.success) {
        // 登入成功，重置嘗試次數和驗證碼
        await _resetLoginAttempts();
        _currentCaptcha = null;
        _authToken = loginResponse.token;
        _refreshToken = loginResponse.refreshToken;
        if (_authToken != null) {
          await NotificationService.instance.updateAuthToken(_authToken!);
        }

        if (loginResponse.user != null) {
          _user = User(
            id: loginResponse.user!.id,
            email: loginResponse.user!.email,
            name: loginResponse.user!.name,
            avatar: loginResponse.user!.avatar,
            createdAt: loginResponse.user!.createdAt,
            lastLoginAt: loginResponse.user!.lastLoginAt,
          );
        }

        // 保存token和用戶信息到本地存儲
        await _saveTokens();
        await _saveUserData();

        // Register FCM token with backend when login success
        try {
          // Lazy import to avoid circular dep in analyzer
          // ignore: avoid_dynamic_calls
          // We'll call NotificationService via a dynamic lookup at app init
        } catch (_) {}

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // 登入失敗處理
        if (!TestConfig.skipIncrementFailedAttempts) {
          await _incrementLoginAttempts();
        } else {
          print('🔧 [AuthProvider] 測試模式：跳過登入失敗嘗試次數增加');
        }

        if (loginResponse.captcha != null) {
          // 獲取新的驗證碼
          _currentCaptcha = loginResponse.captcha;
        } else {
          // 如果沒有提供新驗證碼，獲取一個新的
          await fetchCaptcha();
        }

        _error = loginResponse.error ?? '登入失敗，請檢查帳號密碼和驗證碼';

        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = '登入失敗：${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 模擬註冊API調用
      await Future.delayed(const Duration(seconds: 2));

      // 模擬註冊成功
      if (email.isNotEmpty && password.isNotEmpty && name.isNotEmpty) {
        _user = User(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          email: email,
          name: name,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = '請填寫所有必要欄位';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = '註冊失敗：${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await logoutWithApi();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ========== OAuth 登入方法 ==========

  /// Google 登入
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await OAuthService.signInWithGoogle();

      if (response.success) {
        await _handleOAuthSuccess(response);
        return true;
      } else {
        _error = response.error ?? 'Google 登入失敗';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Google 登入失敗：${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Facebook 登入
  Future<bool> signInWithFacebook() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await OAuthService.signInWithFacebook();

      if (response.success) {
        await _handleOAuthSuccess(response);
        return true;
      } else {
        _error = response.error ?? 'Facebook 登入失敗';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Facebook 登入失敗：${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// LINE 登入
  Future<bool> signInWithLine() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await OAuthService.signInWithLine();

      if (response.success) {
        await _handleOAuthSuccess(response);
        return true;
      } else {
        _error = response.error ?? 'LINE 登入失敗';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'LINE 登入失敗：${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 處理 OAuth 登入成功
  Future<void> _handleOAuthSuccess(OAuthLoginResponse response) async {
    if (response.user != null) {
      _oauthUser = response.user;
      _oauthProvider = response.user!.provider;
      _user = response.user!.toUser();
    }

    if (response.token != null) {
      _authToken = response.token;
    }
    if (response.refreshToken != null) {
      _refreshToken = response.refreshToken;
    }

    // 重置登入嘗試次數（OAuth 登入成功）
    await _resetLoginAttempts();

    // 保存數據到本地存儲
    await _saveTokens();
    await _saveUserData();
    await _saveOAuthData();

    if (_authToken != null) {
      await NotificationService.instance.updateAuthToken(_authToken!);
    }

    _isLoading = false;
    notifyListeners();
  }

  // ========== 安全相關私有方法 ==========

  /// 檢查帳戶是否被鎖定
  Future<bool> _isAccountLockedForEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutData = prefs.getString('lockout_$email');

    if (lockoutData != null) {
      final data = jsonDecode(lockoutData);
      final lockoutUntil = DateTime.parse(data['lockoutUntil']);

      if (DateTime.now().isBefore(lockoutUntil)) {
        return true;
      } else {
        // 鎖定時間已過，清除鎖定狀態
        await prefs.remove('lockout_$email');
      }
    }
    return false;
  }

  /// 鎖定帳戶
  Future<void> _lockAccount(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutUntil = DateTime.now().add(
      Duration(minutes: lockoutDurationMinutes),
    );

    final lockoutData = {
      'email': email,
      'lockoutUntil': lockoutUntil.toIso8601String(),
      'lockedAt': DateTime.now().toIso8601String(),
    };

    await prefs.setString('lockout_$email', jsonEncode(lockoutData));
    _isAccountLocked = true;
    _lockoutUntil = lockoutUntil;
    _lockedEmail = email;
  }

  /// 檢查速率限制
  bool _checkRateLimit() {
    final now = DateTime.now();

    if (_lastFailedAttempt != null) {
      final timeDiff = now.difference(_lastFailedAttempt!);
      if (timeDiff.inMinutes < 1 && _loginAttempts >= maxAttemptsPerMinute) {
        return false;
      }
    }
    return true;
  }

  /// 驗證登入輸入
  bool _validateLoginInput(String email, String password) {
    // 基本驗證
    if (email.isEmpty || password.isEmpty) {
      return false;
    }

    // 電子郵件格式驗證
    // final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    // if (!emailRegex.hasMatch(email)) {
    //   return false;
    // }

    // 密碼長度驗證
    if (password.length < 6) {
      return false;
    }

    return true;
  }

  /// 模擬登入驗證（可替換為真實API調用）
  Future<bool> _simulateLoginValidation(String email, String password) async {
    // 這裡是模擬驗證邏輯
    // 在真實應用中，這裡會調用後端API
    await Future.delayed(const Duration(milliseconds: 500));

    // 模擬一些有效的測試帳戶
    final validAccounts = {
      'test@example.com': 'password123',
      'admin@example.com': 'admin123',
      'user@example.com': 'user123',
    };

    return validAccounts[email] == password;
  }

  /// 增加登入嘗試次數
  Future<void> _incrementLoginAttempts() async {
    // 檢查是否需要重置嘗試次數（基於時間）
    await _checkAndResetAttemptsIfExpired();

    _loginAttempts++;
    _lastFailedAttempt = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('login_attempts', _loginAttempts);
    await prefs.setString(
      'last_failed_attempt',
      _lastFailedAttempt!.toIso8601String(),
    );
  }

  /// 重置登入嘗試次數
  Future<void> _resetLoginAttempts() async {
    _loginAttempts = 0;
    _lastFailedAttempt = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('login_attempts');
    await prefs.remove('last_failed_attempt');
  }

  /// 初始化安全狀態
  Future<void> _initializeSecurityState() async {
    final prefs = await SharedPreferences.getInstance();
    _loginAttempts = prefs.getInt('login_attempts') ?? 0;

    final lastFailedAttemptStr = prefs.getString('last_failed_attempt');
    if (lastFailedAttemptStr != null) {
      _lastFailedAttempt = DateTime.parse(lastFailedAttemptStr);
    }

    // 初始化時檢查是否需要重置嘗試次數
    await _checkAndResetAttemptsIfExpired();
  }

  /// 檢查並重置過期的登入嘗試次數
  Future<void> _checkAndResetAttemptsIfExpired() async {
    if (_lastFailedAttempt == null) return;

    final now = DateTime.now();
    final timeSinceLastAttempt = now.difference(_lastFailedAttempt!);

    // 如果距離上次失敗嘗試超過設定的重置時間，則重置嘗試次數
    if (timeSinceLastAttempt.inHours >= attemptResetHours) {
      await _resetLoginAttempts();
    }
  }

  /// 檢查IP是否被封鎖
  bool _isIPBlocked(String ip) {
    return _blockedIPs.contains(ip);
  }

  /// 封鎖IP
  void _blockIP(String ip) {
    if (!_blockedIPs.contains(ip)) {
      _blockedIPs.add(ip);
    }
  }

  /// 生成簡單驗證碼（用於演示）
  String generateSimpleCaptcha() {
    final random = DateTime.now().millisecondsSinceEpoch % 10000;
    return random.toString().padLeft(4, '0');
  }

  /// 驗證驗證碼
  bool validateCaptcha(String input, String expected) {
    return input == expected;
  }

  /// 獲取帳戶鎖定剩餘時間
  Duration? getLockoutRemainingTime() {
    if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
      return _lockoutUntil!.difference(DateTime.now());
    }
    return null;
  }

  /// 手動解鎖帳戶（管理員功能）
  Future<void> unlockAccount(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lockout_$email');
    _isAccountLocked = false;
    _lockoutUntil = null;
    _lockedEmail = null;
    notifyListeners();
  }

  /// 手動重置登入嘗試次數（管理員功能）
  Future<void> resetLoginAttempts() async {
    await _resetLoginAttempts();
    notifyListeners();
  }

  /// 獲取登入嘗試次數下次重置時間
  DateTime? getNextAttemptResetTime() {
    if (_lastFailedAttempt == null) return null;
    return _lastFailedAttempt!.add(Duration(hours: attemptResetHours));
  }

  /// 獲取距離下次重置的剩餘時間
  Duration? getTimeUntilAttemptReset() {
    final nextReset = getNextAttemptResetTime();
    if (nextReset == null) return null;

    final now = DateTime.now();
    if (now.isAfter(nextReset)) return Duration.zero;

    return nextReset.difference(now);
  }

  // ========== API相關方法 ==========

  /// 獲取驗證碼
  Future<CaptchaResponse?> fetchCaptcha({bool silent = false}) async {
    try {
      print('🔧 [AuthProvider] 開始獲取驗證碼...');
      _isLoading = true;
      if (!silent) notifyListeners();

      final captcha = await AuthApiService.getCaptcha();
      _currentCaptcha = captcha;

      print('🔧 [AuthProvider] 驗證碼獲取成功: ${captcha.captchaId}');

      _isLoading = false;
      notifyListeners();
      return captcha;
    } catch (e) {
      print('🔧 [AuthProvider] 驗證碼獲取失敗: ${e.toString()}');
      _error = '獲取驗證碼失敗：${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// 刷新驗證碼
  Future<CaptchaResponse?> refreshCaptcha() async {
    if (_currentCaptcha == null) {
      return await fetchCaptcha();
    }

    try {
      _isLoading = true;
      notifyListeners();

      final captcha = await AuthApiService.refreshCaptcha(
        _currentCaptcha!.captchaId,
      );
      _currentCaptcha = captcha;

      _isLoading = false;
      notifyListeners();
      return captcha;
    } catch (e) {
      _error = '刷新驗證碼失敗：${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// 使用API進行註冊
  Future<bool> registerWithApi(
    String email,
    String password,
    String name,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await AuthApiService.register(
        email: email,
        password: password,
        name: name,
      );

      if (response.success) {
        _authToken = response.token;
        _refreshToken = response.refreshToken;

        if (response.user != null) {
          _user = User(
            id: response.user!.id,
            email: response.user!.email,
            name: response.user!.name,
            avatar: response.user!.avatar,
            createdAt: response.user!.createdAt,
            lastLoginAt: response.user!.lastLoginAt,
          );
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? '註冊失敗';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = '註冊失敗：${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 使用API進行登出
  Future<void> logoutWithApi() async {
    if (_authToken != null) {
      await AuthApiService.logout(_authToken!);
    }

    // OAuth 登出
    await OAuthService.signOutAll();

    // Try revoke FCM token on backend (best-effort)
    try {
      if (_authToken != null) {
        await NotificationService.instance.revokeCurrentToken();
      }
    } catch (_) {}

    _user = null;
    _authToken = null;
    _refreshToken = null;
    _currentCaptcha = null;
    _oauthUser = null;
    _oauthProvider = null;
    _error = null;

    // 清除本地存儲的數據
    await _clearStoredData();

    notifyListeners();
  }

  /// 刷新認證令牌
  Future<bool> refreshAuthToken() async {
    if (_refreshToken == null) {
      return false;
    }

    try {
      final response = await AuthApiService.refreshToken(_refreshToken!);

      if (response.success) {
        _authToken = response.token;
        _refreshToken = response.refreshToken;
        // 保存刷新後的token到本地存儲
        await _saveTokens();
        notifyListeners();
        return true;
      } else {
        // 刷新失敗時先保留本地登入狀態，交由後續 API 決定是否失效
        return false;
      }
    } catch (e) {
      // 無論網路或其他錯誤，都先保留既有狀態，讓後續 API 決定是否需要重新登入
      if (kDebugMode) {
        print('🔧 [AuthProvider] 刷新 Token 失敗，暫保留狀態: $e');
      }
      return true;
    }
  }

  /// 檢查是否需要驗證碼（始終需要）
  bool shouldShowCaptcha() {
    return true; // 始終需要驗證碼
  }

  /// 清除驗證碼
  void clearCaptcha() {
    _currentCaptcha = null;
    notifyListeners();
  }

  // ========== Token 和用戶數據管理 ==========

  /// 保存token到本地存儲
  Future<void> _saveTokens() async {
    final prefs = await SharedPreferences.getInstance();
    if (_authToken != null) {
      await prefs.setString('auth_token', _authToken!);
    } else {
      await prefs.remove('auth_token');
    }
    if (_refreshToken != null) {
      await prefs.setString('refresh_token', _refreshToken!);
    } else {
      await prefs.remove('refresh_token');
    }
  }

  /// 保存用戶數據到本地存儲
  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (_user != null) {
      await prefs.setString('user_data', jsonEncode(_user!.toJson()));
    } else {
      await prefs.remove('user_data');
    }
  }

  /// 從本地存儲恢復token
  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  /// 從本地存儲恢復用戶數據
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataStr = prefs.getString('user_data');
    if (userDataStr != null) {
      try {
        final userData = jsonDecode(userDataStr);
        _user = User.fromJson(userData);
      } catch (e) {
        // 如果解析失敗，清除無效數據
        await prefs.remove('user_data');
      }
    }
  }

  /// 保存 OAuth 數據到本地存儲
  Future<void> _saveOAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    if (_oauthUser != null) {
      await prefs.setString(
        'oauth_user_data',
        jsonEncode(_oauthUser!.toJson()),
      );
      await prefs.setString('oauth_provider', _oauthProvider ?? '');
    } else {
      await prefs.remove('oauth_user_data');
      await prefs.remove('oauth_provider');
    }
  }

  /// 從本地存儲恢復 OAuth 數據
  Future<void> _loadOAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final oauthUserDataStr = prefs.getString('oauth_user_data');
    if (oauthUserDataStr != null) {
      try {
        final oauthUserData = jsonDecode(oauthUserDataStr);
        _oauthUser = OAuthUser.fromJson(oauthUserData);
        _oauthProvider = prefs.getString('oauth_provider');
      } catch (e) {
        // 如果解析失敗，清除無效數據
        await prefs.remove('oauth_user_data');
        await prefs.remove('oauth_provider');
      }
    }
  }

  /// 清除本地存儲的token和用戶數據
  Future<void> _clearStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_data');
    await prefs.remove('oauth_user_data');
    await prefs.remove('oauth_provider');
  }

  /// 初始化認證狀態（應用啟動時調用）
  Future<void> initializeAuth() async {
    await _loadTokens();
    await _loadUserData();
    await _loadOAuthData();
    await _initializeSecurityState();

    // 如果 access token 即將過期才刷新，避免不必要的 refresh 旋轉
    if (_refreshToken != null &&
        (_authToken == null || _isTokenExpiringSoon(_authToken!))) {
      await refreshAuthToken();
    }

    notifyListeners();
  }

  bool _isTokenExpiringSoon(
    String token, {
    Duration threshold = const Duration(minutes: 2),
  }) {
    final expiry = _getJwtExpiry(token);
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry.subtract(threshold));
  }

  DateTime? _getJwtExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final jsonMap = jsonDecode(decoded);
      final exp = jsonMap is Map<String, dynamic> ? jsonMap['exp'] : null;
      if (exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true)
            .toLocal();
      }
      if (exp is String) {
        final parsed = int.tryParse(exp);
        if (parsed != null) {
          return DateTime.fromMillisecondsSinceEpoch(parsed * 1000, isUtc: true)
              .toLocal();
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
