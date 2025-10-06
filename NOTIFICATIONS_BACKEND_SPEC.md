# App Push Notifications Backend Spec

本文件定義行動 App 推播通知後端規格，涵蓋：裝置 Token 註冊/撤銷、訊息送出、Topic 管理、FCM 整合、錯誤與安全性。

## 目標
- 讓 App 能：
  - 上傳/更新 FCM Token（含平台、版本等）
  - 登出或移除裝置時撤銷 Token
  - 由後端主動推播單人、多人或 Topic 群組
- 讓後端能：
  - 對特定使用者或 Topic 推播
  - 管理 Token 壽命與無效 Token 清理

## 名詞
- FCM: Firebase Cloud Messaging
- Token: FCM 裝置 Token（每台裝置一個，可更新）
- Topic: FCM 群組主題，用於廣播推播

---

## API 總覽

1) 裝置 Token 註冊
- Method: `POST`
- Path: `/api/v1/notifications/register-token`
- Auth: Bearer JWT（需識別 user_id）
- Body:
```json
{
  "fcm_token": "string",
  "platform": "ios|android",
  "app_version": "1.0.0",
  "device_model": "optional",
  "locale": "zh-TW"
}
```
- Response: `204 No Content`
- 行為：
  - 以 `(user_id, fcm_token)` 去重，若已存在則更新 `last_seen_at`、`app_version`、`locale`。
  - 若同一 user 有多個 token，全部保留（多裝置）。

2) 裝置 Token 撤銷（登出/移除裝置）
- Method: `POST`
- Path: `/api/v1/notifications/revoke-token`
- Auth: Bearer JWT（或允許無登入時也可撤銷該 token）
- Body:
```json
{ "fcm_token": "string" }
```
- Response: `204 No Content`
- 行為：
  - 刪除該 token 與使用者的綁定記錄。

3) 發送推播（管理後台/內部使用）
- Method: `POST`
- Path: `/api/v1/notifications/send`
- Auth: Admin（內部權限）
- Body（擇一指定 user_ids 或 topic）：
```json
{
  "user_ids": ["u1", "u2"],
  "topic": "promo-2025Q4",
  "notification": {
    "title": "標題",
    "body": "內容",
    "image": "https://... optional"
  },
  "data": {
    "type": "order|promotion|bookRecommendation|general",
    "target": "screen/order_detail?orderId=12345",
    "payload": "{\"orderId\":\"12345\"}"
  },
  "options": {
    "android_priority": "high",
    "apns_priority": 10,
    "content_available": false
  }
}
```
- Response:
```json
{ "success": true, "sent": 2, "failed": 0, "errors": [] }
```
- 行為：
  - 若提供 `user_ids`：查詢每個使用者綁定的所有 token 並逐一送出。
  - 若提供 `topic`：以 FCM Topic 下發（需先由客戶端訂閱）。
  - `notification` 與 `data` 可同時存在：前者顯示標題與內容，後者提供導頁資料。
  - iOS 資料-only 背景更新可用 `options.content_available = true`（避免顯示提醒）。

4) 訂閱/取消訂閱 Topic（可由 App 或後端代發）
- Method: `POST`
- Path: `/api/v1/notifications/subscribe-topic`
- Auth: Bearer JWT
- Body:
```json
{ "fcm_token": "string", "topic": "promo-all" }
```
- Response: `204 No Content`

- 取消訂閱： `POST /api/v1/notifications/unsubscribe-topic`
```json
{ "fcm_token": "string", "topic": "promo-all" }
```
- Response: `204 No Content`

---

## 後端資料模型（範例）

Table: `push_device_tokens`
- `id` (PK)
- `user_id` (FK -> users)
- `fcm_token` (unique per user)
- `platform` (enum: ios|android)
- `app_version` (string)
- `device_model` (string, nullable)
- `locale` (string, nullable)
- `created_at`, `last_seen_at`

索引：
- unique(user_id, fcm_token)
- index(user_id)

---

## FCM 送出規格

1) 單裝置 Token 推播（HTTP v1）
- Endpoint: `https://fcm.googleapis.com/v1/projects/<PROJECT_ID>/messages:send`
- Auth: OAuth2 服務帳戶（Server-to-Server）
- Request（對 token）
```json
{
  "message": {
    "token": "DEVICE_FCM_TOKEN",
    "notification": { "title": "訂單更新", "body": "您的訂單已出貨" },
    "data": {
      "type": "order",
      "target": "screen/order_detail?orderId=12345",
      "payload": "{\"orderId\":\"12345\"}"
    },
    "android": { "priority": "high" },
    "apns": {
      "headers": { "apns-priority": "10" },
      "payload": { "aps": { "content-available": 0 } }
    }
  }
}
```

2) Topic 推播
```json
{
  "message": {
    "topic": "promo-all",
    "notification": { "title": "雙11活動", "body": "全館 8 折" },
    "data": { "type": "promotion", "target": "screen/promo?campaign=1111" }
  }
}
```

3) 錯誤處理與無效 Token 移除
- 收到 FCM 回傳錯誤：
  - `NotRegistered`、`InvalidRegistration`、`MismatchSenderId` → 刪除該 token 綁定。
  - 其它錯誤 → 記錄並稍後重試（指數退避）。

---

## 安全性與權限
- Token 註冊/撤銷需綁定當前登入使用者（JWT）。
- 管理後台送出推播需 Admin 權限，建議使用內部網段或 API Key 白名單。
- 僅允許相同 `user_id` 操作其名下 token。
- 記錄審計 log：誰對哪些 `user_id/topic` 發送了什麼通知，何時發送，結果如何。

---

## 延伸功能建議
- 使用者偏好：儲存允許的通知類型（order/promotion/...），送出前依偏好過濾目標 token。
- 頻率控制：對單 user/topic 做節流（ex: 每 5 分鐘最多 1 則）。
- A/B 測試：不同文案、載圖測試成效。
- 排程：支援延遲送出、定時推播。

---

## App 端契約（供後端參考）
- App 會攜帶以下 `data` 欄位以進行導頁：
  - `type`: `order|promotion|bookRecommendation|general`
  - `target`: app route 或 deeplink，如 `screen/order_detail?orderId=12345`
  - `payload`: JSON 字串，額外參數
- 後端若只想背景更新，不要打擾使用者：
  - iOS：`apns.payload.aps.content-available = 1` 並省略 `notification` 區塊
  - Android：可考慮 data-only，App 前景時走本地通知

---

## 範例流程
1) App 啟動後取得 `fcm_token` → 呼叫 `/register-token` 綁定 user。
2) 後端接單狀態更新 → 呼叫 `/send` 對該 user 推播（含導頁 data）。
3) App 前景收到 → 顯示本地通知並寫入通知中心；點擊通知導頁到 `target`。
4) 使用者登出 → App 呼叫 `/revoke-token` 撤銷該裝置 token。

---

## 驗收清單
- [ ] 註冊/撤銷 token API 可用，含權限驗證
- [ ] send API 可同時支援 user_ids 與 topic（至少擇一）
- [ ] FCM 錯誤能正確移除無效 token
- [ ] 管理端推播有操作審計 log
- [ ] 壓力測試：批量 user_ids 推播的效能與重試策略


