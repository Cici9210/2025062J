"""
消息模式 (message.py)
功能: 定義用户之間的消息數據結構
相依: pydantic
"""
from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class MessageBase(BaseModel):
    """消息基本模式"""
    content: str

class MessageCreate(MessageBase):
    """創建新消息的請求模式"""
    receiver_id: int

class Message(MessageBase):
    """完整消息數據模式"""
    id: int
    sender_id: int
    receiver_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True
