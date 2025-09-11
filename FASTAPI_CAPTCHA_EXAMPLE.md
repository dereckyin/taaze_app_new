# FastAPI 驗證碼實現示例

## 概述
本文檔提供使用FastAPI實現驗證碼驗證的完整示例，包括依賴安裝、代碼實現和部署配置。

## 1. 環境準備

### 1.1 依賴安裝
```bash
# 創建虛擬環境
python -m venv venv
source venv/bin/activate  # Linux/Mac
# 或
venv\Scripts\activate  # Windows

# 安裝依賴
pip install fastapi uvicorn python-multipart
pip install pillow redis python-jose[cryptography]
pip install passlib[bcrypt] python-decouple
pip install httpx  # 用於測試
```

### 1.2 requirements.txt
```txt
fastapi==0.104.1
uvicorn[standard]==0.24.0
python-multipart==0.0.6
pillow==10.1.0
redis==5.0.1
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-decouple==3.8
httpx==0.25.2
pydantic==2.5.0
```

## 2. 項目結構
```
fastapi_captcha/
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── config.py
│   ├── models/
│   │   ├── __init__.py
│   │   ├── auth.py
│   │   └── captcha.py
│   ├── services/
│   │   ├── __init__.py
│   │   ├── captcha_service.py
│   │   ├── auth_service.py
│   │   └── redis_service.py
│   ├── routers/
│   │   ├── __init__.py
│   │   └── auth.py
│   └── utils/
│       ├── __init__.py
│       ├── security.py
│       └── rate_limiter.py
├── tests/
│   ├── __init__.py
│   └── test_auth.py
├── .env
├── requirements.txt
└── README.md
```

## 3. 核心實現

### 3.1 配置文件
```python
# app/config.py
from decouple import config
from typing import Optional

class Settings:
    # API配置
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "FastAPI Captcha Auth"
    
    # 安全配置
    SECRET_KEY: str = config("SECRET_KEY", default="your-secret-key-here")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    
    # 驗證碼配置
    CAPTCHA_EXPIRE_SECONDS: int = 300  # 5分鐘
    CAPTCHA_MAX_ATTEMPTS: int = 3
    CAPTCHA_LENGTH: int = 4
    
    # 登入限制配置
    MAX_LOGIN_ATTEMPTS: int = 5
    LOCKOUT_DURATION_SECONDS: int = 900  # 15分鐘
    RATE_LIMIT_WINDOW_SECONDS: int = 900  # 15分鐘
    RATE_LIMIT_MAX_ATTEMPTS: int = 5
    
    # Redis配置
    REDIS_HOST: str = config("REDIS_HOST", default="localhost")
    REDIS_PORT: int = config("REDIS_PORT", default=6379)
    REDIS_PASSWORD: Optional[str] = config("REDIS_PASSWORD", default=None)
    REDIS_DB: int = config("REDIS_DB", default=0)
    
    # 數據庫配置（如果需要）
    DATABASE_URL: Optional[str] = config("DATABASE_URL", default=None)

settings = Settings()
```

### 3.2 數據模型
```python
# app/models/auth.py
from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime

class LoginRequest(BaseModel):
    email: EmailStr
    password: str
    captcha_id: Optional[str] = None
    captcha_code: Optional[str] = None

class LoginResponse(BaseModel):
    success: bool
    token: Optional[str] = None
    refresh_token: Optional[str] = None
    user: Optional[dict] = None
    error: Optional[str] = None
    captcha_required: bool = False
    captcha: Optional[dict] = None

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    name: str

class UserResponse(BaseModel):
    id: str
    email: str
    name: str
    avatar: Optional[str] = None
    created_at: datetime
    last_login_at: datetime

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
```

```python
# app/models/captcha.py
from pydantic import BaseModel
from typing import Optional

class CaptchaResponse(BaseModel):
    captcha_id: str
    captcha_image: str
    captcha_text: Optional[str] = None  # 僅用於測試
    required: bool = True
    message: Optional[str] = None

class CaptchaRefreshRequest(BaseModel):
    captcha_id: str
```

