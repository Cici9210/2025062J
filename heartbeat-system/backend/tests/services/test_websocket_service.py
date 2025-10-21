"""
WebSocket服務測試 (test_websocket_service.py)
功能: 測試WebSocket連接管理、消息處理和轉發功能
相依: pytest、fastapi.testclient
"""
import pytest
import json
import asyncio
from unittest.mock import MagicMock, AsyncMock
from sqlalchemy.orm import Session
from fastapi import WebSocket

from app.services.websocket_service import ConnectionManager
from app.database import models


class TestWebSocketService:
    """WebSocket服務測試類"""
    
    def test_init(self):
        """測試ConnectionManager初始化"""
        manager = ConnectionManager()
        assert manager.active_connections == {}
        assert manager.active_pairings == {}
    
    @pytest.mark.asyncio
    async def test_connect(self):
        """測試WebSocket連接"""
        manager = ConnectionManager()
        websocket = AsyncMock(spec=WebSocket)
        client_id = "client-1"
        
        await manager.connect(websocket, client_id)
        
        websocket.accept.assert_called_once()
        assert client_id in manager.active_connections
        assert manager.active_connections[client_id] == websocket
    
    def test_disconnect(self):
        """測試WebSocket斷開連接"""
        manager = ConnectionManager()
        websocket = MagicMock(spec=WebSocket)
        client_id = "client-1"
        
        # 先連接
        manager.active_connections[client_id] = websocket
        assert client_id in manager.active_connections
        
        # 斷開連接
        manager.disconnect(client_id)
        assert client_id not in manager.active_connections
    
    @pytest.mark.asyncio
    async def test_send_personal_message(self):
        """測試發送個人訊息"""
        manager = ConnectionManager()
        websocket = AsyncMock(spec=WebSocket)
        client_id = "client-1"
        message = "Hello, Test!"
        
        # 先連接
        manager.active_connections[client_id] = websocket
        
        # 發送訊息
        await manager.send_personal_message(message, client_id)
        websocket.send_text.assert_called_once_with(message)
    
    @pytest.mark.asyncio
    async def test_send_personal_message_not_connected(self):
        """測試發送訊息給不存在的連接"""
        manager = ConnectionManager()
        client_id = "non-existent-client"
        message = "Hello, Test!"
        
        # 這應該不會引發異常
        await manager.send_personal_message(message, client_id)
    
    @pytest.mark.asyncio
    async def test_broadcast(self):
        """測試廣播訊息"""
        manager = ConnectionManager()
        
        # 創建多個模擬WebSocket連接
        websockets = [AsyncMock(spec=WebSocket) for _ in range(3)]
        client_ids = [f"client-{i}" for i in range(3)]
        message = "Broadcast message"
        
        # 將所有連接加入管理器
        for client_id, websocket in zip(client_ids, websockets):
            manager.active_connections[client_id] = websocket
        
        # 廣播訊息
        await manager.broadcast(message)
        
        # 驗證所有連接都收到了訊息
        for websocket in websockets:
            websocket.send_text.assert_called_once_with(message)
    
    def test_add_pairing(self):
        """測試添加配對關係"""
        manager = ConnectionManager()
        user_id_1 = "user-1"
        user_id_2 = "user-2"
        
        manager.add_pairing(user_id_1, user_id_2)
        
        assert user_id_1 in manager.active_pairings
        assert user_id_2 in manager.active_pairings
        assert manager.active_pairings[user_id_1] == user_id_2
        assert manager.active_pairings[user_id_2] == user_id_1
    
    def test_remove_pairing(self):
        """測試移除配對關係"""
        manager = ConnectionManager()
        user_id_1 = "user-1"
        user_id_2 = "user-2"
        
        # 先添加配對
        manager.add_pairing(user_id_1, user_id_2)
        
        # 移除配對
        manager.remove_pairing(user_id_1, user_id_2)
        
        assert user_id_1 not in manager.active_pairings
        assert user_id_2 not in manager.active_pairings
    
    def test_remove_pairing_with_single_user(self):
        """測試只提供一個用戶ID移除配對關係"""
        manager = ConnectionManager()
        user_id_1 = "user-1"
        user_id_2 = "user-2"
        
        # 先添加配對
        manager.add_pairing(user_id_1, user_id_2)
        
        # 只使用一個ID移除配對
        manager.remove_pairing(user_id_1)
        
        assert user_id_1 not in manager.active_pairings
        assert user_id_2 not in manager.active_pairings
    
    def test_get_user_id_from_device(self, test_db: Session):
        """測試從裝置ID獲取用戶ID"""
        manager = ConnectionManager()
        
        # 創建測試用戶
        user = models.User(email="wstest@example.com", password_hash="hashed_password")
        test_db.add(user)
        test_db.commit()
        test_db.refresh(user)
        
        # 創建裝置
        device = models.Device(device_uid="ws-device", user_id=user.id)
        test_db.add(device)
        test_db.commit()
        test_db.refresh(device)
        
        # 測試_get_user_id_from_device
        user_id = manager._get_user_id_from_device(test_db, device.id)
        assert user_id == user.id
    
    def test_get_user_id_from_nonexistent_device(self, test_db: Session):
        """測試從不存在的裝置ID獲取用戶ID"""
        manager = ConnectionManager()
        
        # 測試_get_user_id_from_device返回None
        user_id = manager._get_user_id_from_device(test_db, 9999)
        assert user_id is None
    
    def test_get_device_by_user_id(self, test_db: Session):
        """測試從用戶ID獲取裝置"""
        manager = ConnectionManager()
        
        # 創建測試用戶
        user = models.User(email="wsdevicetest@example.com", password_hash="hashed_password")
        test_db.add(user)
        test_db.commit()
        test_db.refresh(user)
        
        # 創建裝置
        device = models.Device(device_uid="wsuser-device", user_id=user.id)
        test_db.add(device)
        test_db.commit()
        test_db.refresh(device)
        
        # 測試_get_device_by_user_id
        found_device = manager._get_device_by_user_id(test_db, user.id)
        assert found_device is not None
        assert found_device.id == device.id
        assert found_device.device_uid == device.device_uid
    
    def test_get_device_by_nonexistent_user_id(self, test_db: Session):
        """測試從不存在的用戶ID獲取裝置"""
        manager = ConnectionManager()
        
        # 測試_get_device_by_user_id返回None
        device = manager._get_device_by_user_id(test_db, 9999)
        assert device is None
