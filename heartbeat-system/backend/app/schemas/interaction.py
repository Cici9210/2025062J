"""
互動相關的資料結構 (interaction.py)
功能: 定義互動相關的Pydantic模型
相依: pydantic庫
"""
from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class InteractionBase(BaseModel):
    """互動基本資料結構"""
    pressure_level: float


class InteractionCreate(InteractionBase):
    """創建互動記錄的資料結構"""
    pass


class Interaction(InteractionBase):
    """互動完整資料結構"""
    id: int
    user_id: int
    timestamp: datetime
    
    class Config:
        orm_mode = True


class PairingRequest(BaseModel):
    """配對請求資料結構"""
    target_user_id: Optional[int] = None  # 如果為None則表示隨機配對


class PairingResponse(BaseModel):
    """配對回應資料結構"""
    pairing_id: int
    status: str
    target_user_id: int
    
    class Config:
        orm_mode = True
