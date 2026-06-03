import 'package:flutter/foundation.dart';

/// 測試配置類
class TestConfig {
  // 私有構造函數，防止實例化
  TestConfig._();
  
  /// 是否啟用測試模式（Release 建置自動關閉）
  /// 在測試模式下會跳過安全限制檢查
  static bool get enableTestMode => !kReleaseMode;
  
  /// 是否跳過帳戶鎖定檢查
  static bool get skipAccountLockCheck => enableTestMode;
  
  /// 是否跳過登入嘗試次數限制
  static bool get skipLoginAttemptLimit => enableTestMode;
  
  /// 是否跳過速率限制檢查
  static bool get skipRateLimitCheck => enableTestMode;
  
  /// 是否跳過登入失敗嘗試次數增加
  static bool get skipIncrementFailedAttempts => enableTestMode;
  
  /// 獲取測試模式信息
  static String get testModeInfo {
    if (enableTestMode) {
      return '測試模式已啟用 - 安全限制已禁用';
    } else {
      return '生產模式 - 所有安全限制已啟用';
    }
  }
  
  /// 獲取跳過的檢查列表
  static List<String> get skippedChecks {
    final List<String> checks = [];
    
    if (skipAccountLockCheck) {
      checks.add('帳戶鎖定檢查');
    }
    if (skipLoginAttemptLimit) {
      checks.add('登入嘗試次數限制');
    }
    if (skipRateLimitCheck) {
      checks.add('速率限制檢查');
    }
    if (skipIncrementFailedAttempts) {
      checks.add('登入失敗嘗試次數增加');
    }
    
    return checks;
  }
}

