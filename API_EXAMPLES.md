# API 響應格式示例

## 1. 今日特惠 API

**端點**: `GET /api/books/today-deals`

**響應格式**:
```json
{
  "data": [
    {
      "id": "1",
      "title": "Flutter開發實戰",
      "author": "張三",
      "description": "這是一本關於Flutter開發的實戰指南...",
      "price": 299.0,
      "original_price": 599.0,
      "discount": 50,
      "imageUrl": "https://picsum.photos/300/400?random=1",
      "category": "程式設計",
      "rating": 4.8,
      "reviewCount": 128,
      "isAvailable": true,
      "publishDate": "2024-01-15T00:00:00Z",
      "isbn": "9781234567890",
      "pages": 350,
      "publisher": "科技出版社"
    }
  ],
  "total_count": 25,
  "has_more": true
}
```

## 2. 暢銷排行榜 API

**端點**: `GET /api/books/bestsellers`

**響應格式**:
```json
{
  "data": [
    {
      "id": "2",
      "title": "Dart語言入門",
      "author": "李四",
      "description": "學習Dart程式語言的完整指南...",
      "price": 399.0,
      "imageUrl": "https://picsum.photos/300/400?random=2",
      "category": "程式設計",
      "rating": 4.5,
      "reviewCount": 89,
      "isAvailable": true,
      "publishDate": "2024-02-10T00:00:00Z",
      "isbn": "9781234567891",
      "pages": 280,
      "publisher": "程式設計出版社",
      "sales_rank": 1
    }
  ],
  "total_count": 50,
  "has_more": true
}
```

## 3. 注目新品 API

**端點**: `GET /api/books/new-releases`

**響應格式**:
```json
{
  "data": [
    {
      "id": "3",
      "title": "移動應用設計",
      "author": "王五",
      "description": "現代移動應用UI/UX設計的最佳實踐...",
      "price": 699.0,
      "imageUrl": "https://picsum.photos/300/400?random=3",
      "category": "設計",
      "rating": 4.7,
      "reviewCount": 156,
      "isAvailable": true,
      "publishDate": "2024-01-20T00:00:00Z",
      "isbn": "9781234567892",
      "pages": 420,
      "publisher": "設計出版社",
      "is_new": true
    }
  ],
  "total_count": 30,
  "has_more": true
}
```

## 4. 最新上架二手書 API

**端點**: `GET /api/books/used-books`

**響應格式**:
```json
{
  "data": [
    {
      "id": "4",
      "title": "人工智慧基礎",
      "author": "趙六",
      "description": "人工智慧的基本概念和應用實例...",
      "price": 299.0,
      "original_price": 799.0,
      "imageUrl": "https://picsum.photos/300/400?random=4",
      "category": "人工智慧",
      "rating": 4.9,
      "reviewCount": 203,
      "isAvailable": true,
      "publishDate": "2024-03-05T00:00:00Z",
      "isbn": "9781234567893",
      "pages": 500,
      "publisher": "AI出版社",
      "condition": "良好",
      "is_used": true
    }
  ],
  "total_count": 100,
  "has_more": true
}
```

## 5. 分頁查詢 API

**端點**: `GET /api/books`

**查詢參數**:
- `page`: 頁碼 (預設: 1)
- `page_size`: 每頁數量 (預設: 20)
- `category`: 分類篩選 (可選)
- `search`: 搜尋關鍵字 (可選)

**響應格式**:
```json
{
  "data": [
    {
      "id": "5",
      "title": "資料庫設計",
      "author": "孫七",
      "description": "現代資料庫設計和優化技術...",
      "price": 549.0,
      "imageUrl": "https://picsum.photos/300/400?random=5",
      "category": "資料庫",
      "rating": 4.6,
      "reviewCount": 94,
      "isAvailable": true,
      "publishDate": "2024-02-28T00:00:00Z",
      "isbn": "9781234567894",
      "pages": 320,
      "publisher": "資料科技出版社"
    }
  ],
  "total_count": 1000,
  "has_more": true,
  "current_page": 1,
  "page_size": 20
}
```

## 6. 錯誤響應格式

**HTTP狀態碼**: 4xx 或 5xx

**響應格式**:
```json
{
  "error": {
    "code": "BOOK_NOT_FOUND",
    "message": "找不到指定的書籍",
    "details": "書籍ID不存在或已被刪除"
  }
}
```

## 7. 後端實現建議

### Node.js + Express 示例

