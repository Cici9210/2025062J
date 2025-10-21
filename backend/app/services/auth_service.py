"""
認證服務 (auth_service.py)
功能: 處理使用者註冊、登入和認證相關的功能
相依: security.py中的密碼雜湊和JWT功能
"""
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from jose import JWTError, jwt
from datetime import datetime, timedelta
from typing import Optional

from ..database import models, connection
from ..schemas import auth, user
from ..utils.security import verify_password, get_password_hash, SECRET_KEY, ALGORITHM

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/token")


def get_user_by_email(db: Session, email: str):
    """根據電子郵件獲取使用者"""
    return db.query(models.User).filter(models.User.email == email).first()


def create_user(db: Session, user: auth.UserCreate):
    """創建新使用者"""
    hashed_password = get_password_hash(user.password)
    db_user = models.User(email=user.email, password_hash=hashed_password)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


def authenticate_user(db: Session, email: str, password: str):
    """驗證使用者"""
    try:
        user = get_user_by_email(db, email)
        if not user:
            print(f"用戶不存在: {email}")
            return False
        
        print(f"驗證用戶: {email}")
        print(f"密碼長度: {len(password)}")
        print(f"密碼哈希值長度: {len(user.password_hash) if user.password_hash else 0}")
        
        if not verify_password(password, user.password_hash):
            print("密碼驗證失敗")
            return False
            
        print("密碼驗證成功")
        return user
    except Exception as e:
        print(f"身份驗證過程中出現錯誤: {str(e)}")
        import traceback
        traceback.print_exc()
        return False


def get_current_user(db: Session = Depends(connection.get_db), token: str = Depends(oauth2_scheme)):
    """從令牌中獲取當前使用者"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
        
    user = get_user_by_email(db, email=email)
    if user is None:
        raise credentials_exception
    return user
