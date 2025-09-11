import 'package:flutter/foundation.dart';
import '../providers/auth_provider.dart';

/// 安全功能測試輔助類
class SecurityTestHelper {
  static const String testEmail = 'test@example.com';
  static const String testPassword = 'password123';
  static const String wrongPassword = 'wrongpassword';

  /// 測試登入嘗試次數限制
  static Future<void> testLoginAttemptsLimit(AuthProvider authProvider) async {
    debugPrint('=== 測試登入嘗試次數限制 ===');

    // 嘗試錯誤密碼多次
    for (int i = 1; i <= 6; i++) {
      debugPrint('嘗試 $i: 使用錯誤密碼登入');
      final result = await authProvider.login(testEmail, wrongPassword);
      debugPrint('結果: ${result ? "成功" : "失敗"}');
      debugPrint('剩餘嘗試次數: ${authProvider.remainingAttempts}');
      debugPrint('帳戶鎖定狀態: ${authProvider.isAccountLocked}');

      if (authProvider.isAccountLocked) {
        debugPrint('帳戶已被鎖定！');
        break;
      }
    }
  }

  /// 測試驗證碼功能
  static void testCaptchaGeneration(AuthProvider authProvider) {
    debugPrint('=== 測試驗證碼生成 ===');

    for (int i = 0; i < 5; i++) {
      final captcha = authProvider.generateSimpleCaptcha();
      debugPrint('驗證碼 $i: $captcha');
    }
  }

  /// 測試密碼驗證
  static void testPasswordValidation(AuthProvider authProvider) {
    debugPrint('=== 測試密碼驗證 ===');

    final testPasswords = [
      '', // 空密碼
      '123', // 太短
      '123456', // 剛好6位
      'password', // 只有小寫
      'PASSWORD', // 只有大寫
      'Password1', // 大小寫+數字
      'Password1!', // 完整強度
    ];

    for (final password in testPasswords) {
      final isValid = _validatePassword(password);
      debugPrint('密碼 "$password": ${isValid ? "有效" : "無效"}');
    }
  }

  /// 測試帳戶解鎖
  static Future<void> testAccountUnlock(AuthProvider authProvider) async {
    debugPrint('=== 測試帳戶解鎖 ===');

    // 先鎖定帳戶
    await authProvider.login(testEmail, wrongPassword);
    await authProvider.login(testEmail, wrongPassword);
    await authProvider.login(testEmail, wrongPassword);
    await authProvider.login(testEmail, wrongPassword);
    await authProvider.login(testEmail, wrongPassword);

    debugPrint('帳戶鎖定狀態: ${authProvider.isAccountLocked}');

    // 手動解鎖
    await authProvider.unlockAccount(testEmail);
    debugPrint('解鎖後狀態: ${authProvider.isAccountLocked}');
  }

  /// 私有方法：驗證密碼
  static bool _validatePassword(String password) {
    if (password.isEmpty) return false;
    if (password.length < 6) return false;
    return true;
  }

  /// 運行所有測試
  static Future<void> runAllTests(AuthProvider authProvider) async {
    debugPrint('開始安全功能測試...\n');

    testCaptchaGeneration(authProvider);
    debugPrint('');

    testPasswordValidation(authProvider);
    debugPrint('');

    await testLoginAttemptsLimit(authProvider);
    debugPrint('');

    await testAccountUnlock(authProvider);
    debugPrint('');

    debugPrint('安全功能測試完成！');
  }
}
