# Firebase 設置指南

## 問題解決方案

### 當前狀態
- ✅ 相機功能完全可用（條碼掃描 + AI照片上傳）
- ✅ iOS構建成功
- ⚠️ Firebase暫時禁用以避免模組化衝突

### Firebase 重新啟用步驟

#### 1. 恢復Firebase依賴
在 `pubspec.yaml` 中取消註釋：
```yaml
# Push notifications
firebase_messaging: ^14.7.10
firebase_core: ^2.24.2
```

#### 2. 使用兼容的Firebase版本
如果遇到模組化問題，可以嘗試更舊的版本：
```yaml
firebase_messaging: ^13.0.0
firebase_core: ^2.10.0
```

#### 3. 修改Podfile（已配置）
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    target.build_configurations.each do |config|
      # 模組化頭文件修復
      config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
      config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'NO'
      
      # Firebase特定修復
      if target.name.include?('firebase') || target.name.include?('Firebase')
        config.build_settings['DEFINES_MODULE'] = 'NO'
        config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
      end
      
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end
```

#### 4. 重新安裝依賴
```bash
flutter clean
flutter pub get
cd ios && pod install
```

#### 5. 配置Firebase項目
1. 在Firebase Console創建項目
2. 添加iOS應用
3. 下載 `GoogleService-Info.plist`
4. 將文件放入 `ios/Runner/` 目錄

### 替代方案

#### 方案A：使用更舊的Firebase版本
```yaml
firebase_messaging: ^12.0.0
firebase_core: ^1.24.0
```

#### 方案B：使用其他推送服務
- OneSignal
- Pusher
- 自定義推送服務

#### 方案C：暫時不使用推送通知
- 專注於相機功能
- 使用應用內通知
- 後續再添加推送功能

### 當前功能狀態

#### ✅ 完全可用
- 條碼掃描功能
- AI照片上傳功能
- 書籍瀏覽和搜尋
- 購物車功能
- 用戶認證
- 所有UI功能

#### ⚠️ 需要配置
- Firebase推送通知（可選）

### 建議
1. **優先測試相機功能**：當前版本已完全可用
2. **後續添加Firebase**：當需要推送通知時再配置
3. **使用穩定版本**：避免使用最新版本以避免兼容性問題
