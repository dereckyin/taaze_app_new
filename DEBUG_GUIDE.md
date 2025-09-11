# Flutter App Debug 指南

## 1. 基本Debug命令

### 運行和調試
```bash
# 基本運行
flutter run

# 在特定設備上運行
flutter run -d chrome    # Chrome瀏覽器
flutter run -d ios       # iOS模擬器
flutter run -d android   # Android模擬器

# Debug模式運行（默認）
flutter run --debug

# Release模式運行
flutter run --release

# 查看可用設備
flutter devices
```

### 熱重載和熱重啟
- 在app運行時按 `r` 進行熱重載
- 在app運行時按 `R` 進行熱重啟
- 在app運行時按 `q` 退出

## 2. Debug工具使用

### 內建Debug Screen
- 在debug模式下，主屏幕右下角會出現紅色的bug圖標
- 點擊可進入debug控制台
- 可以查看各Provider的狀態
- 可以執行各種debug操作

### Debug Helper工具
```dart
// 基本日誌
DebugHelper.log('這是一條日誌', tag: 'TAG');

// Provider狀態日誌
DebugHelper.logProviderState('BookProvider', state);

// API請求日誌
DebugHelper.logApiRequest('GET', 'https://api.example.com');

// 性能測量
DebugHelper.measureRenderTime('WidgetName', () {
  // 你的widget構建代碼
});
```

## 3. 常見問題和解決方案

### A. 網路連接問題
**問題**: API調用失敗，顯示離線資料
**解決方案**:
1. 檢查網路連接
2. 確認API URL是否正確
3. 檢查防火牆設置
4. 使用debug screen切換到離線模式測試

### B. Provider狀態問題
**問題**: UI不更新或狀態異常
**解決方案**:
1. 檢查是否正確調用 `notifyListeners()`
2. 確認Provider是否正確註冊
3. 使用debug screen查看Provider狀態
4. 檢查Consumer/Selector的使用

### C. 圖片載入問題
**問題**: 圖片無法顯示
**解決方案**:
1. 檢查圖片URL是否有效
2. 確認網路權限
3. 檢查cached_network_image配置
4. 使用placeholder處理載入失敗

### D. Firebase推送通知問題
**問題**: 推送通知不工作
**解決方案**:
1. 檢查Firebase配置
2. 確認設備權限
3. 檢查網路連接
4. 查看Firebase控制台

### E. 購物車狀態問題
**問題**: 購物車商品不正確
**解決方案**:
1. 檢查CartProvider的狀態管理
2. 確認商品ID是否正確
3. 檢查本地存儲
4. 使用debug screen清空購物車測試

## 4. 性能調試

### 檢查渲染性能
```dart
// 在widget中使用
DebugHelper.measureRenderTime('ExpensiveWidget', () {
  return ExpensiveWidget();
});
```

### 內存使用檢查
```dart
// 在debug screen中點擊"內存檢查"按鈕
DebugHelper.logMemoryUsage();
```

### 網路請求監控
- 所有API請求都會自動記錄在debug screen中
- 可以查看請求URL、狀態碼和響應內容

## 5. 進階Debug技巧

### 使用Flutter Inspector
1. 在VS Code中按 `Ctrl+Shift+P`
2. 輸入 "Flutter: Open Widget Inspector"
3. 可以查看widget樹和屬性

### 使用Dart DevTools
```bash
# 啟動DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

### 條件斷點
在VS Code中設置條件斷點：
1. 在代碼行左側點擊設置斷點
2. 右鍵斷點，選擇"Edit Breakpoint"
3. 設置條件，如 `book.id == '1'`

### 日誌過濾
在debug screen中，日誌會按標籤分類：
- `[BookProvider]`: 書籍相關操作
- `[API]`: 網路請求
- `[PROVIDER]`: Provider狀態變化
- `[PERFORMANCE]`: 性能相關
- `[MEMORY]`: 內存使用

## 6. 錯誤處理最佳實踐

### 優雅降級
```dart
try {
  // 嘗試API調用
  final data = await fetchData();
} catch (e) {
  // 使用本地資料作為備用
  DebugHelper.log('API失敗，使用本地資料: $e');
  loadLocalData();
}
```

### 用戶友好的錯誤信息
```dart
if (error != null) {
  return ErrorWidget(
    message: '載入失敗，請檢查網路連接',
    onRetry: () => retry(),
  );
}
```

## 7. 測試和驗證

### 手動測試流程
1. 啟動app並進入debug screen
2. 測試各種操作（載入書籍、添加到購物車等）
3. 檢查日誌輸出
4. 模擬網路錯誤（關閉網路）
5. 測試離線模式

### 自動化測試
```bash
# 運行單元測試
flutter test

# 運行集成測試
flutter drive --target=test_driver/app.dart
```

## 8. 發布前檢查清單

- [ ] 移除所有debug print語句
- [ ] 確認API URL指向生產環境
- [ ] 測試所有功能在release模式下正常工作
- [ ] 檢查性能是否滿足要求
- [ ] 確認錯誤處理是否完善
- [ ] 測試離線模式功能

## 9. 有用的VS Code擴展

- Flutter
- Dart
- Flutter Widget Snippets
- Bracket Pair Colorizer
- Error Lens
- GitLens

## 10. 緊急問題處理

如果app完全無法啟動：
1. 運行 `flutter clean`
2. 運行 `flutter pub get`
3. 重新啟動IDE
4. 檢查Flutter版本兼容性
5. 查看完整的錯誤日誌

記住：debug是一個迭代過程，保持耐心並系統性地解決問題！
