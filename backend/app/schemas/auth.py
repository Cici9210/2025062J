"""
認證相關的資料結構 (auth.py)
功能: 定義使用者註冊、登入和令牌相關的Pydantic模型
相依: pydantic庫
"""
from pydantic import BaseModel, EmailStr
from typing import Optional


class UserCreate(BaseModel):
    """使用者註冊資料結構"""
    email: EmailStr
    password: str


class Token(BaseModel):
    """JWT令牌資料結構"""
    access_token: str
    token_type: str


class TokenData(BaseModel):
    """令牌資料結構"""
    email: Optional[str] = None
