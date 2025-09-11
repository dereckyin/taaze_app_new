# FastAPI 快速開始指南

## 1. 快速安裝和運行

### 1.1 創建項目目錄
```bash
mkdir fastapi_captcha_auth
cd fastapi_captcha_auth
```

### 1.2 安裝依賴
```bash
pip install fastapi uvicorn pillow redis python-jose[cryptography] passlib[bcrypt] python-multipart
```

### 1.3 創建最小化實現
```python
# main.py
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr
from typing import Optional
import uuid
import random
import string
import time
from PIL import Image, ImageDraw, ImageFont
import io
import base64
import redis
import json

app = FastAPI(title="FastAPI Captcha Auth")

# CORS設置
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Redis連接（如果沒有Redis，會使用內存存儲）
try:
    redis_client = redis.Redis(host='localhost', port=6379, db=0, decode_responses=True)
    redis_client.ping()
    USE_REDIS = True
except:
    USE_REDIS = False
    memory_store = {}

# 數據模型
class LoginRequest(BaseModel):
    email: EmailStr
    password: str
    captcha_id: Optional[str] = None
    captcha_code: Optional[str] = None

class LoginResponse(BaseModel):
    success: bool
    token: Optional[str] = None
    user: Optional[dict] = None
    error: Optional[str] = None
    captcha_required: bool = False
    captcha: Optional[dict] = None

class CaptchaResponse(BaseModel):
    captcha_id: str
    captcha_image: str
    captcha_text: Optional[str] = None
    required: bool = True

# 驗證碼服務
class CaptchaService:
    def generate_random_string(self, length=4):
        return ''.join(random.choices(string.ascii_uppercase + string.digits, k=length))
    
    def generate_captcha_image(self, text):
        width, height = 120, 50
        image = Image.new('RGB', (width, height), color='#f0f0f0')
        draw = ImageDraw.Draw(image)
        
        # 干擾線
        for _ in range(5):
            x1, y1 = random.randint(0, width), random.randint(0, height)
            x2, y2 = random.randint(0, width), random.randint(0, height)
            color = (random.randint(0, 255), random.randint(0, 255), random.randint(0, 255))
            draw.line([(x1, y1), (x2, y2)], fill=color, width=1)
        
        # 文字
        try:
            font = ImageFont.truetype("arial.ttf", 20)
        except:
            font = ImageFont.load_default()
        
        for i, char in enumerate(text):
            x = (width / len(text)) * (i + 0.5)
            y = height / 2 + random.randint(-10, 10)
            color = (random.randint(0, 100), random.randint(0, 100), random.randint(0, 100))
            draw.text((x, y), char, font=font, fill=color, anchor="mm")
        
        # 轉換為base64
        buffer = io.BytesIO()
        image.save(buffer, format='PNG')
        img_str = base64.b64encode(buffer.getvalue()).decode()
        return f"data:image/png;base64,{img_str}"
    
    def create_captcha(self):
        captcha_id = str(uuid.uuid4())
        captcha_text = self.generate_random_string(4)
        captcha_image = self.generate_captcha_image(captcha_text)
        
        # 存儲驗證碼
        captcha_data = {
            'text': captcha_text,
            'created_at': time.time(),
            'attempts': 0
        }
        
        if USE_REDIS:
            redis_client.setex(f"captcha:{captcha_id}", 300, json.dumps(captcha_data))
        else:
            memory_store[f"captcha:{captcha_id}"] = captcha_data
        
        return {
            'captcha_id': captcha_id,
            'captcha_image': captcha_image,
            'captcha_text': captcha_text,  # 僅用於測試
            'required': True
        }
    
    def verify_captcha(self, captcha_id, user_input):
        if USE_REDIS:
            captcha_data_str = redis_client.get(f"captcha:{captcha_id}")
            if not captcha_data_str:
                return {'valid': False, 'error': '驗證碼不存在或已過期'}
            captcha_data = json.loads(captcha_data_str)
        else:
            captcha_data = memory_store.get(f"captcha:{captcha_id}")
            if not captcha_data:
                return {'valid': False, 'error': '驗證碼不存在或已過期'}
        
        # 檢查是否過期（5分鐘）
        if time.time() - captcha_data['created_at'] > 300:
            if USE_REDIS:
                redis_client.delete(f"captcha:{captcha_id}")
            else:
                memory_store.pop(f"captcha:{captcha_id}", None)
            return {'valid': False, 'error': '驗證碼已過期'}
        
        # 檢查嘗試次數
        if captcha_data['attempts'] >= 3:
            if USE_REDIS:
                redis_client.delete(f"captcha:{captcha_id}")
            else:
                memory_store.pop(f"captcha:{captcha_id}", None)
            return {'valid': False, 'error': '驗證碼嘗試次數過多'}
        
        captcha_data['attempts'] += 1
        
        if USE_REDIS:
            redis_client.setex(f"captcha:{captcha_id}", 300, json.dumps(captcha_data))
        else:
            memory_store[f"captcha:{captcha_id}"] = captcha_data
        
        if captcha_data['text'].upper() == user_input.upper():
            if USE_REDIS:
                redis_client.delete(f"captcha:{captcha_id}")
            else:
                memory_store.pop(f"captcha:{captcha_id}", None)
            return {'valid': True}
        else:
            return {'valid': False, 'error': '驗證碼錯誤'}

captcha_service = CaptchaService()

# 登入嘗試記錄
login_attempts = {}

def record_login_attempt(email, ip, success):
    key = f"{email}:{ip}"
    current_time = time.time()
    
    if key not in login_attempts:
        login_attempts[key] = {
            'attempts': [],
            'locked': False,
            'lock_until': None
        }
    
    user_attempts = login_attempts[key]
    user_attempts['attempts'].append({
        'timestamp': current_time,
        'success': success
    })
    
    # 清理舊的嘗試記錄
    user_attempts['attempts'] = [
        attempt for attempt in user_attempts['attempts']
        if current_time - attempt['timestamp'] < 3600
    ]
    
    # 檢查是否需要鎖定
    recent_failed_attempts = [
        attempt for attempt in user_attempts['attempts']
        if not attempt['success'] and current_time - attempt['timestamp'] < 900
    ]
    
    if len(recent_failed_attempts) >= 5:
        user_attempts['locked'] = True
        user_attempts['lock_until'] = current_time + 900
    
    if success:
        del login_attempts[key]

def is_locked(email, ip):
    key = f"{email}:{ip}"
    if key not in login_attempts:
        return False
    
    user_attempts = login_attempts[key]
    if not user_attempts['locked']:
        return False
    
    current_time = time.time()
    if current_time > user_attempts['lock_until']:
        user_attempts['locked'] = False
        user_attempts['lock_until'] = None
        return False
    
    return True

def should_require_captcha(email, ip):
    key = f"{email}:{ip}"
    if key not in login_attempts:
        return False
    
    current_time = time.time()
    recent_failed_attempts = [
        attempt for attempt in login_attempts[key]['attempts']
        if not attempt['success'] and current_time - attempt['timestamp'] < 900
    ]
    
    return len(recent_failed_attempts) >= 2

def validate_user_credentials(email, password):
    # 模擬用戶數據
    valid_users = {
        'test@example.com': 'password123',
        'admin@example.com': 'admin123',
        'user@example.com': 'user123'
    }
    return valid_users.get(email) == password

# API路由
@app.get("/")
async def root():
    return {"message": "FastAPI Captcha Auth API", "redis": USE_REDIS}

@app.get("/api/v1/auth/captcha", response_model=CaptchaResponse)
async def get_captcha():
    try:
        captcha_data = captcha_service.create_captcha()
        return CaptchaResponse(**captcha_data)
    except Exception as e:
        raise HTTPException(status_code=500, detail="生成驗證碼失敗")

@app.post("/api/v1/auth/captcha/refresh", response_model=CaptchaResponse)
async def refresh_captcha(request_data: dict):
    try:
        captcha_id = request_data.get('captchaId')
        if captcha_id:
            if USE_REDIS:
                redis_client.delete(f"captcha:{captcha_id}")
            else:
                memory_store.pop(f"captcha:{captcha_id}", None)
        
        captcha_data = captcha_service.create_captcha()
        return CaptchaResponse(**captcha_data)
    except Exception as e:
        raise HTTPException(status_code=500, detail="刷新驗證碼失敗")

@app.post("/api/v1/auth/login", response_model=LoginResponse)
async def login(request: Request, login_data: LoginRequest):
    try:
        client_ip = request.client.host
        
        # 檢查是否被鎖定
        if is_locked(login_data.email, client_ip):
            return LoginResponse(
                success=False,
                error="帳戶已被鎖定，請稍後再試"
            )
        
        # 檢查是否需要驗證碼
        requires_captcha = should_require_captcha(login_data.email, client_ip)
        
        if requires_captcha:
            if not login_data.captcha_id or not login_data.captcha_code:
                captcha_data = captcha_service.create_captcha()
                return LoginResponse(
                    success=False,
                    error="需要驗證碼",
                    captcha_required=True,
                    captcha=captcha_data
                )
            
            # 驗證驗證碼
            captcha_result = captcha_service.verify_captcha(
                login_data.captcha_id,
                login_data.captcha_code
            )
            
            if not captcha_result['valid']:
                captcha_data = captcha_service.create_captcha()
                return LoginResponse(
                    success=False,
                    error=captcha_result['error'],
                    captcha_required=True,
                    captcha=captcha_data
                )
        
        # 驗證用戶憑證
        if validate_user_credentials(login_data.email, login_data.password):
            # 登入成功
            record_login_attempt(login_data.email, client_ip, True)
            
            return LoginResponse(
                success=True,
                token="mock-jwt-token",
                user={
                    'id': '1',
                    'email': login_data.email,
                    'name': login_data.email.split('@')[0],
                    'created_at': time.strftime('%Y-%m-%dT%H:%M:%S.000Z'),
                    'last_login_at': time.strftime('%Y-%m-%dT%H:%M:%S.000Z')
                }
            )
        else:
            # 登入失敗
            record_login_attempt(login_data.email, client_ip, False)
            
            requires_captcha = should_require_captcha(login_data.email, client_ip)
            captcha_data = None
            
            if requires_captcha:
                captcha_data = captcha_service.create_captcha()
            
            return LoginResponse(
                success=False,
                error="電子郵件或密碼錯誤",
                captcha_required=requires_captcha,
                captcha=captcha_data
            )
            
    except Exception as e:
        raise HTTPException(status_code=500, detail="登入失敗")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

### 1.4 運行服務
```bash
python main.py
```

## 2. 測試API

### 2.1 獲取驗證碼
```bash
curl -X GET "http://localhost:8000/api/v1/auth/captcha"
```

### 2.2 登入測試
```bash
# 正常登入
curl -X POST "http://localhost:8000/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'

# 錯誤密碼（會觸發驗證碼）
curl -X POST "http://localhost:8000/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "wrongpassword"
  }'
```

## 3. 更新Flutter配置

### 3.1 修改API地址
```dart
// lib/services/auth_api_service.dart
class AuthApiService {
  static const String baseUrl = 'http://localhost:8000/api/v1';  // 更新為FastAPI地址
  // 其他代碼保持不變...
}
```

### 3.2 測試Flutter應用
```bash
flutter run
```

## 4. 可選：安裝Redis（推薦）

### 4.1 安裝Redis
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install redis-server

# macOS
brew install redis

# Windows
# 下載並安裝Redis for Windows
```

### 4.2 啟動Redis
```bash
redis-server
```

### 4.3 驗證Redis連接
```bash
redis-cli ping
# 應該返回 PONG
```

## 5. 生產環境部署

### 5.1 使用Gunicorn
```bash
pip install gunicorn
gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

### 5.2 使用Docker
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY main.py .

EXPOSE 8000

CMD ["gunicorn", "main:app", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8000"]
```

## 6. API文檔

啟動服務後訪問：
- http://localhost:8000/docs (Swagger UI)
- http://localhost:8000/redoc (ReDoc)

## 7. 測試帳戶

- `test@example.com` / `password123`
- `admin@example.com` / `admin123`
- `user@example.com` / `user123`

這個快速開始指南提供了一個最小化的FastAPI實現，包含了所有核心功能：
- 驗證碼生成和驗證
- 登入嘗試限制
- 帳戶鎖定機制
- 與Flutter應用的整合

您可以根據需要進一步擴展和定制這個實現。
