# OAuth 後端整合規格（Google、Facebook）

## 概述

前端已實作 Google/Facebook OAuth 登入流程，會呼叫統一端點 `POST /auth/oauth`，並期待與帳密登入相同的回應結構（`success`, `token`, `refresh_token`, `user`）。本文件定義後端需提供的 API、資料表與安全規範，並說明與既有帳號密碼登入之整合規則。

- Base URL：依前端 `lib/config/api_config.dart`（預設 `https://api.taaze.tw/api/v1`）
- 既有端點（前端已使用）：
  - POST `/auth/login`（含驗證碼機制）
  - GET `/auth/captcha`、POST `/auth/captcha/refresh`
  - POST `/auth/logout`
  - POST `/auth/refresh`
- 新增端點：
  - POST `/auth/oauth`（Google/Facebook 統一入口）

---

## 1) POST /auth/oauth

請求 Body（JSON）：
```json
{
  "provider": "google",
  "access_token": "ACCESS_TOKEN",
  "id_token": "ID_TOKEN (可選，Google 建議傳)",
  "user_info": {
    "id": "provider_user_id",
    "email": "user@example.com",
    "name": "User Name",
    "avatar": "https://...",
    "provider": "google"
  }
}
```

處理流程：
- 驗證 `provider ∈ {google, facebook}`，`access_token` 非空
- 伺服器端向供應商驗證 token 並以供應商 API 拉取權威用戶資料（不要信任前端提供的 `user_info`）
  - Google：
    - 若有 `id_token`，驗證簽章與 `aud`（你的 Google Client ID）、`iss`、`exp`、`email_verified`
    - 若無 `id_token`，使用 `access_token` 取回 `https://www.googleapis.com/oauth2/v3/userinfo`（`sub/id,email,name,picture,email_verified`）
  - Facebook：
    - 用 App Token 呼叫 `GET https://graph.facebook.com/debug_token?input_token={access_token}&access_token={app_id}|{app_secret}` 驗證 token
    - 再取 `GET https://graph.facebook.com/me?fields=id,name,email,picture.type(large)&access_token={access_token}`

帳號整合規則：
- 以 `(provider, provider_user_id)` 查 `oauth_accounts`
  - 找到 → 取對應 `users`，更新 `last_login_at`，簽發 tokens
- 找不到 → 以 email 查 `users`
  - 若存在：
    - 預設「自動綁定」當且僅當可判斷 email 已驗證（Google `email_verified=true`；Facebook 如缺驗證資訊則需至少有 email 才允許綁定，否則拒絕）
    - 建立 `oauth_accounts` 關聯
  - 若不存在：建立新 `users`，再建 `oauth_accounts`

成功回應（200）：
```json
{
  "success": true,
  "token": "JWT_ACCESS_TOKEN",
  "refresh_token": "JWT_REFRESH_TOKEN",
  "user": {
    "id": "user_id",
    "email": "user@example.com",
    "name": "User Name",
    "avatar": "https://...",
    "provider": "google",
    "created_at": "2025-10-30T00:00:00.000Z",
    "last_login_at": "2025-10-30T00:00:00.000Z"
  }
}
```

失敗回應（需與前端解析對齊）：
- 一般錯誤：
```json
{ "success": false, "error": "OAuth 登入失敗：原因說明" }
```
- 需要驗證碼（沿用帳密登入策略）：
```json
{
  "success": false,
  "error": "需要驗證碼",
  "captcha_required": true,
  "captcha": {
    "captcha_id": "abc123",
    "captcha_image": "data:image/png;base64,...",
    "required": true,
    "message": "請輸入驗證碼"
  }
}
```

欄位命名建議採用 snake_case（前端已相容），例如 `refresh_token`, `captcha_required`。

---

## 2) 資料庫結構建議

`users`
- `id (pk)`, `email (unique, not null)`, `password_hash (nullable)`, `name`, `avatar`, `is_active (bool)`, `email_verified (bool)`, `created_at`, `last_login_at`

`oauth_accounts`
- `id (pk)`, `user_id (fk users.id)`, `provider (enum['google','facebook'])`, `provider_user_id`, `provider_email`, `linked_at`, `last_login_at`, `raw_profile (jsonb)`, `access_token_hash (optional)`, `refresh_token_hash (optional)`
- 唯一鍵：`(provider, provider_user_id)`；索引：`user_id`, `provider_email`

`refresh_tokens`
- `id (pk)`, `user_id`, `token_hash`, `issued_at`, `expires_at`, `revoked_at`, `ua`, `ip`

---

## 3) Token 規格

- Access Token：JWT（~15 分鐘），payload 至少含 `sub (user_id)`, `iat`, `exp`, `provider`
- Refresh Token：長效（7–30 天），每次使用即輪替（Rotate on use），僅儲存雜湊於 DB
- 登出：`/auth/logout` 作廢當前 refresh token，可選即時黑名單 access token 的 `jti`
- 刷新：`/auth/refresh` 簽發新 access/refresh（舊 refresh 作廢）

---

## 4) 與帳密登入整合

- 保持 `/auth/login` 現有行為（驗證碼/鎖定/速率限制）
- `/auth/oauth` 回傳結構與帳密登入一致，前端可無縫使用
- 一個使用者可同時存在 password 與多個 `oauth_accounts`
- 如需嚴謹綁定流程（密碼或 Email OTP 驗證），可另增 `POST /auth/oauth/bind`（前端目前未接）

---

## 5) 安全與風險控管

- 供應商驗證必須在後端完成，不信任前端 `user_info`
- Email 驗證：
  - Google：僅 `email_verified=true` 才自動綁定
  - Facebook：若缺 email 或不可驗證 → 拒絕綁定
- 速率限制/驗證碼：可沿用帳密登入策略；高風險情況回傳 `captcha_required`
- 不長期儲存第三方 access_token 明文；必要時雜湊或以 KMS 加密
- 回傳時間格式使用 ISO8601 UTC

---

## 6) 設定與環境變數

- GOOGLE：`GOOGLE_CLIENT_ID`（允許的 `aud`）、（如需）`GOOGLE_CLIENT_IDS` 多平台清單
- FACEBOOK：`FACEBOOK_APP_ID`, `FACEBOOK_APP_SECRET`
- JWT：`JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`, `JWT_ISSUER`, `JWT_AUDIENCE`
- 其他：DB 連線、CORS 白名單、伺服器時間同步

---

## 7) 伺服器處理（簡化流程）

1. 解析 `provider`, `access_token`, `id_token`
2. 依 provider 驗證並取得 profile（`id/email/name/avatar/email_verified`）
3. 若無 email → 回 `{ success:false, error:"未取得 email" }`
4. `(provider, provider_user_id)` 查 `oauth_accounts` → 有則登入
5. 否則 `email` 查 `users`：
   - 有且允許自動綁定 → 建立 `oauth_accounts`，登入
   - 無 → 建立 `users` + `oauth_accounts`，登入
6. 套用速率/驗證碼策略，必要時回傳 `captcha_required`

---

## 8) 驗收測試

- Google：
  - 新用戶首次登入（建立 user+綁定）
  - 舊用戶同 email（email_verified=true）自動綁定
  - 無效/過期 token 處理
- Facebook：
  - 有 email 情形的綁定/建立
  - 無 email → 正確失敗回應
- 整合：
  - `/auth/oauth` 與 `/auth/login` 回傳一致
  - 速率限制/驗證碼觸發時前端可顯示驗證碼
  - Refresh/Logout 正常

---

如需參考控制器與 provider 驗證骨架（FastAPI 或 Node），可再補充範例檔。
