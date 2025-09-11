# 權限設置說明

## iOS 權限設置

### Info.plist 權限描述
已在 `ios/Runner/Info.plist` 中添加以下權限：

```xml
<key>NSCameraUsageDescription</key>
<string>此應用需要訪問相機來掃描書籍條碼和拍照上傳到AI助手</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>此應用需要訪問相簿來選擇圖片上傳到AI助手</string>

<key>NSMicrophoneUsageDescription</key>
<string>此應用需要訪問麥克風來錄製音頻（可選功能）</string>
```

### 權限說明
- **NSCameraUsageDescription**: 相機權限，用於條碼掃描和拍照
- **NSPhotoLibraryUsageDescription**: 相簿權限，用於選擇圖片上傳
- **NSMicrophoneUsageDescription**: 麥克風權限，為未來音頻功能預留

## Android 權限設置

### AndroidManifest.xml 權限
已在 `android/app/src/main/AndroidManifest.xml` 中添加以下權限：

```xml
<!-- 相機權限 -->
<uses-permission android:name="android.permission.CAMERA" />
<!-- 相簿權限 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<!-- 網路權限 -->
<uses-permission android:name="android.permission.INTERNET" />
```

### 權限說明
- **CAMERA**: 相機權限，用於條碼掃描和拍照
- **READ_EXTERNAL_STORAGE**: 讀取外部存儲權限，用於選擇圖片
- **WRITE_EXTERNAL_STORAGE**: 寫入外部存儲權限，用於保存圖片
- **INTERNET**: 網路權限，用於API調用

## 測試步驟

### iOS 測試
1. 運行 `flutter run -d "iPhone 16 Plus"`
2. 點擊首頁的"掃描條碼"按鈕
3. 系統會彈出權限請求對話框
4. 點擊"允許"授予相機權限
5. 測試條碼掃描功能

### Android 測試
1. 運行 `flutter run -d android`
2. 點擊首頁的"掃描條碼"按鈕
3. 系統會彈出權限請求對話框
4. 點擊"允許"授予相機權限
5. 測試條碼掃描功能

## 權限請求流程

### 首次使用
1. 用戶點擊掃描按鈕
2. 系統檢查權限狀態
3. 如果未授予權限，彈出權限請求對話框
4. 用戶選擇允許或拒絕
5. 根據選擇結果執行相應操作

### 權限被拒絕
- 顯示友好的錯誤提示
- 引導用戶到設置頁面手動開啟權限
- 提供重試機制

## 注意事項

### iOS
- 權限描述必須用中文，符合App Store審核要求
- 描述要清楚說明使用目的
- 避免使用過於技術性的術語

### Android
- Android 6.0+ 需要動態權限請求
- 權限在AndroidManifest.xml中聲明
- 運行時權限由Flutter插件自動處理

## 故障排除

### 權限被拒絕
1. 檢查Info.plist/AndroidManifest.xml設置
2. 重新安裝app
3. 手動在設置中開啟權限
4. 檢查設備是否支持相機功能

### 權限描述不顯示
1. 確認Info.plist文件格式正確
2. 重新構建app
3. 檢查權限key是否正確

### 相機無法啟動
1. 確認設備有相機硬件
2. 檢查其他app是否正在使用相機
3. 重啟設備
4. 檢查相機硬件是否正常

