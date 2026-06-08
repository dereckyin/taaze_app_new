# Android 上架指南（Google Play）

本文件整理「讀冊新生活」Android 版上架 Play Store 的完整步驟。

---

## 現況摘要

| 項目 | 狀態 |
|------|------|
| Application ID | `tw.taaze.bookstore` |
| 版本 | `1.0.0+1`（`pubspec.yaml`） |
| App 名稱 | 讀冊新生活 |
| Release AAB 建置 | ✅ 已可成功 `flutter build appbundle --release` |
| Release 簽章 | ⚠️ 需執行 keystore 腳本（見下方） |
| `google-services.json` | ✅ 本機已有（gitignore，勿提交） |
| Firebase Dart 設定 | ⚠️ `firebase_options.dart` 仍為 placeholder，推播需用 FlutterFire CLI 重新產生 |
| OAuth Google 登入 | ⚠️ 需把 **release SHA-1** 加到 Google Cloud Console |

---

## 第一步：建立 Upload Keystore（必做）

Play Console **不接受** debug 簽章。請在專案根目錄執行：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/generate_android_upload_keystore.ps1
```

腳本會建立：

- `android/app/upload-keystore.jks`（已 gitignore）
- `android/key.properties`（已 gitignore）

**請把 keystore 密碼備份到安全位置。** 遺失後無法用同一 upload key 更新 App。

參考範本：`android/key.properties.example`

---

## 第二步：建置正式 AAB

```powershell
cd c:\Users\dereckyin\Desktop\my_app
flutter pub get
flutter build appbundle --release
```

產出檔案：

```
build/app/outputs/bundle/release/app-release.aab
```

上傳到 Play Console → **Release → Production → Create new release → Upload**。

---

## 第三步：Google Play Console 設定

1. 建立 [Google Play 開發者帳號](https://play.google.com/console)（一次性 USD $25）
2. **建立應用程式** → 選擇「應用程式」
3. 填寫商店資訊：
   - 應用程式名稱：讀冊新生活
   - 簡短／完整說明
   - 螢幕截圖（手機至少 2 張，建議 1080×1920 或更高）
   - 功能圖片 1024×500
   - 應用程式圖示 512×512
4. **隱私權政策 URL**（必填，需可公開存取）
5. **內容分級問卷**
6. **資料安全表單**（說明收集的帳號、相機、通知等資料）
7. **目標對象與內容**（是否面向兒童等）

建議啟用 **Google Play App Signing**：Google 代管 app signing key，你只需保管 upload key。

---

## 第四步：OAuth / 第三方登入設定

### Google 登入

在 [Google Cloud Console](https://console.cloud.google.com/) → 憑證 → Android OAuth 用戶端：

- Package name：`tw.taaze.bookstore`
- SHA-1：**release keystore** 的 SHA-1（執行 keystore 腳本時會顯示）

目前 debug SHA-1（僅供本機測試）：

```
SHA1: 11:87:C7:C9:4E:F2:00:04:5E:33:6E:4D:6F:88:F5:6B:F0:8E:E6:24
```

**Release upload keystore SHA-1**（請加到 Google Cloud OAuth 正式 Android 用戶端）：

```
SHA1: 5D:75:51:A6:91:4C:5D:55:AC:52:7B:0F:33:5C:0B:A4:B0:0E:7D:A1
SHA256: 3D:EF:0C:0E:9C:E5:53:E9:C3:9D:D3:68:41:9E:E3:66:E3:F5:81:87:34:FF:04:E3:F6:0C:02:A2:2E:CC:C9:07
```

### Facebook 登入

在 [Facebook Developers](https://developers.facebook.com/) → 你的 App → 設定：

- Android 套件名稱：`tw.taaze.bookstore`
- 新增 **Release Key Hash**（可用 keytool 取得，或 Facebook SDK 除錯工具）

Facebook 設定已在 `android/app/src/main/res/values/strings.xml`。

---

## 第五步：Firebase 推播（選用但建議）

1. 確認 `android/app/google-services.json` 來自正式 Firebase 專案
2. 重新產生 Dart 設定（取代 placeholder）：

```powershell
dart pub global activate flutterfire_cli
flutterfire configure
```

3. 更新 `lib/main.dart` 使用：

```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

4. Release 建置時 Gradle 會自動套用 `google-services` plugin

---

## 第六步：版本更新規則

每次上架新版本，修改 `pubspec.yaml`：

```yaml
version: 1.0.1+2   # 1.0.1 = versionName, 2 = versionCode
```

- `versionCode`（+ 後面的數字）**必須遞增**，Play Console 才接受上傳
- 修改後重新 `flutter build appbundle --release`

---

## 常用指令

```powershell
# 查看 release keystore SHA-1
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" `
  -list -v -keystore android\app\upload-keystore.jks -alias upload

# 本機 release 測試（需連接實機）
flutter install --release

# 檢查 Android 環境
flutter doctor -v
```

---

## 已知限制 / 待辦

- [x] 建立 upload keystore（`android/app/upload-keystore.jks` + `android/key.properties`）
- [x] 使用 Play Console 已登記的上傳金鑰（`android/releasebuild.jks`，alias: `key0`）
- [ ] **備份 keystore 密碼**（`releasebuild.jks` 與 `key.properties`，勿提交 Git）
- [ ] 將 release SHA-1 加入 Google Cloud OAuth
- [ ] 更新 Facebook release key hash
- [ ] 用 FlutterFire CLI 更新 `firebase_options.dart`
- [ ] 準備 Play Store 文案、截圖、隱私權政策
- [ ] 完成 Play Console 資料安全與內容分級

---

## 相關文件

- `OAUTH_SETUP_GUIDE.md` — OAuth 詳細設定
- `DEVELOPER_GUIDE.md` — 本地通知與建置
- `API_INTEGRATION_GUIDE.md` — API 與 `--dart-define` 建置參數

---

**注意**：`android/app/upload-keystore.jks`、`android/key.properties`、`google-services.json` 均不應提交到 Git。
