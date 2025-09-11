# 登入嘗試次數規則說明

## 概述

本應用實現了完整的登入安全機制，包含登入嘗試次數限制和時間基礎的自動重置功能。

## 規則詳情

### 基本設定

- **最大登入嘗試次數**: 5 次
- **帳戶鎖定時間**: 15 分鐘
- **嘗試次數重置時間**: 24 小時
- **速率限制**: 每分鐘最多 3 次嘗試

### 遞減規則

1. **登入失敗時**:
   - `_loginAttempts` 增加 1
   - 記錄 `_lastFailedAttempt` 時間戳
   - 保存到本地存儲 (SharedPreferences)

2. **登入成功時**:
   - 立即重置 `_loginAttempts` 為 0
   - 清除 `_lastFailedAttempt`
   - 清除本地存儲的嘗試記錄

### 重置機制

#### 自動重置 (新增功能)

1. **時間基礎重置**:
   - 距離上次失敗嘗試超過 24 小時後，自動重置嘗試次數
   - 在以下時機檢查並執行重置：
     - 應用初始化時
     - 增加登入嘗試次數前
     - 訪問 `remainingAttempts` 時

2. **檢查邏輯**:
   ```dart
   Future<void> _checkAndResetAttemptsIfExpired() async {
     if (_lastFailedAttempt == null) return;
     
     final now = DateTime.now();
     final timeSinceLastAttempt = now.difference(_lastFailedAttempt!);
     
     if (timeSinceLastAttempt.inHours >= attemptResetHours) {
       await _resetLoginAttempts();
     }
   }
   ```

#### 手動重置

1. **管理員功能**:
   - `resetLoginAttempts()`: 手動重置登入嘗試次數
   - `unlockAccount(email)`: 手動解鎖特定帳戶

### 鎖定機制

1. **觸發條件**:
   - 連續失敗 5 次登入嘗試
   - 達到速率限制 (每分鐘 3 次)

2. **鎖定時間**:
   - 15 分鐘後自動解鎖
   - 可手動解鎖

3. **鎖定期間**:
   - 無法進行登入嘗試
   - 顯示倒數計時器

### 用戶界面顯示

#### 登入嘗試次數顯示

- 顯示已使用次數: `已使用次數/最大次數`
- 進度條顯示使用比例
- 顏色變化: 橙色 (低風險) → 紅色 (高風險)

#### 重置時間提示 (新增功能)

- 顯示距離下次自動重置的剩餘時間
- 格式: "X小時Y分鐘後重置" 或 "X分鐘後重置"
- 當可重置時顯示: "已可重置"

### 安全特性

1. **防止暴力破解**:
   - 限制嘗試次數
   - 時間基礎重置
   - 速率限制

2. **用戶體驗**:
   - 清晰的視覺反饋
   - 重置時間提示
   - 自動恢復機制

3. **數據持久化**:
   - 使用 SharedPreferences 保存狀態
   - 應用重啟後保持安全狀態

## 使用範例

### 檢查剩餘嘗試次數

```dart
final authProvider = context.read<AuthProvider>();
final remaining = authProvider.remainingAttempts;
final nextReset = authProvider.getNextAttemptResetTime();
```

### 手動重置 (管理員)

```dart
await authProvider.resetLoginAttempts();
```

### 獲取重置時間

```dart
final timeUntilReset = authProvider.getTimeUntilAttemptReset();
```

## 配置選項

可在 `AuthProvider` 中調整以下常數:

```dart
static const int maxLoginAttempts = 5;           // 最大嘗試次數
static const int lockoutDurationMinutes = 15;    // 鎖定時間 (分鐘)
static const int maxAttemptsPerMinute = 3;       // 每分鐘最大嘗試次數
static const int attemptResetHours = 24;         // 重置時間 (小時)
```

## 注意事項

1. **時間同步**: 重置機制依賴本地時間，確保設備時間準確
2. **數據清理**: 應用會自動清理過期的嘗試記錄
3. **性能考量**: 重置檢查是非同步進行，不會阻塞 UI
4. **安全考量**: 重置時間不宜過短，建議至少 24 小時

## 更新日誌

- **v1.1**: 添加時間基礎的自動重置機制
- **v1.0**: 基本登入嘗試次數限制和鎖定機制
