# OAuth 登入設定指南

本指南將幫助你配置 Google、Facebook 和 LINE 的 OAuth 登入功能。

## 1. Google 登入設定

### 1.1 創建 Google Cloud 專案

1. 前往 [Google Cloud Console](https://console.cloud.google.com/)
2. 創建新專案或選擇現有專案
3. 啟用 Google+ API

### 1.2 配置 OAuth 2.0

1. 前往「憑證」頁面
2. 點擊「建立憑證」→「OAuth 2.0 用戶端 ID」
3. 選擇應用程式類型：
   - **Android**: 需要 SHA-1 指紋
   - **iOS**: 需要 Bundle ID
   - **Web**: 用於測試

### 1.3 獲取 SHA-1 指紋 (Android)

```bash
# 調試版本
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# 發布版本
keytool -list -v -keystore your-release-key.keystore -alias your-key-alias
```

### 1.4 Android 配置

在 `android/app/build.gradle` 中添加：

```gradle
android {
    defaultConfig {
        // 添加你的 SHA-1 指紋
        manifestPlaceholders = [
            'googleMapsApiKey': 'YOUR_GOOGLE_MAPS_API_KEY'
        ]
    }
}
```

### 1.5 iOS 配置

在 `ios/Runner/Info.plist` 中添加：

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>REVERSED_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

## 2. Facebook 登入設定

### 2.1 創建 Facebook 應用

1. 前往 [Facebook Developers](https://developers.facebook.com/)
2. 創建新應用
3. 選擇「消費者」類型
4. 添加「Facebook 登入」產品

### 2.2 配置應用設定

1. 在「Facebook 登入」→「設定」中：
   - 添加有效的 OAuth 重新導向 URI
   - 配置應用網域

2. 在「基本」設定中：
   - 添加應用圖示
   - 設定隱私政策 URL
   - 設定服務條款 URL

### 2.3 Android 配置

在 `android/app/src/main/res/values/strings.xml` 中添加：

```xml
<string name="facebook_app_id">YOUR_FACEBOOK_APP_ID</string>
<string name="fb_login_protocol_scheme">fbYOUR_FACEBOOK_APP_ID</string>
```

在 `android/app/src/main/AndroidManifest.xml` 中添加：

```xml
<meta-data android:name="com.facebook.sdk.ApplicationId" android:value="@string/facebook_app_id"/>
<meta-data android:name="com.facebook.sdk.ClientToken" android:value="@string/fb_login_protocol_scheme"/>

<activity android:name="com.facebook.FacebookActivity"
    android:configChanges="keyboard|keyboardHidden|screenLayout|screenSize|orientation"
    android:label="@string/app_name" />

<activity
    android:name="com.facebook.CustomTabActivity"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="@string/fb_login_protocol_scheme" />
    </intent-filter>
</activity>
```

### 2.4 iOS 配置

在 `ios/Runner/Info.plist` 中添加：

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>facebook</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>fbYOUR_FACEBOOK_APP_ID</string>
        </array>
    </dict>
</array>

<key>FacebookAppID</key>
<string>YOUR_FACEBOOK_APP_ID</string>
<key>FacebookClientToken</key>
<string>YOUR_FACEBOOK_CLIENT_TOKEN</string>
<key>FacebookDisplayName</key>
<string>YOUR_APP_NAME</string>
```

## 3. LINE 登入設定

### 3.1 創建 LINE 應用

1. 前往 [LINE Developers Console](https://developers.line.biz/)
2. 創建新 Provider
3. 創建新 Channel
4. 選擇「LINE Login」產品

### 3.2 配置 Channel 設定

1. 在「LINE Login」設定中：
   - 添加 Callback URL
   - 設定 OpenID Connect
   - 配置權限範圍

2. 獲取 Channel ID 和 Channel Secret

### 3.3 實現 LINE 登入

由於 LINE 登入需要複雜的回調處理，建議使用以下方案：

1. **WebView 方案**: 使用 `webview_flutter` 套件
2. **外部瀏覽器方案**: 使用 `url_launcher` 套件
3. **原生 SDK 方案**: 使用 LINE 官方 SDK

### 3.4 回調處理

LINE 登入需要處理回調 URL，建議實現：

```dart
// 在 main.dart 中處理深度連結
void main() {
  runApp(MyApp());
  
  // 監聽深度連結
  FirebaseDynamicLinks.instance.onLink.listen((dynamicLink) {
    // 處理 LINE 登入回調
  });
}
```

## 4. 環境變數配置

### 4.1 創建環境變數文件

創建 `lib/config/oauth_config.dart`：

```dart
class OAuthConfig {
  // Google
  static const String googleClientId = 'YOUR_GOOGLE_CLIENT_ID';
  static const String googleClientSecret = 'YOUR_GOOGLE_CLIENT_SECRET';
  
  // Facebook
  static const String facebookAppId = 'YOUR_FACEBOOK_APP_ID';
  static const String facebookClientToken = 'YOUR_FACEBOOK_CLIENT_TOKEN';
  
  // LINE
  static const String lineChannelId = 'YOUR_LINE_CHANNEL_ID';
  static const String lineChannelSecret = 'YOUR_LINE_CHANNEL_SECRET';
  static const String lineRedirectUri = 'YOUR_LINE_REDIRECT_URI';
}
```

### 4.2 安全注意事項

1. **不要將敏感資訊提交到版本控制**
2. **使用環境變數或安全存儲**
3. **在生產環境中使用不同的憑證**
4. **定期輪換 API 金鑰**

## 5. 測試

### 5.1 測試環境

1. **開發環境**: 使用測試憑證
2. **預發布環境**: 使用預發布憑證
3. **生產環境**: 使用正式憑證

### 5.2 測試檢查清單

- [ ] Google 登入功能正常
- [ ] Facebook 登入功能正常
- [ ] LINE 登入功能正常
- [ ] 登出功能正常
- [ ] 錯誤處理正常
- [ ] 網路異常處理正常

## 6. 常見問題

### 6.1 Google 登入問題

**問題**: `SignInException: Status{statusCode=DEVELOPER_ERROR, resolution=null}`

**解決方案**: 檢查 SHA-1 指紋是否正確配置

### 6.2 Facebook 登入問題

**問題**: `FacebookException: Log in attempt failed`

**解決方案**: 檢查 App ID 和 Client Token 是否正確

### 6.3 LINE 登入問題

**問題**: 回調處理失敗

**解決方案**: 確保 Callback URL 配置正確

## 7. 部署注意事項

### 7.1 Android 部署

1. 生成發布版本的 SHA-1 指紋
2. 在 Google Console 中添加發布版本 SHA-1
3. 更新 Facebook 應用設定

### 7.2 iOS 部署

1. 配置正確的 Bundle ID
2. 更新 Facebook 應用設定
3. 配置正確的 URL Schemes

## 8. 監控和分析

### 8.1 登入統計

- 追蹤各 OAuth 提供商的使用情況
- 監控登入成功率
- 分析用戶偏好

### 8.2 錯誤監控

- 使用 Firebase Crashlytics 監控崩潰
- 記錄 OAuth 登入錯誤
- 設置錯誤警報

## 9. 維護

### 9.1 定期檢查

- 檢查 API 金鑰是否過期
- 更新 OAuth 套件版本
- 檢查安全漏洞

### 9.2 備份和恢復

- 備份 OAuth 配置
- 準備應急登入方案
- 測試恢復流程

---

**注意**: 本指南僅供參考，實際配置可能因平台版本和套件更新而有所變化。請參考官方文檔獲取最新資訊。
