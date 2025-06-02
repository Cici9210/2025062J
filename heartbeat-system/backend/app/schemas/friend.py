"""
好友相關的資料結構 (friend.py)
功能: 定義好友相關的Pydantic模型
相依: pydantic庫
"""
from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime


class FriendRequestBase(BaseModel):
    """好友請求基本資料結構"""
    email: EmailStr


class FriendRequest(FriendRequestBase):
    """好友請求完整資料結構"""
    id: int
    user_id_1: int  # 發送請求的用戶
    user_id_2: Optional[int] = None  # 接收請求的用戶
    status: str  # "pending", "accepted", "rejected"
    created_at: datetime
    from_user_email: Optional[str] = None
    
    class Config:
        orm_mode = True


class FriendRequestCreate(FriendRequestBase):
    """創建好友請求的資料結構"""
    pass


class FriendRequestResponse(BaseModel):
    """好友請求回應資料結構"""
    id: int
    status: str
    
    class Config:
        orm_mode = True
