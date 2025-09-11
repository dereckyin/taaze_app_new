# OAuth 登入功能測試指南

## 概述

本指南將幫助你測試已實現的 OAuth 登入功能，包括 Google、Facebook 和 LINE 登入。

## 測試前準備

### 1. 確認環境

```bash
# 檢查 Flutter 環境
flutter doctor

# 確認依賴已安裝
flutter pub get

# 確認 iOS CocoaPods 已安裝
cd ios && pod install
```

### 2. 配置檢查

在 `lib/config/oauth_config.dart` 中確認配置：

```dart
// 檢查配置狀態
print('Google 配置狀態: ${OAuthConfig.isGoogleConfigured()}');
print('Facebook 配置狀態: ${OAuthConfig.isFacebookConfigured()}');
print('LINE 配置狀態: ${OAuthConfig.isLineConfigured()}');
print('已配置的提供商: ${OAuthConfig.getConfiguredProviders()}');
```

## 測試步驟

### 1. 基本功能測試

#### 1.1 啟動應用

```bash
# iOS 模擬器
flutter run -d ios

# Android 模擬器
flutter run -d android

# Web 瀏覽器
flutter run -d chrome
```

#### 1.2 檢查登入頁面

- [ ] 登入頁面正常顯示
- [ ] 傳統登入表單正常
- [ ] OAuth 按鈕正確顯示（根據配置）
- [ ] 分隔線和文字正確顯示

### 2. OAuth 按鈕顯示測試

#### 2.1 未配置狀態

當所有 OAuth 提供商都未配置時：
- [ ] 不顯示 OAuth 按鈕區域
- [ ] 不顯示分隔線

#### 2.2 部分配置狀態

配置部分提供商後：
- [ ] 只顯示已配置的按鈕
- [ ] 按鈕間距正確
- [ ] 按鈕樣式正確

### 3. Google 登入測試

#### 3.1 配置 Google 登入

1. 在 `lib/config/oauth_config.dart` 中設置：
   ```dart
   static const String googleClientId = 'YOUR_ACTUAL_GOOGLE_CLIENT_ID';
   ```

2. 在 Google Cloud Console 中配置：
   - 添加 iOS Bundle ID
   - 添加 Android SHA-1 指紋
   - 啟用 Google+ API

#### 3.2 測試流程

- [ ] 點擊 Google 登入按鈕
- [ ] 彈出 Google 登入頁面
- [ ] 輸入 Google 帳戶資訊
- [ ] 授權應用權限
- [ ] 登入成功，跳轉到主頁面
- [ ] 用戶資訊正確顯示

#### 3.3 錯誤處理測試

- [ ] 取消登入時顯示適當訊息
- [ ] 網路錯誤時顯示錯誤訊息
- [ ] 配置錯誤時顯示配置提示

### 4. Facebook 登入測試

#### 4.1 配置 Facebook 登入

1. 在 `lib/config/oauth_config.dart` 中設置：
   ```dart
   static const String facebookAppId = 'YOUR_ACTUAL_FACEBOOK_APP_ID';
   static const String facebookClientToken = 'YOUR_ACTUAL_FACEBOOK_CLIENT_TOKEN';
   ```

2. 在 Facebook Developers Console 中配置：
   - 添加 iOS Bundle ID
   - 添加 Android Package Name
   - 設置隱私政策 URL

#### 4.2 測試流程

- [ ] 點擊 Facebook 登入按鈕
- [ ] 彈出 Facebook 登入頁面
- [ ] 輸入 Facebook 帳戶資訊
- [ ] 授權應用權限
- [ ] 登入成功，跳轉到主頁面
- [ ] 用戶資訊正確顯示

### 5. LINE 登入測試

#### 5.1 配置 LINE 登入

1. 在 `lib/config/oauth_config.dart` 中設置：
   ```dart
   static const String lineChannelId = 'YOUR_ACTUAL_LINE_CHANNEL_ID';
   static const String lineChannelSecret = 'YOUR_ACTUAL_LINE_CHANNEL_SECRET';
   static const String lineRedirectUri = 'YOUR_ACTUAL_LINE_REDIRECT_URI';
   ```

2. 在 LINE Developers Console 中配置：
   - 設置 Callback URL
   - 配置權限範圍

#### 5.2 測試流程

