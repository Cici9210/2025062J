"""
安全工具 (security.py)
功能: 提供密碼雜湊和JWT令牌功能
相依: passlib、jose
"""
from passlib.context import CryptContext
from jose import jwt
from datetime import datetime, timedelta
from typing import Optional

# 密碼處理上下文
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# JWT配置 (實際應用中應從環境變數讀取)
SECRET_KEY = "這裡應該是非常長且安全的隨機字串"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

def verify_password(plain_password, hashed_password):
    """驗證密碼"""
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    """獲取密碼雜湊值"""
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """創建訪問令牌"""
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt
