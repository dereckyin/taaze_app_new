# 開發者整合指南

本指南整合常用的開發作業：本地通知設定、iOS/Android 測試、常見問題排查，以及後續要啟用 Firebase 推播的步驟連結。

---

## 目錄
- 本地通知（必備）
  - iOS 設定
  - Android 設定
  - 測試方法
  - 常見問題排查
- Firebase 推播（選用，未預設啟用）
- 建置與執行指令

---

## 本地通知（必備）

### iOS 設定
1) AppDelegate delegate（前景顯示通知）
- 已完成：在 `ios/Runner/AppDelegate.swift` 設定
  - `UNUserNotificationCenter.current().delegate = self`
  - 並覆寫前景顯示與點擊回呼（顯示 alert/badge/sound）

2) 通知初始化時機
- 已完成：在 `lib/main.dart` 的 `main()` 中，於 `runApp()` 前呼叫：
  - `await LocalNotificationService.instance.initialize();`
- 目的：第一次啟動時即能正確請求權限與設定前景展示行為

3) 權限與前景展示行為
- 已完成：`LocalNotificationService` 使用 `DarwinInitializationSettings` 並請求 `alert/badge/sound`
- 目前專案的 `flutter_local_notifications` 版本為 17.x，iOS API 使用 `IOSFlutterLocalNotificationsPlugin`
  - 若未來升級到 19.x，請改為 `DarwinFlutterLocalNotificationsPlugin` 並調整對應參數

4) Entitlements 與背景能力
- 已完成：`ios/Runner/Runner.entitlements` 內含 `aps-environment=development`
- `Info.plist` 已具備 `UIBackgroundModes -> remote-notification`（如需 FCM 背景處理）

### Android 設定
1) 權限
- 已完成：`android.permission.POST_NOTIFICATIONS`（Android 13+）
- 其他既有權限：`INTERNET` 等

2) 啟用通知渠道與初始化
- 已完成：`LocalNotificationService` 於啟動時請求 Android 13+ 通知權限
- `AndroidManifest.xml` 已設預設 channel id `default_channel`

### 測試方法
- 進入主畫面右下角「鈴鐺」按鈕：會觸發本地通知
- iOS
  - 首次啟動允許通知後，前景應顯示 Banner/Alert；切到背景則進通知中心
- Android
  - Android 13+ 要在系統層級允許通知；前景可能顯示 Heads-up，背景進通知欄

### 常見問題排查（iOS）
- 第一次啟動時「允許通知」是否按了允許？
- `AppDelegate.swift` 是否有 `UNUserNotificationCenter.current().delegate = self`？
- 初始化是否在 `runApp()` 之前執行？（目前已是）
- iOS 設定 > App > 通知 是否已開啟？
- 模擬器若異常，重開模擬器或刪 App 重裝再允許通知
- 使用的 API 是否與套件版本相符（17.x 用 `IOSFlutterLocalNotificationsPlugin`）

---

## Firebase 推播（選用）
專案目前預設「未啟用」Firebase 推播，若需要啟用，請依以下概要與詳細文件操作：

1) 準備檔案
- 從 Firebase Console 下載 `GoogleService-Info.plist`，放至 `ios/Runner/`
- 確認 `lib/firebase_options.dart` 為真實專案設定

2) 程式初始化
- 在 `main.dart` 解除註解：
  - `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);`
- 在通知初始化流程中再呼叫 `NotificationService.instance.initialize(...)`（已留好呼叫點，預設關閉）

3) 參考文件
- 詳細步驟見：`FIREBASE_SETUP.md`
- 後端規格見：`NOTIFICATIONS_BACKEND_SPEC.md`

---

## 建置與執行

### iOS（模擬器）
```bash
flutter build ios --simulator
flutter run -d ios
```

### Android（APK）
```bash
flutter build apk --debug
flutter run -d android
```

---

## 變更索引（本次已完成）
- iOS：
  - 設定 `UNUserNotificationCenter` delegate（前景顯示）
  - 修正 Swift delegate override，移除冗餘協定宣告
  - 在 `main()` 前置初始化本地通知
  - 新增 `Runner.entitlements`、留置 `GoogleService-Info.plist` 位置
- Android：
  - `POST_NOTIFICATIONS` 權限、預設通知 channel id
- Flutter：
  - `LocalNotificationService` 加強權限請求與除錯輸出
  - 與 17.x 版套件 API 對齊（iOS 使用 `IOSFlutterLocalNotificationsPlugin`）