### 3.3 Redis服務
```python
# app/services/redis_service.py
import redis
import json
from typing import Optional, Any
from app.config import settings

class RedisService:
    def __init__(self):
        self.redis_client = redis.Redis(
            host=settings.REDIS_HOST,
            port=settings.REDIS_PORT,
            password=settings.REDIS_PASSWORD,
            db=settings.REDIS_DB,
            decode_responses=True
        )
    
    async def set(self, key: str, value: Any, expire: Optional[int] = None) -> bool:
        """設置鍵值對"""
        try:
            if isinstance(value, (dict, list)):
                value = json.dumps(value)
            return self.redis_client.set(key, value, ex=expire)
        except Exception as e:
            print(f"Redis set error: {e}")
            return False
    
    async def get(self, key: str) -> Optional[Any]:
        """獲取值"""
        try:
            value = self.redis_client.get(key)
            if value is None:
                return None
            try:
                return json.loads(value)
            except json.JSONDecodeError:
                return value
        except Exception as e:
            print(f"Redis get error: {e}")
            return None
    
    async def delete(self, key: str) -> bool:
        """刪除鍵"""
        try:
            return bool(self.redis_client.delete(key))
        except Exception as e:
            print(f"Redis delete error: {e}")
            return False
    
    async def exists(self, key: str) -> bool:
        """檢查鍵是否存在"""
        try:
            return bool(self.redis_client.exists(key))
        except Exception as e:
            print(f"Redis exists error: {e}")
            return False
    
    async def increment(self, key: str, expire: Optional[int] = None) -> int:
        """遞增計數器"""
        try:
            count = self.redis_client.incr(key)
            if expire and count == 1:
                self.redis_client.expire(key, expire)
            return count
        except Exception as e:
            print(f"Redis increment error: {e}")
            return 0

redis_service = RedisService()
```

### 3.4 驗證碼服務
```python
# app/services/captcha_service.py
import uuid
import random
import string
import time
from PIL import Image, ImageDraw, ImageFont
import io
import base64
from typing import Dict, Any
from app.services.redis_service import redis_service
from app.config import settings

class CaptchaService:
    def __init__(self):
        self.captcha_store = {}  # 備用存儲（如果Redis不可用）
    
    def generate_random_string(self, length: int = None) -> str:
        """生成隨機字符串"""
        if length is None:
            length = settings.CAPTCHA_LENGTH
        return ''.join(random.choices(string.ascii_uppercase + string.digits, k=length))
    
    def generate_captcha_image(self, text: str) -> str:
        """生成驗證碼圖片"""
        width, height = 120, 50
        image = Image.new('RGB', (width, height), color='#f0f0f0')
        draw = ImageDraw.Draw(image)
        
        # 干擾線
        for _ in range(5):
            x1 = random.randint(0, width)
            y1 = random.randint(0, height)
            x2 = random.randint(0, width)
            y2 = random.randint(0, height)
            color = (random.randint(0, 255), random.randint(0, 255), random.randint(0, 255))
            draw.line([(x1, y1), (x2, y2)], fill=color, width=1)
        
        # 干擾點
        for _ in range(50):
            x = random.randint(0, width)
            y = random.randint(0, height)
            color = (random.randint(0, 255), random.randint(0, 255), random.randint(0, 255))
            draw.point((x, y), fill=color)
        
        # 文字
        try:
            # 嘗試使用系統字體
            font = ImageFont.truetype("arial.ttf", 20)
        except:
            try:
                font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", 20)
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
    
    async def create_captcha(self) -> Dict[str, Any]:
        """創建驗證碼"""
        captcha_id = str(uuid.uuid4())
        captcha_text = self.generate_random_string()
        captcha_image = self.generate_captcha_image(captcha_text)
        
        # 存儲驗證碼到Redis
        captcha_data = {
            'text': captcha_text,
            'created_at': time.time(),
            'attempts': 0
        }
        
        await redis_service.set(
            f"captcha:{captcha_id}",
            captcha_data,
            expire=settings.CAPTCHA_EXPIRE_SECONDS
        )
        
        # 清理過期驗證碼
        await self.cleanup_expired_captchas()
        
        return {
            'captcha_id': captcha_id,
            'captcha_image': captcha_image,
            'captcha_text': captcha_text,  # 僅用於測試
            'required': True
        }
    
    async def verify_captcha(self, captcha_id: str, user_input: str) -> Dict[str, Any]:
        """驗證驗證碼"""
        captcha_data = await redis_service.get(f"captcha:{captcha_id}")
        
        if not captcha_data:
            return {'valid': False, 'error': '驗證碼不存在或已過期'}
        
        # 檢查是否過期
        if time.time() - captcha_data['created_at'] > settings.CAPTCHA_EXPIRE_SECONDS:
            await redis_service.delete(f"captcha:{captcha_id}")
            return {'valid': False, 'error': '驗證碼已過期'}
        
        # 檢查嘗試次數
        if captcha_data['attempts'] >= settings.CAPTCHA_MAX_ATTEMPTS:
            await redis_service.delete(f"captcha:{captcha_id}")
            return {'valid': False, 'error': '驗證碼嘗試次數過多'}
        
        # 增加嘗試次數
        captcha_data['attempts'] += 1
        await redis_service.set(
            f"captcha:{captcha_id}",
            captcha_data,
            expire=settings.CAPTCHA_EXPIRE_SECONDS
        )
        
        if captcha_data['text'].upper() == user_input.upper():
            await redis_service.delete(f"captcha:{captcha_id}")
            return {'valid': True}
        else:
            return {'valid': False, 'error': '驗證碼錯誤'}
    
    async def cleanup_expired_captchas(self):
        """清理過期驗證碼"""
        # Redis會自動過期，這裡可以添加額外的清理邏輯
        pass

captcha_service = CaptchaService()
```

