"""
WebSocket服務 (websocket_service.py)
功能: 管理WebSocket連接、訊息處理和轉發
相依: models.py中的資料庫模型
"""
from fastapi import WebSocket
from sqlalchemy.orm import Session
from typing import Dict, List
import json
import asyncio

from ..database import models


class ConnectionManager:
    def __init__(self):
        # 存儲活躍連接的字典 {client_id: websocket}
        self.active_connections: Dict[str, WebSocket] = {}
        # 存儲配對關係的字典 {user_id: paired_user_id}
        self.active_pairings: Dict[str, str] = {}
        
    async def connect(self, websocket: WebSocket, client_id: str):
        """建立WebSocket連接"""
        await websocket.accept()
        self.active_connections[client_id] = websocket
        
    def disconnect(self, client_id: str):
        """關閉WebSocket連接"""
        if client_id in self.active_connections:
            del self.active_connections[client_id]
            
    async def send_personal_message(self, message: str, client_id: str):
        """發送個人訊息"""
        if client_id in self.active_connections:
            await self.active_connections[client_id].send_text(message)
            
    async def broadcast(self, message: str):
        """廣播訊息給所有連接"""
        for connection in self.active_connections.values():
            await connection.send_text(message)
            
    async def process_message(self, client_id: str, data: dict, db: Session):
        """處理從客戶端收到的消息"""
        message_type = data.get("type")
        
        if message_type == "heartbeat":
            # 記錄心跳數據
            device_id = data.get("device_id")
            bpm = data.get("bpm")
            temperature = data.get("temperature")
            
            heartbeat_log = models.HeartbeatLog(
                device_id=device_id,
                bpm=bpm,
                temperature=temperature
            )
            db.add(heartbeat_log)
            db.commit()
            
            # 如果該用戶已配對，則轉發心跳數據
            user_id = self._get_user_id_from_device(db, device_id)
            if user_id and user_id in self.active_pairings:
                paired_user_id = self.active_pairings[user_id]
                paired_device = self._get_device_by_user_id(db, paired_user_id)
                
                if paired_device and str(paired_device.id) in self.active_connections:
                    await self.send_personal_message(
                        json.dumps({
                            "type": "paired_heartbeat",
                            "bpm": bpm,
                            "temperature": temperature
                        }),
                        str(paired_device.id)
                    )
        
        elif message_type == "pressure":
            # 處理壓力數據
            device_id = data.get("device_id")
            pressure_level = data.get("pressure_level")
            
            # 記錄互動
            user_id = self._get_user_id_from_device(db, device_id)
            if user_id:
                interaction = models.Interaction(
                    user_id=user_id,
                    pressure_level=pressure_level
                )
                db.add(interaction)
                db.commit()
            
            # 如果配對了，則轉發壓力數據
            if user_id and user_id in self.active_pairings:
                paired_user_id = self.active_pairings[user_id]
                paired_device = self._get_device_by_user_id(db, paired_user_id)
                
                if paired_device and str(paired_device.id) in self.active_connections:
                    await self.send_personal_message(
                        json.dumps({
                            "type": "paired_pressure",
                            "pressure_level": pressure_level
                        }),
                        str(paired_device.id)
                    )
    
    def _get_user_id_from_device(self, db: Session, device_id: int) -> int:
        """從裝置ID獲取用戶ID"""
        device = db.query(models.Device).filter(models.Device.id == device_id).first()
        return device.user_id if device else None
        
    def _get_device_by_user_id(self, db: Session, user_id: int):
        """從用戶ID獲取裝置"""
        return db.query(models.Device).filter(models.Device.user_id == user_id).first()
        
    def add_pairing(self, user_id_1: str, user_id_2: str):
        """添加配對關係"""
        self.active_pairings[user_id_1] = user_id_2
        self.active_pairings[user_id_2] = user_id_1
        
    def remove_pairing(self, user_id_1: str, user_id_2: str = None):
        """移除配對關係"""
        if user_id_1 in self.active_pairings:
            if user_id_2 is None:
                user_id_2 = self.active_pairings[user_id_1]
            
            if user_id_1 in self.active_pairings:
                del self.active_pairings[user_id_1]
            if user_id_2 in self.active_pairings:
                del self.active_pairings[user_id_2]