- [ ] 點擊 LINE 登入按鈕
- [ ] 打開外部瀏覽器或 LINE 應用
- [ ] 完成 LINE 登入流程
- [ ] 處理回調 URL（需要額外實現）

### 6. 載入狀態測試

- [ ] 點擊 OAuth 按鈕後顯示載入狀態
- [ ] 載入期間按鈕不可點擊
- [ ] 載入完成後恢復正常狀態

### 7. 錯誤處理測試

#### 7.1 網路錯誤

- [ ] 斷網狀態下點擊 OAuth 按鈕
- [ ] 顯示網路錯誤訊息
- [ ] 錯誤訊息用戶友好

#### 7.2 配置錯誤

- [ ] 使用錯誤的 API 金鑰
- [ ] 顯示配置錯誤訊息
- [ ] 提供解決建議

#### 7.3 用戶取消

- [ ] 在 OAuth 流程中取消
- [ ] 顯示取消訊息
- [ ] 不影響應用狀態

### 8. 數據持久化測試

- [ ] OAuth 登入成功後數據正確保存
- [ ] 應用重啟後登入狀態保持
- [ ] 登出後數據正確清除

### 9. 跨平台測試

#### 9.1 iOS 測試

- [ ] 在 iOS 模擬器中測試
- [ ] 在真實 iOS 設備上測試
- [ ] 檢查 iOS 特定配置

#### 9.2 Android 測試

- [ ] 在 Android 模擬器中測試
- [ ] 在真實 Android 設備上測試
- [ ] 檢查 Android 特定配置

#### 9.3 Web 測試

- [ ] 在 Chrome 瀏覽器中測試
- [ ] 在 Safari 瀏覽器中測試
- [ ] 檢查 Web 特定行為

## 測試檢查清單

### 功能測試

- [ ] Google 登入功能正常
- [ ] Facebook 登入功能正常
- [ ] LINE 登入功能正常（如果配置）
- [ ] 傳統登入功能正常
- [ ] 登出功能正常

### 用戶體驗測試

- [ ] 按鈕樣式美觀
- [ ] 載入狀態清晰
- [ ] 錯誤訊息友好
- [ ] 操作流程順暢

### 安全性測試

- [ ] API 金鑰安全存儲
- [ ] 用戶數據正確處理
- [ ] 登出後數據清除
- [ ] 錯誤不洩露敏感資訊

### 性能測試

- [ ] 登入響應時間合理
- [ ] 載入狀態不阻塞 UI
- [ ] 記憶體使用正常
- [ ] 電池消耗合理

## 常見問題和解決方案

### Q: OAuth 按鈕不顯示

**A**: 檢查配置是否正確：
```dart
print(OAuthConfig.getConfiguredProviders());
```

### Q: Google 登入失敗

**A**: 檢查以下項目：
1. SHA-1 指紋是否正確
2. Bundle ID 是否匹配
3. Google Cloud Console 配置

### Q: Facebook 登入失敗

**A**: 檢查以下項目：
1. App ID 和 Client Token
2. 隱私政策 URL 設置
3. Facebook 應用狀態

### Q: LINE 登入無法完成

**A**: LINE 登入需要額外的回調處理：
1. 實現深度連結處理
2. 配置 URL Scheme
3. 處理授權碼交換

## 測試報告模板

### 測試環境

- 設備：iPhone 14 Pro / Pixel 7
- 系統：iOS 17.0 / Android 14
- 應用版本：1.0.0
- 測試日期：2024-01-XX

### 測試結果

| 功能 | 狀態 | 備註 |
|------|------|------|
| Google 登入 | ✅ 通過 | 正常 |
| Facebook 登入 | ✅ 通過 | 正常 |
| LINE 登入 | ⚠️ 部分 | 需要回調處理 |
| 錯誤處理 | ✅ 通過 | 正常 |
| 載入狀態 | ✅ 通過 | 正常 |

### 發現的問題

1. **問題描述**：LINE 登入需要額外實現
2. **影響程度**：中等
3. **建議解決方案**：實現深度連結處理

### 建議改進

1. 添加更多 OAuth 提供商
2. 改進錯誤訊息
3. 添加登入統計功能

---

**注意**：在生產環境部署前，請確保所有 OAuth 提供商都已正確配置並通過測試。
