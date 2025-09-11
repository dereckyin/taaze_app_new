# 橫幅 API 響應格式示例

## 1. 橫幅列表 API

**端點**: `GET /api/banners`

**查詢參數**:
- `type`: 橫幅類型 (可選) - promotion, announcement, featured, new_release, event
- `active`: 是否只返回有效橫幅 (預設: true)
- `limit`: 限制返回數量 (可選)

**響應格式**:
```json
{
  "data": [
    {
      "id": "1",
      "title": "讀冊生活網路書店",
      "subtitle": "探索數千本精彩書籍",
      "description": "享受閱讀的美好時光，發現更多精彩內容",
      "imageUrl": "https://picsum.photos/800/400?random=1",
      "actionUrl": "/search",
      "actionText": "開始探索",
      "type": "featured",
      "isActive": true,
      "displayOrder": 1,
      "createdAt": "2024-01-15T00:00:00Z",
      "expiresAt": null
    },
    {
      "id": "2",
      "title": "新會員優惠",
      "subtitle": "首次購書享8折優惠",
      "description": "立即註冊成為會員，享受專屬優惠價格",
      "imageUrl": "https://picsum.photos/800/400?random=2",
      "actionUrl": "/register",
      "actionText": "立即註冊",
      "type": "promotion",
      "isActive": true,
      "displayOrder": 2,
      "createdAt": "2024-01-14T00:00:00Z",
      "expiresAt": "2024-02-15T00:00:00Z"
    }
  ],
  "total_count": 6,
  "success": true
}
```

## 2. 橫幅類型說明

### BannerType 枚舉值
- `promotion`: 促銷活動
- `announcement`: 公告
- `featured`: 精選推薦
- `new_release`: 新品上市
- `event`: 活動

### 橫幅狀態
- `isActive`: 是否啟用
- `expiresAt`: 過期時間 (null表示永不過期)
- `displayOrder`: 顯示順序 (數字越小越靠前)

## 3. 後端實現示例

### Node.js + Express 示例

```javascript
// 橫幅列表API
app.get('/api/banners', async (req, res) => {
  try {
    const { type, active = true, limit } = req.query;
    
    const query = {};
    
    if (type) {
      query.type = type;
    }
    
    if (active === 'true') {
      query.isActive = true;
      query.$or = [
        { expiresAt: null },
        { expiresAt: { $gt: new Date() } }
      ];
    }
    
    let banners = await Banner.find(query)
      .sort({ displayOrder: 1, createdAt: -1 });
    
    if (limit) {
      banners = banners.limit(parseInt(limit));
    }
    
    res.json({
      data: banners,
      total_count: banners.length,
      success: true
    });
  } catch (error) {
    res.status(500).json({
      error: {
        code: 'INTERNAL_ERROR',
        message: '伺服器內部錯誤'
      }
    });
  }
});

// 創建橫幅API
app.post('/api/banners', async (req, res) => {
  try {
    const bannerData = req.body;
    const banner = new Banner(bannerData);
    await banner.save();
    
    res.status(201).json({
      data: banner,
      success: true
    });
  } catch (error) {
    res.status(400).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: error.message
      }
    });
  }
});

// 更新橫幅API
app.put('/api/banners/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;
    
    const banner = await Banner.findByIdAndUpdate(
      id, 
      updateData, 
      { new: true }
    );
    
    if (!banner) {
      return res.status(404).json({
        error: {
          code: 'BANNER_NOT_FOUND',
          message: '找不到指定的橫幅'
        }
      });
    }
    
    res.json({
      data: banner,
      success: true
    });
  } catch (error) {
    res.status(500).json({
      error: {
        code: 'INTERNAL_ERROR',
        message: '伺服器內部錯誤'
      }
    });
  }
});

// 刪除橫幅API
app.delete('/api/banners/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const banner = await Banner.findByIdAndDelete(id);
    
    if (!banner) {
      return res.status(404).json({
        error: {
          code: 'BANNER_NOT_FOUND',
          message: '找不到指定的橫幅'
        }
      });
    }
    
    res.json({
      success: true,
      message: '橫幅已刪除'
    });
  } catch (error) {
    res.status(500).json({
      error: {
        code: 'INTERNAL_ERROR',
        message: '伺服器內部錯誤'
      }
    });
  }
});
```

### Python + FastAPI 示例