### 3.5 認證服務
```python
# app/services/auth_service.py
import time
from typing import Dict, Any, Optional
from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta
from app.services.redis_service import redis_service
from app.services.captcha_service import captcha_service
from app.config import settings

# 密碼加密
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class AuthService:
    def __init__(self):
        pass
    
    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        """驗證密碼"""
        return pwd_context.verify(plain_password, hashed_password)
    
    def get_password_hash(self, password: str) -> str:
        """生成密碼哈希"""
        return pwd_context.hash(password)
    
    def create_access_token(self, data: dict, expires_delta: Optional[timedelta] = None) -> str:
        """創建訪問令牌"""
        to_encode = data.copy()
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        
        to_encode.update({"exp": expire})
        encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
        return encoded_jwt
    
    def create_refresh_token(self, data: dict) -> str:
        """創建刷新令牌"""
        to_encode = data.copy()
        expire = datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
        to_encode.update({"exp": expire, "type": "refresh"})
        encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
        return encoded_jwt
    
    async def record_login_attempt(self, email: str, ip: str, success: bool):
        """記錄登入嘗試"""
        key = f"login_attempts:{email}:{ip}"
        current_time = time.time()
        
        attempts_data = await redis_service.get(key) or {
            'attempts': [],
            'locked': False,
            'lock_until': None
        }
        
        attempts_data['attempts'].append({
            'timestamp': current_time,
            'success': success
        })
        
        # 清理舊的嘗試記錄（保留最近1小時）
        attempts_data['attempts'] = [
            attempt for attempt in attempts_data['attempts']
            if current_time - attempt['timestamp'] < 3600
        ]
        
        # 檢查是否需要鎖定
        recent_failed_attempts = [
            attempt for attempt in attempts_data['attempts']
            if not attempt['success'] and current_time - attempt['timestamp'] < settings.LOCKOUT_DURATION_SECONDS
        ]
        
        if len(recent_failed_attempts) >= settings.MAX_LOGIN_ATTEMPTS:
            attempts_data['locked'] = True
            attempts_data['lock_until'] = current_time + settings.LOCKOUT_DURATION_SECONDS
        
        # 如果登入成功，重置嘗試記錄
        if success:
            await redis_service.delete(key)
        else:
            await redis_service.set(key, attempts_data, expire=3600)
    
    async def is_locked(self, email: str, ip: str) -> bool:
        """檢查是否被鎖定"""
        key = f"login_attempts:{email}:{ip}"
        attempts_data = await redis_service.get(key)
        
        if not attempts_data or not attempts_data.get('locked'):
            return False
        
        current_time = time.time()
        if current_time > attempts_data['lock_until']:
            attempts_data['locked'] = False
            attempts_data['lock_until'] = None
            await redis_service.set(key, attempts_data, expire=3600)
            return False
        
        return True
    
    async def get_lockout_remaining_time(self, email: str, ip: str) -> int:
        """獲取鎖定剩餘時間"""
        key = f"login_attempts:{email}:{ip}"
        attempts_data = await redis_service.get(key)
        
        if not attempts_data or not attempts_data.get('locked'):
            return 0
        
        current_time = time.time()
        return max(0, int(attempts_data['lock_until'] - current_time))
    
    async def should_require_captcha(self, email: str, ip: str) -> bool:
        """檢查是否需要驗證碼"""
        key = f"login_attempts:{email}:{ip}"
        attempts_data = await redis_service.get(key)
        
        if not attempts_data:
            return False
        
        current_time = time.time()
        recent_failed_attempts = [
            attempt for attempt in attempts_data['attempts']
            if not attempt['success'] and current_time - attempt['timestamp'] < settings.LOCKOUT_DURATION_SECONDS
        ]
        
        return len(recent_failed_attempts) >= 2
    
    async def validate_user_credentials(self, email: str, password: str) -> Optional[Dict[str, Any]]:
        """驗證用戶憑證"""
        # 這裡應該查詢數據庫
        # 示例：模擬用戶數據
        valid_users = {
            'test@example.com': {
                'id': '1',
                'email': 'test@example.com',
                'name': 'Test User',
                'password_hash': self.get_password_hash('password123'),
                'avatar': None,
                'created_at': datetime.now(),
                'last_login_at': datetime.now()
            },
            'admin@example.com': {
                'id': '2',
                'email': 'admin@example.com',
                'name': 'Admin User',
                'password_hash': self.get_password_hash('admin123'),
                'avatar': None,
                'created_at': datetime.now(),
                'last_login_at': datetime.now()
            }
        }
        
        user = valid_users.get(email)
        if user and self.verify_password(password, user['password_hash']):
            return user
        
        return None

auth_service = AuthService()
```

