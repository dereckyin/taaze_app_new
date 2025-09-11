# API端驗證碼實現示例

## 概述
本文檔提供API端驗證碼實現的完整示例，包括Node.js/Express和Python/Flask兩種實現方式。

## 1. Node.js/Express 實現

### 依賴安裝
```bash
npm install express cors helmet express-rate-limit express-slow-down
npm install jsonwebtoken bcryptjs uuid canvas
npm install redis ioredis  # 用於存儲驗證碼和嘗試次數
```

### 主要代碼

#### 1.1 驗證碼生成服務
```javascript
// services/captchaService.js
const { createCanvas } = require('canvas');
const crypto = require('crypto');

class CaptchaService {
  constructor() {
    this.captchaStore = new Map(); // 生產環境應使用Redis
  }

  // 生成隨機字符串
  generateRandomString(length = 4) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let result = '';
    for (let i = 0; i < length; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
  }

  // 生成驗證碼圖片
  generateCaptchaImage(text) {
    const width = 120;
    const height = 50;
    const canvas = createCanvas(width, height);
    const ctx = canvas.getContext('2d');

    // 背景
    ctx.fillStyle = '#f0f0f0';
    ctx.fillRect(0, 0, width, height);

    // 干擾線
    for (let i = 0; i < 5; i++) {
      ctx.strokeStyle = `rgb(${Math.random() * 255}, ${Math.random() * 255}, ${Math.random() * 255})`;
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.moveTo(Math.random() * width, Math.random() * height);
      ctx.lineTo(Math.random() * width, Math.random() * height);
      ctx.stroke();
    }

    // 文字
    ctx.font = 'bold 20px Arial';
    ctx.fillStyle = '#333';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    
    // 添加文字扭曲效果
    for (let i = 0; i < text.length; i++) {
      const char = text[i];
      const x = (width / text.length) * (i + 0.5);
      const y = height / 2 + (Math.random() - 0.5) * 10;
      
      ctx.save();
      ctx.translate(x, y);
      ctx.rotate((Math.random() - 0.5) * 0.4);
      ctx.fillText(char, 0, 0);
      ctx.restore();
    }

    return canvas.toDataURL('image/png');
  }

  // 創建驗證碼
  createCaptcha() {
    const captchaId = crypto.randomUUID();
    const captchaText = this.generateRandomString(4);
    const captchaImage = this.generateCaptchaImage(captchaText);

    // 存儲驗證碼（5分鐘過期）
    this.captchaStore.set(captchaId, {
      text: captchaText,
      createdAt: Date.now(),
      attempts: 0
    });

    // 清理過期驗證碼
    this.cleanupExpiredCaptchas();

    return {
      captchaId,
      captchaImage,
      captchaText, // 僅用於測試
      required: true
    };
  }

  // 驗證驗證碼
  verifyCaptcha(captchaId, userInput) {
    const captcha = this.captchaStore.get(captchaId);
    
    if (!captcha) {
      return { valid: false, error: '驗證碼不存在或已過期' };
    }

    // 檢查是否過期（5分鐘）
    if (Date.now() - captcha.createdAt > 5 * 60 * 1000) {
      this.captchaStore.delete(captchaId);
      return { valid: false, error: '驗證碼已過期' };
    }

    // 檢查嘗試次數
    if (captcha.attempts >= 3) {
      this.captchaStore.delete(captchaId);
      return { valid: false, error: '驗證碼嘗試次數過多' };
    }

    captcha.attempts++;

    if (captcha.text.toUpperCase() === userInput.toUpperCase()) {
      this.captchaStore.delete(captchaId);
      return { valid: true };
    } else {
      return { valid: false, error: '驗證碼錯誤' };
    }
  }

  // 清理過期驗證碼
  cleanupExpiredCaptchas() {
    const now = Date.now();
    for (const [id, captcha] of this.captchaStore.entries()) {
      if (now - captcha.createdAt > 5 * 60 * 1000) {
        this.captchaStore.delete(id);
      }
    }
  }
}

module.exports = new CaptchaService();
```

