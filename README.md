# 專業網路書店 Flutter 應用程式

這是一個專業的網路書店 Flutter 應用程式，具備完整的購物功能和現代化的 UI/UX 設計。

## ✨ 主要功能

### 📱 核心功能
- **商品展示**：首頁橫幅、精選書籍、最新書籍、分類導航
- **搜尋功能**：智能搜尋書籍，支援書名、作者、關鍵字搜尋
- **購物車**：添加商品、數量調整、結帳流程
- **會員系統**：用戶註冊、登入、個人資料管理
- **通知中心**：推播通知、消息管理

### 🎨 設計特色
- **桃紅色主色調**：溫暖舒適的視覺體驗
- **Material Design 3**：現代化界面設計
- **響應式設計**：適配不同螢幕尺寸
- **流暢動畫**：優雅的過渡效果

### 📚 商品分類
- 程式設計
- 設計
- 人工智慧
- 資料庫
- 網路安全
- 雲端運算
- 區塊鏈

## 🚀 快速開始

> 開發者請優先閱讀：`DEVELOPER_GUIDE.md`（整合通知、建置與常見問題）

### 環境要求
- Flutter SDK 3.9.0 或更高版本
- Dart SDK
- iOS 模擬器或 Android 模擬器（可選）

### 安裝步驟

1. **克隆專案**
   ```bash
   git clone <repository-url>
   cd my_app
   ```

2. **安裝依賴**
   ```bash
   flutter pub get
   ```

3. **運行應用程式**
   ```bash
   # 在 Web 瀏覽器中運行
   flutter run -d chrome
   
   # 在 iOS 模擬器中運行
   flutter run -d ios
   
   # 在 Android 模擬器中運行
   flutter run -d android
   ```

### 建置版本

```bash
# 建置 Web 版本
flutter build web

# 建置 iOS 版本（需要 Apple Developer 帳號）
flutter build ios

# 建置 Android 版本
flutter build apk
```

## 🏗️ 專案結構

```
lib/
├── models/          # 資料模型
│   ├── book.dart
│   ├── user.dart
│   ├── cart_item.dart
│   └── notification.dart
├── providers/       # 狀態管理
│   ├── auth_provider.dart
│   ├── book_provider.dart
│   ├── cart_provider.dart
│   └── notification_provider.dart
├── screens/         # 頁面
│   ├── main_screen.dart
│   ├── home_screen.dart
│   ├── book_detail_screen.dart
│   ├── search_screen.dart
│   ├── cart_screen.dart
│   ├── checkout_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── profile_screen.dart
│   └── notifications_screen.dart
├── widgets/         # UI 組件
│   ├── book_card.dart
│   ├── custom_app_bar.dart
│   └── loading_widget.dart
├── theme/           # 主題配置
│   └── app_theme.dart
└── main.dart        # 應用程式入口
```

## 🛠️ 技術架構

- **狀態管理**：Provider
- **HTTP 請求**：http package
- **本地儲存**：shared_preferences
- **圖片快取**：cached_network_image
- **推送通知**：firebase_messaging
- **UI 組件**：flutter_staggered_grid_view, shimmer
- **圖標**：font_awesome_flutter

## 📱 使用說明

1. **瀏覽商品**：在首頁查看精選書籍和最新書籍
2. **搜尋書籍**：使用搜尋功能找到想要的書籍
3. **查看詳情**：點擊書籍查看詳細資訊和評論
4. **加入購物車**：將喜歡的書籍加入購物車
5. **結帳購買**：填寫收貨資訊完成購買
6. **會員功能**：註冊登入享受更多功能

## 🔧 開發說明

### 添加新功能
1. 在 `models/` 中定義資料模型
2. 在 `providers/` 中實現狀態管理
3. 在 `screens/` 中創建頁面
4. 在 `widgets/` 中創建可重用組件

### 自定義主題
修改 `lib/theme/app_theme.dart` 文件來自定義應用程式主題。

## 📄 授權

此專案僅供學習和演示使用。

## 🤝 貢獻

歡迎提交 Issue 和 Pull Request 來改進此專案。

---

**注意**：此應用程式使用模擬資料進行演示，實際部署時需要連接真實的後端 API。
