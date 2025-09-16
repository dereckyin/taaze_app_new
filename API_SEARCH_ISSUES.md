# 搜尋 API 問題報告

## 當前問題

### 1. 搜尋 API 端點問題
- **問題**: 搜尋 API 返回 404 錯誤
- **當前端點**: `https://api.taaze.tw/api/v1/search/{keyword}`
- **錯誤訊息**: `{"detail":"Not Found"}`
- **狀態碼**: 404

### 2. 建議的修正方案

#### 方案 A: 修正端點路徑
如果搜尋功能應該使用不同的端點，建議修正為：
```
GET https://api.taaze.tw/api/v1/books/search?q={keyword}
```
或
```
GET https://api.taaze.tw/api/v1/search?keyword={keyword}
```

#### 方案 B: 修正路徑參數格式
如果當前端點格式正確，可能需要 URL 編碼：
```
GET https://api.taaze.tw/api/v1/search/{url_encoded_keyword}
```

### 3. 期望的 API 響應格式

為了支援無限滾動功能，建議 API 響應包含分頁資訊：

```json
{
  "data": [
    {
      "id": "string",
      "title": "string",
      "author": "string",
      "description": "string",
      "price": 0.0,
      "imageUrl": "string",
      "category": "string",
      "rating": 0.0,
      "reviewCount": 0,
      "isAvailable": true,
      "publishDate": "2024-01-01T00:00:00Z",
      "isbn": "string",
      "pages": 0,
      "publisher": "string"
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalCount": 100,
    "totalPages": 5,
    "hasMore": true
  }
}
```

### 4. 分頁參數支援

建議 API 支援以下查詢參數：
- `page`: 頁碼（從 1 開始）
- `pageSize`: 每頁數量（預設 20）
- `sort`: 排序方式（如：`title`, `price`, `rating`, `publishDate`）
- `order`: 排序順序（`asc` 或 `desc`）

### 5. 完整的搜尋 API 規格建議

```
GET https://api.taaze.tw/api/v1/search?q={keyword}&page={page}&pageSize={pageSize}&sort={sort}&order={order}
```

**參數說明**:
- `q`: 搜尋關鍵字（必需）
- `page`: 頁碼，預設 1
- `pageSize`: 每頁數量，預設 20，最大 100
- `sort`: 排序欄位，可選值：`title`, `author`, `price`, `rating`, `publishDate`
- `order`: 排序順序，可選值：`asc`, `desc`，預設 `asc`

**響應格式**:
```json
{
  "success": true,
  "data": [
    {
      "id": "string",
      "title": "string",
      "author": "string",
      "description": "string",
      "price": 0.0,
      "imageUrl": "string",
      "category": "string",
      "rating": 0.0,
      "reviewCount": 0,
      "isAvailable": true,
      "publishDate": "2024-01-01T00:00:00Z",
      "isbn": "string",
      "pages": 0,
      "publisher": "string"
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalCount": 100,
    "totalPages": 5,
    "hasMore": true
  },
  "message": "搜尋成功"
}
```

### 6. 錯誤處理

建議 API 返回標準化的錯誤格式：

```json
{
  "success": false,
  "error": {
    "code": "SEARCH_ERROR",
    "message": "搜尋失敗",
    "details": "具體錯誤訊息"
  }
}
```

### 7. 測試建議

建議後端團隊測試以下場景：
1. 空關鍵字搜尋
2. 特殊字符搜尋（如：`@#$%^&*()`）
3. 中文關鍵字搜尋
4. 英文關鍵字搜尋
5. 混合語言搜尋
6. 分頁邊界測試
7. 大量結果搜尋

### 8. 效能優化建議

1. **索引優化**: 確保資料庫有適當的搜尋索引
2. **快取機制**: 對熱門搜尋關鍵字實施快取
3. **分頁限制**: 限制每頁最大數量，避免過大響應
4. **搜尋建議**: 提供搜尋建議功能
5. **搜尋歷史**: 記錄用戶搜尋歷史（可選）

## 當前解決方案

在 API 修正之前，應用程式會：
1. 嘗試調用真實 API
2. 如果 API 失敗，自動回退到模擬資料
3. 使用模擬資料展示搜尋功能和無限滾動效果
4. 提供完整的用戶體驗

## 聯絡資訊

如有任何問題或需要進一步討論，請聯絡前端開發團隊。
