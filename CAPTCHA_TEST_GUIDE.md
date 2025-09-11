# 驗證碼整合測試指南

## 概述
本指南說明如何測試登入畫面的驗證碼功能，確保與 FastAPI 後端的整合正常運作。

## 測試環境設置

### 1. 啟動 FastAPI 後端
```bash
# 進入 FastAPI 項目目錄
cd fastapi_captcha

# 安裝依賴
pip install -r requirements.txt

# 啟動 Redis（如果沒有運行）
redis-server --daemonize yes

# 啟動 FastAPI 應用
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### 2. 啟動 Flutter 應用
```bash
# 在 Flutter 項目根目錄
flutter run -d chrome
```

## 測試流程

### 測試 1: 正常登入（需要驗證碼）
1. 打開登入畫面
2. **預期結果**：驗證碼區域立即顯示（橙色邊框）
3. 輸入有效的測試帳戶：
   - 電子郵件：`test@example.com`
   - 密碼：`password123`
   - 驗證碼：輸入顯示的驗證碼
4. 點擊「登入」按鈕
5. **預期結果**：成功登入，跳轉到主畫面

### 測試 2: 未輸入驗證碼
1. 輸入帳戶資訊但不輸入驗證碼：
   - 電子郵件：`test@example.com`
   - 密碼：`password123`
   - 驗證碼：留空
2. 點擊「登入」按鈕
3. **預期結果**：顯示「請輸入驗證碼」錯誤訊息

### 測試 3: 登入失敗
1. 輸入錯誤的密碼：
   - 電子郵件：`test@example.com`
   - 密碼：`wrongpassword`
   - 驗證碼：輸入顯示的驗證碼
2. 點擊「登入」按鈕
3. **預期結果**：
   - 顯示錯誤訊息
   - 自動刷新驗證碼
   - 驗證碼輸入框被清空

### 測試 4: 驗證碼刷新功能
1. 在驗證碼顯示後，點擊刷新按鈕（🔄）
2. **預期結果**：
   - 驗證碼圖片更新
   - 驗證碼輸入框被清空

### 測試 5: 驗證碼驗證
1. 輸入錯誤的驗證碼
2. 點擊「登入」按鈕
3. **預期結果**：
   - 顯示驗證碼錯誤訊息
   - 自動獲取新的驗證碼

### 測試 6: 驗證碼過期處理
1. 等待驗證碼過期（5分鐘）或手動觸發過期
2. 嘗試登入
3. **預期結果**：
   - 顯示「驗證碼已過期，請刷新後重試」訊息
   - 自動刷新驗證碼

## API 端點測試

### 手動測試 API
```bash
# 獲取驗證碼
curl -X GET "http://localhost:8000/api/v1/auth/captcha"

# 登入（無驗證碼）
curl -X POST "http://localhost:8000/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'

# 登入（帶驗證碼）
curl -X POST "http://localhost:8000/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "captcha_id": "your-captcha-id",
    "captcha_code": "your-captcha-code"
  }'
```

## 故障排除

### 常見問題

1. **驗證碼圖片不顯示**
   - 檢查 FastAPI 是否正常運行
   - 檢查網路連接
   - 查看 Flutter 控制台錯誤訊息

2. **API 調用失敗**
   - 確認 API URL 設置正確：`https://api.taaze.tw/api/v1`
   - 檢查 CORS 設置
   - 查看網路請求日誌

3. **驗證碼驗證失敗**
   - 確認輸入的驗證碼大小寫正確
   - 檢查驗證碼是否過期（5分鐘）
   - 確認 captcha_id 正確傳遞

### 調試技巧

1. **啟用 Flutter 調試模式**
   ```bash
   flutter run --debug
   ```

2. **查看網路請求**
   - 在 Chrome 開發者工具中查看 Network 標籤
   - 檢查 API 請求和響應

3. **查看 Flutter 日誌**
   ```bash
   flutter logs
   ```

## 預期行為

### 驗證碼顯示邏輯
- 打開登入畫面時，系統會自動獲取並顯示驗證碼
- 驗證碼區域會以橙色邊框突出顯示
- 包含安全提示文字：「為了保護您的帳戶安全，請輸入下方驗證碼完成登入」

### 用戶體驗
- 驗證碼輸入框自動聚焦
- 支援大寫字母輸入
- 刷新按鈕提供即時反饋
- 錯誤訊息清晰明確

### 安全性
- 驗證碼 5 分鐘後自動過期
- 最多允許 3 次驗證嘗試
- 登入失敗會觸發新的驗證碼

## 完成測試檢查清單

- [ ] 打開登入畫面時驗證碼立即顯示
- [ ] 未輸入驗證碼時顯示錯誤訊息
- [ ] 驗證碼圖片正常顯示
- [ ] 驗證碼刷新功能正常
- [ ] 錯誤驗證碼處理正確
- [ ] 正確驗證碼登入成功
- [ ] 驗證碼過期處理
- [ ] 登入失敗後自動刷新驗證碼
- [ ] 網路錯誤處理
- [ ] UI 響應式設計
- [ ] 錯誤訊息清晰
- [ ] 所有登入都需要驗證碼

完成所有測試項目後，驗證碼整合功能即可投入使用。