### 3.6 速率限制器
```python
# app/utils/rate_limiter.py
import time
from typing import Dict, Any
from fastapi import Request, HTTPException
from app.services.redis_service import redis_service
from app.config import settings

class RateLimiter:
    def __init__(self):
        pass
    
    async def check_rate_limit(self, request: Request, identifier: str = None) -> bool:
        """檢查速率限制"""
        if identifier is None:
            identifier = request.client.host
        
        key = f"rate_limit:{identifier}"
        current_time = time.time()
        
        # 獲取當前請求記錄
        requests = await redis_service.get(key) or []
        
        # 清理過期的請求記錄
        requests = [
            req_time for req_time in requests
            if current_time - req_time < settings.RATE_LIMIT_WINDOW_SECONDS
        ]
        
        # 檢查是否超過限制
        if len(requests) >= settings.RATE_LIMIT_MAX_ATTEMPTS:
            return False
        
        # 記錄當前請求
        requests.append(current_time)
        await redis_service.set(
            key,
            requests,
            expire=settings.RATE_LIMIT_WINDOW_SECONDS
        )
        
        return True
    
    async def get_remaining_attempts(self, request: Request, identifier: str = None) -> int:
        """獲取剩餘嘗試次數"""
        if identifier is None:
            identifier = request.client.host
        
        key = f"rate_limit:{identifier}"
        requests = await redis_service.get(key) or []
        
        current_time = time.time()
        valid_requests = [
            req_time for req_time in requests
            if current_time - req_time < settings.RATE_LIMIT_WINDOW_SECONDS
        ]
        
        return max(0, settings.RATE_LIMIT_MAX_ATTEMPTS - len(valid_requests))

rate_limiter = RateLimiter()
```

### 3.7 安全工具
```python
# app/utils/security.py
from jose import JWTError, jwt
from fastapi import HTTPException, status
from app.config import settings

def verify_token(token: str) -> dict:
    """驗證JWT令牌"""
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        return payload
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="無效的令牌",
            headers={"WWW-Authenticate": "Bearer"},
        )

def get_current_user(token: str) -> dict:
    """獲取當前用戶"""
    payload = verify_token(token)
    user_id = payload.get("sub")
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="無效的令牌",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return payload
```

