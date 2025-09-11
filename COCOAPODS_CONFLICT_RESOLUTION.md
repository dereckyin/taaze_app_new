# CocoaPods 依賴衝突解決方案

## 問題描述

在添加 OAuth 登入功能時，遇到了 CocoaPods 依賴版本衝突的問題：

```
[!] CocoaPods could not find compatible versions for pod "GTMSessionFetcher/Core":
  In snapshot (Podfile.lock):
    GTMSessionFetcher/Core (< 3.0, = 2.3.0, >= 1.1)

  In Podfile:
    google_sign_in_ios (from `.symlinks/plugins/google_sign_in_ios/darwin`) was resolved to 0.0.1, which depends on
      GoogleSignIn (~> 8.0) was resolved to 8.0.0, which depends on
        GTMSessionFetcher/Core (~> 3.3)
```

## 衝突原因

1. **Google Sign-In 套件更新**：新版本的 `google_sign_in` 需要更新的 Google 依賴
2. **Mobile Scanner 衝突**：`mobile_scanner` 套件與 `google_sign_in` 存在依賴衝突
3. **版本鎖定**：現有的 `Podfile.lock` 鎖定了舊版本

## 解決方案

### 方案 1：暫時移除衝突套件（推薦）

1. **註解 mobile_scanner**：
   ```yaml
   # pubspec.yaml
   dependencies:
     # mobile_scanner: ^4.0.0  # 暫時註解以避免與 google_sign_in 衝突
   ```

2. **清理並重新安裝**：
   ```bash
   flutter clean
   flutter pub get
   cd ios
   pod install
   ```

### 方案 2：強制更新依賴

1. **刪除鎖定文件**：
   ```bash
   cd ios
   rm -rf Pods Podfile.lock
   ```

2. **更新 CocoaPods 倉庫**：
   ```bash
   pod repo update
   pod install
   ```

### 方案 3：使用版本覆蓋

在 `ios/Podfile` 中添加版本覆蓋：

```ruby
target 'Runner' do
  use_frameworks! :linkage => :static

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  
  # 強制使用特定版本
  pod 'GTMSessionFetcher', '~> 3.5'
  pod 'GoogleUtilities', '~> 8.1'
end
```

## 已實施的解決方案

我們採用了**方案 1**，暫時註解了 `mobile_scanner` 套件：

### 修改的文件

1. **pubspec.yaml**：
   ```yaml
   # Camera and barcode scanning
   camera: ^0.11.0+2
   # mobile_scanner: ^4.0.0  # 暫時註解以避免與 google_sign_in 衝突
   image_picker: ^1.1.2
   ```

2. **ios/Podfile**：
   - 添加了依賴衝突修復
   - 設置了正確的 iOS 部署目標

### 安裝結果

```
Pod installation complete! There are 11 dependencies from the Podfile and 22 total pods installed.
```

成功安裝的 OAuth 相關套件：
- ✅ AppAuth (1.7.6)
- ✅ GoogleSignIn (8.0.0)
- ✅ GTMSessionFetcher (3.5.0)
- ✅ GoogleUtilities (8.1.0)
- ✅ FBSDKCoreKit (17.0.3)
- ✅ FBSDKLoginKit (17.0.3)

## 後續步驟

### 1. 測試 OAuth 功能

```bash
flutter run
```

### 2. 重新啟用 Mobile Scanner（可選）

如果需要條碼掃描功能，可以嘗試：

1. **更新 mobile_scanner 版本**：
   ```yaml
   mobile_scanner: ^5.0.0  # 使用更新版本
   ```

2. **或者使用替代方案**：
   ```yaml
   qr_code_scanner: ^1.0.1  # 替代條碼掃描套件
   ```

### 3. 配置 OAuth 提供商

參考 `OAUTH_SETUP_GUIDE.md` 配置：
- Google Cloud Console
- Facebook Developers
- LINE Developers

## 預防措施

### 1. 依賴管理最佳實踐

- 定期更新套件版本
- 使用 `flutter pub outdated` 檢查過期套件
- 避免鎖定過舊的版本

### 2. 版本兼容性檢查

在添加新套件前：
```bash
flutter pub deps
```

### 3. 分階段更新

- 先更新核心套件
- 再添加新功能套件
- 測試每個階段的兼容性

## 常見問題

### Q: 為什麼會出現依賴衝突？

A: Flutter 套件依賴原生 iOS/Android 套件，當多個套件需要不同版本的同一個原生套件時就會發生衝突。

### Q: 如何避免未來出現類似問題？

A: 
1. 使用 `flutter pub deps` 檢查依賴樹
2. 定期更新套件到最新版本
3. 避免使用過舊的套件版本

### Q: 可以同時使用多個 Google 套件嗎？

A: 可以，但需要確保版本兼容。建議使用 Google 官方套件組合。

## 參考資源

- [CocoaPods 官方文檔](https://guides.cocoapods.org/)
- [Flutter 依賴管理](https://flutter.dev/docs/development/packages-and-plugins/using-packages)
- [Google Sign-In Flutter 插件](https://pub.dev/packages/google_sign_in)
- [Facebook Auth Flutter 插件](https://pub.dev/packages/flutter_facebook_auth)

---

**注意**：這個解決方案是暫時的。在生產環境中，建議找到兼容的套件版本組合，或者使用替代的條碼掃描解決方案。