#### 1.2 登入嘗試限制服務
```javascript
// services/loginAttemptService.js
class LoginAttemptService {
  constructor() {
    this.attempts = new Map(); // 生產環境應使用Redis
  }

  // 記錄登入嘗試
  recordAttempt(email, ip, success) {
    const key = `${email}:${ip}`;
    const now = Date.now();
    
    if (!this.attempts.has(key)) {
      this.attempts.set(key, {
        attempts: [],
        locked: false,
        lockUntil: null
      });
    }

    const userAttempts = this.attempts.get(key);
    userAttempts.attempts.push({
      timestamp: now,
      success
    });

    // 清理舊的嘗試記錄（保留最近1小時）
    userAttempts.attempts = userAttempts.attempts.filter(
      attempt => now - attempt.timestamp < 60 * 60 * 1000
    );

    // 檢查是否需要鎖定
    const recentFailedAttempts = userAttempts.attempts.filter(
      attempt => !attempt.success && now - attempt.timestamp < 15 * 60 * 1000
    );

    if (recentFailedAttempts.length >= 5) {
      userAttempts.locked = true;
      userAttempts.lockUntil = now + 15 * 60 * 1000; // 鎖定15分鐘
    }

    // 如果登入成功，重置嘗試記錄
    if (success) {
      this.attempts.delete(key);
    }
  }

  // 檢查是否需要驗證碼
  shouldRequireCaptcha(email, ip) {
    const key = `${email}:${ip}`;
    const userAttempts = this.attempts.get(key);
    
    if (!userAttempts) return false;

    const now = Date.now();
    const recentFailedAttempts = userAttempts.attempts.filter(
      attempt => !attempt.success && now - attempt.timestamp < 15 * 60 * 1000
    );

    return recentFailedAttempts.length >= 2;
  }

  // 檢查是否被鎖定
  isLocked(email, ip) {
    const key = `${email}:${ip}`;
    const userAttempts = this.attempts.get(key);
    
    if (!userAttempts || !userAttempts.locked) return false;

    const now = Date.now();
    if (now > userAttempts.lockUntil) {
      userAttempts.locked = false;
      userAttempts.lockUntil = null;
      return false;
    }

    return true;
  }

  // 獲取鎖定剩餘時間
  getLockoutRemainingTime(email, ip) {
    const key = `${email}:${ip}`;
    const userAttempts = this.attempts.get(key);
    
    if (!userAttempts || !userAttempts.locked) return 0;

    const now = Date.now();
    return Math.max(0, userAttempts.lockUntil - now);
  }
}

module.exports = new LoginAttemptService();
```