### 3.8 API路由
```python
# app/routers/auth.py
from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Dict, Any
from app.models.auth import LoginRequest, LoginResponse, RegisterRequest
from app.models.captcha import CaptchaResponse, CaptchaRefreshRequest
from app.services.auth_service import auth_service
from app.services.captcha_service import captcha_service
from app.utils.rate_limiter import rate_limiter
from app.utils.security import verify_token

router = APIRouter(prefix="/auth", tags=["認證"])
security = HTTPBearer()

@router.get("/captcha", response_model=CaptchaResponse)
async def get_captcha():
    """獲取驗證碼"""
    try:
        captcha_data = await captcha_service.create_captcha()
        return CaptchaResponse(**captcha_data)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="生成驗證碼失敗"
        )

@router.post("/captcha/refresh", response_model=CaptchaResponse)
async def refresh_captcha(request_data: CaptchaRefreshRequest):
    """刷新驗證碼"""
    try:
        # 刪除舊驗證碼
        await redis_service.delete(f"captcha:{request_data.captcha_id}")
        
        # 生成新驗證碼
        captcha_data = await captcha_service.create_captcha()
        return CaptchaResponse(**captcha_data)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="刷新驗證碼失敗"
        )

@router.post("/login", response_model=LoginResponse)
async def login(request: Request, login_data: LoginRequest):
    """用戶登入"""
    try:
        client_ip = request.client.host
        
        # 檢查速率限制
        if not await rate_limiter.check_rate_limit(request):
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="請求過於頻繁，請稍後再試"
            )
        
        # 檢查是否被鎖定
        if await auth_service.is_locked(login_data.email, client_ip):
            remaining_time = await auth_service.get_lockout_remaining_time(login_data.email, client_ip)
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"帳戶已被鎖定，剩餘時間：{remaining_time}秒"
            )
        
        # 檢查是否需要驗證碼
        requires_captcha = await auth_service.should_require_captcha(login_data.email, client_ip)
        
        if requires_captcha:
            if not login_data.captcha_id or not login_data.captcha_code:
                captcha_data = await captcha_service.create_captcha()
                return LoginResponse(
                    success=False,
                    error="需要驗證碼",
                    captcha_required=True,
                    captcha=captcha_data
                )
            
            # 驗證驗證碼
            captcha_result = await captcha_service.verify_captcha(
                login_data.captcha_id,
                login_data.captcha_code
            )
            
            if not captcha_result['valid']:
                captcha_data = await captcha_service.create_captcha()
                return LoginResponse(
                    success=False,
                    error=captcha_result['error'],
                    captcha_required=True,
                    captcha=captcha_data
                )
        
        # 驗證用戶憑證
        user = await auth_service.validate_user_credentials(
            login_data.email,
            login_data.password
        )
        
        if user:
            # 登入成功
            await auth_service.record_login_attempt(login_data.email, client_ip, True)
            
            # 生成令牌
            access_token = auth_service.create_access_token(data={"sub": user['id']})
            refresh_token = auth_service.create_refresh_token(data={"sub": user['id']})
            
            return LoginResponse(
                success=True,
                token=access_token,
                refresh_token=refresh_token,
                user={
                    'id': user['id'],
                    'email': user['email'],
                    'name': user['name'],
                    'avatar': user['avatar'],
                    'created_at': user['created_at'].isoformat(),
                    'last_login_at': user['last_login_at'].isoformat()
                }
            )
        else:
            # 登入失敗
            await auth_service.record_login_attempt(login_data.email, client_ip, False)
            
            requires_captcha = await auth_service.should_require_captcha(login_data.email, client_ip)
            captcha_data = None
            
            if requires_captcha:
                captcha_data = await captcha_service.create_captcha()
            
            return LoginResponse(
                success=False,
                error="電子郵件或密碼錯誤",
                captcha_required=requires_captcha,
                captcha=captcha_data
            )
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="登入失敗"
        )

@router.post("/register", response_model=LoginResponse)
async def register(register_data: RegisterRequest):
    """用戶註冊"""
    try:
        # 這裡應該實現註冊邏輯
        # 檢查用戶是否已存在
        # 創建新用戶
        # 返回登入響應
        
        return LoginResponse(
            success=False,
            error="註冊功能尚未實現"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="註冊失敗"
        )

@router.post("/logout")
async def logout(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """用戶登出"""
    try:
        # 驗證令牌
        payload = verify_token(credentials.credentials)
        
        # 這裡可以將令牌加入黑名單
        # 或者清除相關的會話數據
        
        return {"message": "登出成功"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="登出失敗"
        )

@router.post("/refresh", response_model=Dict[str, str])
async def refresh_token(refresh_data: Dict[str, str]):
    """刷新令牌"""
    try:
        refresh_token = refresh_data.get("refresh_token")
        if not refresh_token:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="缺少刷新令牌"
            )
        
        # 驗證刷新令牌
        payload = verify_token(refresh_token)
        
        if payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="無效的刷新令牌"
            )
        
        # 生成新的訪問令牌
        new_access_token = auth_service.create_access_token(data={"sub": payload["sub"]})
        
        return {
            "access_token": new_access_token,
            "token_type": "bearer"
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="刷新令牌失敗"
        )
```

