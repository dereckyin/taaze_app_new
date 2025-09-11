# 假資料模式說明

## 概述

目前app已設置為**假資料模式**，在API開發完成之前，所有資料都使用預設的模擬資料顯示。

## 假資料內容

### 書籍資料
- 總共12本模擬書籍
- 包含不同分類：程式設計、設計、人工智慧、資料庫、網路安全、雲端運算、區塊鏈
- 每本書都有完整的資訊：標題、作者、描述、價格、圖片、評分等

### 橫幅資料
- 總共6個模擬橫幅
- 包含不同類型：精選推薦、促銷活動、公告、新品上市、活動
- 每個橫幅都有完整的資訊：標題、副標題、描述、圖片、行動按鈕等
- 支持過期時間和顯示順序

### 四個板塊的假資料分類

#### 1. 今日特惠
- **篩選條件**: 價格 < 500元
- **首頁顯示**: 6本書籍
- **包含書籍**: Dart語言入門、資料庫設計、網路安全實務、UI設計原則、JavaScript進階

#### 2. 暢銷排行榜
- **篩選條件**: 評分 > 4.5
- **首頁顯示**: 6本書籍
- **包含書籍**: Flutter開發實戰、移動應用設計、人工智慧基礎、React Native開發指南、Python機器學習、雲端運算架構

#### 3. 注目新品
- **篩選條件**: 出版日期在最近30天內
- **首頁顯示**: 6本書籍
- **包含書籍**: 人工智慧基礎、資料庫設計、React Native開發指南、Python機器學習、雲端運算架構、區塊鏈技術

#### 4. 最新上架二手書
- **篩選條件**: 價格 < 300元
- **首頁顯示**: 6本書籍
- **包含書籍**: 網路安全實務、UI設計原則、JavaScript進階、區塊鏈技術

## 功能測試

### 首頁功能
1. **橫幅輪播區域**: 支持多個橫幅輪播顯示，包含不同類型的促銷和公告
2. **快速功能按鈕**: 四個圓形按鈕，直接跳轉到對應板塊
3. **分類導航**: 顯示所有書籍分類
4. **四個板塊**: 每個板塊顯示6本書籍，有"查看更多"按鈕

### 列表頁功能
1. **點擊"查看更多"**: 進入對應的完整列表頁
2. **分頁顯示**: 顯示該板塊的所有書籍
3. **書籍卡片**: 點擊可進入書籍詳情頁
4. **加入購物車**: 可以將書籍加入購物車

### Debug功能
1. **Debug按鈕**: 右下角紅色bug圖標（僅在debug模式顯示）
2. **狀態監控**: 查看各Provider的狀態（書籍、橫幅、用戶、購物車、通知）
3. **操作按鈕**: 重新載入、切換模式等
4. **日誌查看**: 查看所有操作的日誌

## 切換到真實API

當API開發完成後，需要進行以下修改：

### 1. 恢復API配置
在 `lib/providers/book_provider.dart` 中：
```dart
// 取消註解這些行
static const String _baseUrl = 'https://api.taaze.tw/api/v1';
static const String _booksEndpoint = '/api/books';
static const String _todayDealsEndpoint = '/api/books/today-deals';
static const String _bestsellersEndpoint = '/api/books/bestsellers';
static const String _newReleasesEndpoint = '/api/books/new-releases';
static const String _usedBooksEndpoint = '/api/books/used-books';
static const Duration _timeout = Duration(seconds: 10);
```

在 `lib/providers/banner_provider.dart` 中：
```dart
// 取消註解這些行
static const String _baseUrl = 'https://api.taaze.tw/api/v1';
static const String _bannersEndpoint = '/api/banners';
static const Duration _timeout = Duration(seconds: 10);
```

### 2. 恢復imports
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
```

### 3. 恢復API方法
取消註解 `_fetchBooksFromAPI` 和 `_bookFromJson` 方法（BookProvider）
取消註解 `_fetchBannersFromAPI` 方法（BannerProvider）

### 4. 修改載入邏輯
將 `_loadBooks` 方法改回調用真實API，而不是直接使用假資料
將 `_loadBanners` 方法改回調用真實API，而不是直接使用假資料

### 5. 更新API URL
將兩個Provider中的 `_baseUrl` 都改為實際的API地址

## 測試建議

### 手動測試流程
1. 啟動app: `flutter run -d chrome`
2. 檢查橫幅輪播是否正常顯示和切換
3. 檢查首頁四個板塊是否正常顯示
4. 點擊"查看更多"進入列表頁
5. 測試書籍詳情頁和購物車功能
6. 使用debug工具查看狀態和日誌

### 自動化測試
```bash
# 運行分析
flutter analyze

# 運行測試
flutter test
```

## 注意事項

1. **假資料模式**: 目前所有API調用都被跳過，直接使用假資料
2. **橫幅輪播**: 支持多個橫幅自動輪播，包含不同類型和樣式
3. **分頁功能**: 在假資料模式下，列表頁會一次性載入所有符合條件的書籍
4. **搜尋功能**: 搜尋會基於假資料進行本地篩選
5. **分類篩選**: 分類篩選會基於假資料進行本地篩選
6. **Debug日誌**: 所有操作都會記錄在debug控制台中

## 性能優化

在假資料模式下，app的性能表現：
- **載入速度**: 極快，因為不需要網路請求
- **記憶體使用**: 低，因為資料量小
- **用戶體驗**: 流暢，沒有載入延遲

當切換到真實API後，建議實施以下優化：
- 快取策略
- 分頁載入
- 圖片懶載入
- 錯誤重試機制