#### 1.3 API路由
```javascript
// routes/auth.js
const express = require('express');
const rateLimit = require('express-rate-limit');
const slowDown = require('express-slow-down');
const captchaService = require('../services/captchaService');
const loginAttemptService = require('../services/loginAttemptService');

const router = express.Router();

// 速率限制
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15分鐘
  max: 5, // 最多5次嘗試
  message: { error: '嘗試次數過多，請稍後再試' },
  standardHeaders: true,
  legacyHeaders: false,
});

// 慢速限制
const speedLimiter = slowDown({
  windowMs: 15 * 60 * 1000, // 15分鐘
  delayAfter: 2, // 2次嘗試後開始延遲
  delayMs: 500, // 每次延遲500ms
});

// 獲取驗證碼
router.get('/captcha', (req, res) => {
  try {
    const captcha = captchaService.createCaptcha();
    res.json({
      success: true,
      ...captcha
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: '生成驗證碼失敗'
    });
  }
});

// 刷新驗證碼
router.post('/captcha/refresh', (req, res) => {
  try {
    const { captchaId } = req.body;
    
    // 刪除舊驗證碼
    if (captchaId) {
      captchaService.captchaStore.delete(captchaId);
    }
    
    const captcha = captchaService.createCaptcha();
    res.json({
      success: true,
      ...captcha
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: '刷新驗證碼失敗'
    });
  }
});

// 登入
router.post('/login', loginLimiter, speedLimiter, async (req, res) => {
  try {
    const { email, password, captchaId, captchaCode } = req.body;
    const clientIp = req.ip || req.connection.remoteAddress;

    // 檢查是否被鎖定
    if (loginAttemptService.isLocked(email, clientIp)) {
      const remainingTime = loginAttemptService.getLockoutRemainingTime(email, clientIp);
      return res.status(429).json({
        success: false,
        error: '帳戶已被鎖定',
        lockoutRemainingTime: remainingTime
      });
    }

    // 檢查是否需要驗證碼
    const requiresCaptcha = loginAttemptService.shouldRequireCaptcha(email, clientIp);
    
    if (requiresCaptcha) {
      if (!captchaId || !captchaCode) {
        const captcha = captchaService.createCaptcha();
        return res.status(400).json({
          success: false,
          error: '需要驗證碼',
          captchaRequired: true,
          captcha: captcha
        });
      }

      // 驗證驗證碼
      const captchaResult = captchaService.verifyCaptcha(captchaId, captchaCode);
      if (!captchaResult.valid) {
        const captcha = captchaService.createCaptcha();
        return res.status(400).json({
          success: false,
          error: captchaResult.error,
          captchaRequired: true,
          captcha: captcha
        });
      }
    }

    // 驗證用戶憑證（這裡應該查詢數據庫）
    const isValidUser = await validateUserCredentials(email, password);
    
    if (isValidUser) {
      // 登入成功
      loginAttemptService.recordAttempt(email, clientIp, true);
      
      const token = generateJWTToken(email);
      const refreshToken = generateRefreshToken(email);
      
      res.json({
        success: true,
        token,
        refreshToken,
        user: {
          id: '1',
          email,
          name: email.split('@')[0],
          createdAt: new Date().toISOString(),
          lastLoginAt: new Date().toISOString()
        }
      });
    } else {
      // 登入失敗
      loginAttemptService.recordAttempt(email, clientIp, false);
      
      const requiresCaptcha = loginAttemptService.shouldRequireCaptcha(email, clientIp);
      let captcha = null;
      
      if (requiresCaptcha) {
        captcha = captchaService.createCaptcha();
      }
      
      res.status(401).json({
        success: false,
        error: '電子郵件或密碼錯誤',
        captchaRequired: requiresCaptcha,
        captcha
      });
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: '登入失敗'
    });
  }
});

// 輔助函數
async function validateUserCredentials(email, password) {
  // 這裡應該查詢數據庫驗證用戶憑證
  // 示例：模擬驗證
  const validUsers = {
    'test@example.com': 'password123',
    'admin@example.com': 'admin123',
    'user@example.com': 'user123'
  };
  
  return validUsers[email] === password;
}

function generateJWTToken(email) {
  // 這裡應該使用JWT庫生成真實的token
  return 'mock-jwt-token';
}

function generateRefreshToken(email) {
  // 這裡應該生成刷新token
  return 'mock-refresh-token';
}

module.exports = router;
```

## 2. Python/Flask 實現

### 依賴安裝
```bash
pip install flask flask-cors flask-limiter redis pillow
pip install pyjwt bcrypt
```

### 主要代碼