```python
from fastapi import FastAPI, Query, HTTPException
from typing import Optional, List
from datetime import datetime

app = FastAPI()

@app.get("/api/banners")
async def get_banners(
    type: Optional[str] = None,
    active: bool = True,
    limit: Optional[int] = None
):
    query = {}
    
    if type:
        query["type"] = type
    
    if active:
        query["isActive"] = True
        query["$or"] = [
            {"expiresAt": None},
            {"expiresAt": {"$gt": datetime.now()}}
        ]
    
    banners = await Banner.find(query).sort("displayOrder", 1).sort("createdAt", -1)
    
    if limit:
        banners = banners.limit(limit)
    
    return {
        "data": banners,
        "total_count": len(banners),
        "success": True
    }

@app.post("/api/banners")
async def create_banner(banner_data: dict):
    try:
        banner = Banner(**banner_data)
        await banner.save()
        return {
            "data": banner,
            "success": True
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.put("/api/banners/{banner_id}")
async def update_banner(banner_id: str, update_data: dict):
    banner = await Banner.find_one({"_id": banner_id})
    
    if not banner:
        raise HTTPException(status_code=404, detail="橫幅不存在")
    
    for key, value in update_data.items():
        setattr(banner, key, value)
    
    await banner.save()
    
    return {
        "data": banner,
        "success": True
    }

@app.delete("/api/banners/{banner_id}")
async def delete_banner(banner_id: str):
    banner = await Banner.find_one({"_id": banner_id})
    
    if not banner:
        raise HTTPException(status_code=404, detail="橫幅不存在")
    
    await banner.delete()
    
    return {
        "success": True,
        "message": "橫幅已刪除"
    }
```

## 4. 資料庫設計

### MongoDB 文檔結構

```javascript
{
  "_id": ObjectId("..."),
  "id": "1",
  "title": "讀冊生活網路書店",
  "subtitle": "探索數千本精彩書籍",
  "description": "享受閱讀的美好時光，發現更多精彩內容",
  "imageUrl": "https://picsum.photos/800/400?random=1",
  "actionUrl": "/search",
  "actionText": "開始探索",
  "type": "featured",
  "isActive": true,
  "displayOrder": 1,
  "createdAt": ISODate("2024-01-15T00:00:00Z"),
  "expiresAt": null,
  "updatedAt": ISODate("2024-01-15T00:00:00Z"),
  "createdBy": "admin",
  "tags": ["homepage", "featured"]
}
```

### 索引建議

```javascript
// 複合索引
db.banners.createIndex({ "type": 1, "isActive": 1, "displayOrder": 1 })
db.banners.createIndex({ "isActive": 1, "expiresAt": 1 })
db.banners.createIndex({ "createdAt": -1 })

// 唯一索引
db.banners.createIndex({ "id": 1 }, { unique: true })
```

## 5. 快取策略

### Redis 快取示例

```javascript
// 快取橫幅列表
const cacheKey = 'banners:active';
const cachedBanners = await redis.get(cacheKey);

if (cachedBanners) {
  return JSON.parse(cachedBanners);
}

const banners = await Banner.find({
  isActive: true,
  $or: [
    { expiresAt: null },
    { expiresAt: { $gt: new Date() } }
  ]
}).sort({ displayOrder: 1 });

const result = {
  data: banners,
  total_count: banners.length,
  success: true
};

// 快取30分鐘
await redis.setex(cacheKey, 1800, JSON.stringify(result));
return result;
```

## 6. 管理後台功能

### 橫幅管理功能
1. **橫幅列表**: 顯示所有橫幅，支持篩選和排序
2. **創建橫幅**: 表單創建新橫幅
3. **編輯橫幅**: 修改現有橫幅
4. **預覽功能**: 預覽橫幅在app中的顯示效果
5. **批量操作**: 批量啟用/停用橫幅
6. **統計分析**: 橫幅點擊率和轉換率

### 橫幅編輯表單字段
- 標題 (必填)
- 副標題 (必填)
- 描述 (可選)
- 背景圖片 (必填)
- 行動按鈕文字 (可選)
- 行動按鈕連結 (可選)
- 橫幅類型 (必填)
- 顯示順序 (必填)
- 啟用狀態 (必填)
- 過期時間 (可選)

## 7. 性能優化建議

1. **圖片優化**: 使用CDN和圖片壓縮
2. **快取策略**: 對熱門橫幅進行快取
3. **分頁載入**: 大量橫幅時使用分頁
4. **懶載入**: 圖片懶載入減少初始載入時間
5. **預載入**: 預載入下一張橫幅圖片
6. **壓縮**: 啟用Gzip壓縮減少傳輸大小

## 8. 切換到真實API

當API開發完成後，需要進行以下修改：

### 1. 恢復API配置
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
取消註解 `_fetchBannersFromAPI` 方法

### 4. 修改載入邏輯
將 `_loadBanners` 方法改回調用真實API

### 5. 更新API URL
將 `_baseUrl` 改為實際的API地址
