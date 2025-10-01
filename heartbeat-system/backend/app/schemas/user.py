"""
使用者相關的資料結構 (user.py)
功能: 定義使用者相關的Pydantic模型
相依: pydantic庫
"""
from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime


class UserBase(BaseModel):
    """使用者基本資料結構"""
    email: EmailStr


class User(UserBase):
    """使用者完整資料結構"""
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True


class UserInDB(User):
    """資料庫中的使用者資料結構，包含密碼雜湊"""
    password_hash: str
    
    class Config:
        from_attributes = True


class UserWithStatus(User):
    """帶狀態的使用者資料結構，用於好友列表"""
    online: bool = False
    last_active: Optional[datetime] = None
    
    class Config:
        from_attributes = True