#### 2.1 驗證碼服務
```python
# services/captcha_service.py
import uuid
import random
import string
import time
from PIL import Image, ImageDraw, ImageFont
import io
import base64

class CaptchaService:
    def __init__(self):
        self.captcha_store = {}  # 生產環境應使用Redis
    
    def generate_random_string(self, length=4):
        """生成隨機字符串"""
        return ''.join(random.choices(string.ascii_uppercase + string.digits, k=length))
    
    def generate_captcha_image(self, text):
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
        """創建驗證碼"""
        captcha_id = str(uuid.uuid4())
        captcha_text = self.generate_random_string(4)
        captcha_image = self.generate_captcha_image(captcha_text)
        
        # 存儲驗證碼（5分鐘過期）
        self.captcha_store[captcha_id] = {
            'text': captcha_text,
            'created_at': time.time(),
            'attempts': 0
        }
        
        # 清理過期驗證碼
        self.cleanup_expired_captchas()
        
        return {
            'captchaId': captcha_id,
            'captchaImage': captcha_image,
            'captchaText': captcha_text,  # 僅用於測試
            'required': True
        }
    
    def verify_captcha(self, captcha_id, user_input):
        """驗證驗證碼"""
        if captcha_id not in self.captcha_store:
            return {'valid': False, 'error': '驗證碼不存在或已過期'}
        
        captcha = self.captcha_store[captcha_id]
        
        # 檢查是否過期（5分鐘）
        if time.time() - captcha['created_at'] > 300:
            del self.captcha_store[captcha_id]
            return {'valid': False, 'error': '驗證碼已過期'}
        
        # 檢查嘗試次數
        if captcha['attempts'] >= 3:
            del self.captcha_store[captcha_id]
            return {'valid': False, 'error': '驗證碼嘗試次數過多'}
        
        captcha['attempts'] += 1
        
        if captcha['text'].upper() == user_input.upper():
            del self.captcha_store[captcha_id]
            return {'valid': True}
        else:
            return {'valid': False, 'error': '驗證碼錯誤'}
    
    def cleanup_expired_captchas(self):
        """清理過期驗證碼"""
        current_time = time.time()
        expired_ids = [
            captcha_id for captcha_id, captcha in self.captcha_store.items()
            if current_time - captcha['created_at'] > 300
        ]
        for captcha_id in expired_ids:
            del self.captcha_store[captcha_id]

captcha_service = CaptchaService()
```

