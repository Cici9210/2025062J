"""
裝置相關的資料結構 (device.py)
功能: 定義裝置相關的Pydantic模型
相依: pydantic庫
"""
from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class DeviceBase(BaseModel):
    """裝置基本資料結構"""
    device_uid: str


class DeviceBind(DeviceBase):
    """裝置綁定請求資料結構"""
    pass


class Device(DeviceBase):
    """裝置完整資料結構"""
    id: int
    user_id: int
    
    class Config:
        orm_mode = True


class DeviceStatus(BaseModel):
    """裝置狀態資料結構"""
    id: int
    device_uid: str
    is_online: bool
    last_heartbeat: Optional[datetime] = None
    last_bpm: Optional[int] = None
    last_temperature: Optional[float] = None
    
    class Config:
        orm_mode = True