```javascript
// 今日特惠API
app.get('/api/books/today-deals', async (req, res) => {
  try {
    const books = await Book.find({
      discount: { $gte: 30 },
      isAvailable: true
    }).limit(6);
    
    res.json({
      data: books,
      total_count: books.length,
      has_more: false
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

// 分頁查詢API
app.get('/api/books', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const pageSize = parseInt(req.query.page_size) || 20;
    const category = req.query.category;
    const search = req.query.search;
    
    const query = { isAvailable: true };
    
    if (category) {
      query.category = category;
    }
    
    if (search) {
      query.$or = [
        { title: { $regex: search, $options: 'i' } },
        { author: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } }
      ];
    }
    
    const skip = (page - 1) * pageSize;
    const books = await Book.find(query)
      .skip(skip)
      .limit(pageSize);
    
    const totalCount = await Book.countDocuments(query);
    const hasMore = skip + books.length < totalCount;
    
    res.json({
      data: books,
      total_count: totalCount,
      has_more: hasMore,
      current_page: page,
      page_size: pageSize
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
from fastapi import FastAPI, Query
from typing import Optional

app = FastAPI()

@app.get("/api/books/today-deals")
async def get_today_deals():
    books = await Book.filter(
        discount__gte=30,
        is_available=True
    ).limit(6)
    
    return {
        "data": books,
        "total_count": len(books),
        "has_more": False
    }

@app.get("/api/books")
async def get_books(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    category: Optional[str] = None,
    search: Optional[str] = None
):
    query = {"is_available": True}
    
    if category:
        query["category"] = category
    
    if search:
        query["$or"] = [
            {"title": {"$regex": search, "$options": "i"}},
            {"author": {"$regex": search, "$options": "i"}},
            {"description": {"$regex": search, "$options": "i"}}
        ]
    
    skip = (page - 1) * page_size
    books = await Book.find(query).skip(skip).limit(page_size)
    total_count = await Book.count_documents(query)
    has_more = skip + len(books) < total_count
    
    return {
        "data": books,
        "total_count": total_count,
        "has_more": has_more,
        "current_page": page,
        "page_size": page_size
    }
```

## 8. 資料庫設計建議

### MongoDB 文檔結構

```javascript
{
  "_id": ObjectId("..."),
  "id": "1",
  "title": "Flutter開發實戰",
  "author": "張三",
  "description": "這是一本關於Flutter開發的實戰指南...",
  "price": 599.0,
  "original_price": 599.0,
  "discount": 0,
  "imageUrl": "https://picsum.photos/300/400?random=1",
  "category": "程式設計",
  "rating": 4.8,
  "reviewCount": 128,
  "isAvailable": true,
  "publishDate": ISODate("2024-01-15T00:00:00Z"),
  "isbn": "9781234567890",
  "pages": 350,
  "publisher": "科技出版社",
  "createdAt": ISODate("2024-01-01T00:00:00Z"),
  "updatedAt": ISODate("2024-01-01T00:00:00Z"),
  "tags": ["flutter", "mobile", "development"],
  "is_new": false,
  "is_used": false,
  "condition": "全新",
  "sales_rank": 0
}
```

### 索引建議

```javascript
// 複合索引
db.books.createIndex({ "category": 1, "isAvailable": 1 })
db.books.createIndex({ "rating": -1, "reviewCount": -1 })
db.books.createIndex({ "publishDate": -1 })
db.books.createIndex({ "price": 1 })
db.books.createIndex({ "discount": -1 })

// 文字搜尋索引
db.books.createIndex({ 
  "title": "text", 
  "author": "text", 
  "description": "text" 
})
```

## 9. 快取策略

### Redis 快取示例

```javascript
// 快取今日特惠
const cacheKey = 'today_deals';
const cachedData = await redis.get(cacheKey);

if (cachedData) {
  return JSON.parse(cachedData);
}

const books = await Book.find({ discount: { $gte: 30 } });
const result = {
  data: books,
  total_count: books.length,
  has_more: false
};

// 快取1小時
await redis.setex(cacheKey, 3600, JSON.stringify(result));
return result;
```

## 10. 性能優化建議

1. **分頁查詢**: 使用 `skip()` 和 `limit()` 進行分頁
2. **索引優化**: 為常用查詢字段建立索引
3. **快取策略**: 對熱門數據進行快取
4. **CDN**: 圖片使用CDN加速
5. **資料庫連接池**: 使用連接池管理資料庫連接
6. **API限流**: 實施API調用頻率限制
7. **壓縮**: 啟用Gzip壓縮減少傳輸大小