### 3.9 主應用
```python
# app/main.py
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse
from app.routers import auth
from app.config import settings
import time

app = FastAPI(
    title=settings.PROJECT_NAME,
    version="1.0.0",
    description="FastAPI驗證碼認證系統"
)

# CORS中間件
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 生產環境應該設置具體的域名
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 信任主機中間件
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["*"]  # 生產環境應該設置具體的主機
)

# 請求時間中間件
@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    return response

# 異常處理
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=500,
        content={"detail": "內部服務器錯誤"}
    )

# 包含路由
app.include_router(auth.router, prefix=settings.API_V1_STR)

# 健康檢查
@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": time.time()}

# 根路徑
@app.get("/")
async def root():
    return {
        "message": "FastAPI驗證碼認證系統",
        "version": "1.0.0",
        "docs": "/docs"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
```

## 4. 環境配置

### 4.1 .env文件
```bash
# .env
SECRET_KEY=your-super-secret-key-here-change-in-production
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0
DATABASE_URL=sqlite:///./app.db
```

### 4.2 啟動腳本
```bash
# start.sh
#!/bin/bash
export SECRET_KEY="your-super-secret-key-here"
export REDIS_HOST="localhost"
export REDIS_PORT="6379"

# 啟動Redis（如果沒有運行）
redis-server --daemonize yes

# 啟動FastAPI應用
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

## 5. 測試

### 5.1 單元測試
```python
# tests/test_auth.py
import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_get_captcha():
    response = client.get("/api/v1/auth/captcha")
    assert response.status_code == 200
    data = response.json()
    assert "captcha_id" in data
    assert "captcha_image" in data

def test_login_without_captcha():
    response = client.post("/api/v1/auth/login", json={
        "email": "test@example.com",
        "password": "password123"
    })
    assert response.status_code == 200
    data = response.json()
    assert data["success"] == True

def test_login_with_wrong_password():
    response = client.post("/api/v1/auth/login", json={
        "email": "test@example.com",
        "password": "wrongpassword"
    })
    assert response.status_code == 200
    data = response.json()
    assert data["success"] == False
```

### 5.2 運行測試
```bash
# 安裝測試依賴
pip install pytest pytest-asyncio httpx

# 運行測試
pytest tests/ -v
```

## 6. 部署

### 6.1 Docker部署
```dockerfile
# Dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  api:
    build: .
    ports:
      - "8000:8000"
    environment:
      - REDIS_HOST=redis
      - REDIS_PORT=6379
    depends_on:
      - redis

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

volumes:
  redis_data:
```

### 6.2 生產環境配置
```bash
# 使用Gunicorn部署
pip install gunicorn

# 啟動命令
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

## 7. API文檔

啟動服務後，訪問以下URL查看API文檔：
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## 8. 與Flutter整合

### 8.1 更新Flutter API配置
```dart
// lib/services/auth_api_service.dart
class AuthApiService {
  static const String baseUrl = 'http://localhost:8000/api/v1';  // FastAPI地址
  // 其他配置保持不變...
}
```

### 8.2 測試API連接
```bash
# 測試獲取驗證碼
curl -X GET "http://localhost:8000/api/v1/auth/captcha"

# 測試登入
curl -X POST "http://localhost:8000/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

這個FastAPI實現提供了完整的驗證碼認證系統，包括：
- 驗證碼生成和驗證
- 登入嘗試限制
- 速率限制
- JWT令牌管理
- Redis緩存
- 完整的錯誤處理
- API文檔
- 測試和部署配置

您可以根據團隊的需求進一步定制和擴展這個實現。