#### 2.2 Flask應用
```python
# app.py
from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from services.captcha_service import captcha_service
import time

app = Flask(__name__)
CORS(app)

# 速率限制
limiter = Limiter(
    app,
    key_func=get_remote_address,
    default_limits=["200 per day", "50 per hour"]
)

# 登入嘗試記錄
login_attempts = {}

@app.route('/api/auth/captcha', methods=['GET'])
def get_captcha():
    try:
        captcha = captcha_service.create_captcha()
        return jsonify({
            'success': True,
            **captcha
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': '生成驗證碼失敗'
        }), 500

@app.route('/api/auth/captcha/refresh', methods=['POST'])
def refresh_captcha():
    try:
        data = request.get_json()
        captcha_id = data.get('captchaId')
        
        # 刪除舊驗證碼
        if captcha_id and captcha_id in captcha_service.captcha_store:
            del captcha_service.captcha_store[captcha_id]
        
        captcha = captcha_service.create_captcha()
        return jsonify({
            'success': True,
            **captcha
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': '刷新驗證碼失敗'
        }), 500

@app.route('/api/auth/login', methods=['POST'])
@limiter.limit("5 per 15 minutes")
def login():
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')
        captcha_id = data.get('captchaId')
        captcha_code = data.get('captchaCode')
        
        client_ip = request.remote_addr
        
        # 檢查是否被鎖定
        if is_locked(email, client_ip):
            remaining_time = get_lockout_remaining_time(email, client_ip)
            return jsonify({
                'success': False,
                'error': '帳戶已被鎖定',
                'lockoutRemainingTime': remaining_time
            }), 429
        
        # 檢查是否需要驗證碼
        requires_captcha = should_require_captcha(email, client_ip)
        
        if requires_captcha:
            if not captcha_id or not captcha_code:
                captcha = captcha_service.create_captcha()
                return jsonify({
                    'success': False,
                    'error': '需要驗證碼',
                    'captchaRequired': True,
                    'captcha': captcha
                }), 400
            
            # 驗證驗證碼
            captcha_result = captcha_service.verify_captcha(captcha_id, captcha_code)
            if not captcha_result['valid']:
                captcha = captcha_service.create_captcha()
                return jsonify({
                    'success': False,
                    'error': captcha_result['error'],
                    'captchaRequired': True,
                    'captcha': captcha
                }), 400
        
        # 驗證用戶憑證
        if validate_user_credentials(email, password):
            # 登入成功
            record_attempt(email, client_ip, True)
            
            return jsonify({
                'success': True,
                'token': 'mock-jwt-token',
                'refreshToken': 'mock-refresh-token',
                'user': {
                    'id': '1',
                    'email': email,
                    'name': email.split('@')[0],
                    'createdAt': time.strftime('%Y-%m-%dT%H:%M:%S.000Z'),
                    'lastLoginAt': time.strftime('%Y-%m-%dT%H:%M:%S.000Z')
                }
            })
        else:
            # 登入失敗
            record_attempt(email, client_ip, False)
            
            requires_captcha = should_require_captcha(email, client_ip)
            captcha = None
            
            if requires_captcha:
                captcha = captcha_service.create_captcha()
            
            return jsonify({
                'success': False,
                'error': '電子郵件或密碼錯誤',
                'captchaRequired': requires_captcha,
                'captcha': captcha
            }), 401
            
    except Exception as e:
        return jsonify({
            'success': False,
            'error': '登入失敗'
        }), 500

# 輔助函數
def validate_user_credentials(email, password):
    """驗證用戶憑證"""
    valid_users = {
        'test@example.com': 'password123',
        'admin@example.com': 'admin123',
        'user@example.com': 'user123'
    }
    return valid_users.get(email) == password

def record_attempt(email, ip, success):
    """記錄登入嘗試"""
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
        if current_time - attempt['timestamp'] < 3600  # 保留最近1小時
    ]
    
    # 檢查是否需要鎖定
    recent_failed_attempts = [
        attempt for attempt in user_attempts['attempts']
        if not attempt['success'] and current_time - attempt['timestamp'] < 900  # 15分鐘內
    ]
    
    if len(recent_failed_attempts) >= 5:
        user_attempts['locked'] = True
        user_attempts['lock_until'] = current_time + 900  # 鎖定15分鐘
    
    # 如果登入成功，重置嘗試記錄
    if success:
        del login_attempts[key]

def should_require_captcha(email, ip):
    """檢查是否需要驗證碼"""
    key = f"{email}:{ip}"
    if key not in login_attempts:
        return False
    
    current_time = time.time()
    recent_failed_attempts = [
        attempt for attempt in login_attempts[key]['attempts']
        if not attempt['success'] and current_time - attempt['timestamp'] < 900
    ]
    
    return len(recent_failed_attempts) >= 2

def is_locked(email, ip):
    """檢查是否被鎖定"""
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

def get_lockout_remaining_time(email, ip):
    """獲取鎖定剩餘時間"""
    key = f"{email}:{ip}"
    if key not in login_attempts:
        return 0
    
    user_attempts = login_attempts[key]
    if not user_attempts['locked']:
        return 0
    
    current_time = time.time()
    return max(0, user_attempts['lock_until'] - current_time)

if __name__ == '__main__':
    app.run(debug=True, port=3000)
```

## 3. 安全最佳實踐

### 3.1 驗證碼安全
- 使用隨機字符串生成
- 添加干擾線和扭曲效果
- 限制嘗試次數（3次）
- 設置過期時間（5分鐘）
- 使用HTTPS傳輸

### 3.2 登入限制
- IP級別速率限制
- 用戶級別嘗試次數限制
- 漸進式延遲
- 帳戶鎖定機制

### 3.3 數據存儲
- 生產環境使用Redis
- 設置適當的過期時間
- 定期清理過期數據
- 加密敏感信息

### 3.4 監控和日誌
- 記錄所有登入嘗試
- 監控異常行為
- 設置警報機制
- 定期安全審計

## 4. 部署建議

### 4.1 環境配置
```bash
# 環境變量
CAPTCHA_EXPIRE_TIME=300
MAX_LOGIN_ATTEMPTS=5
LOCKOUT_DURATION=900
RATE_LIMIT_WINDOW=900
RATE_LIMIT_MAX=5
```

### 4.2 Redis配置
```bash
# Redis配置
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=your_password
REDIS_DB=0
```

### 4.3 負載均衡
- 使用多個API實例
- 配置負載均衡器
- 實現會話共享
- 設置健康檢查

這個實現提供了完整的API端驗證碼驗證機制，確保了安全性和可擴展性。
