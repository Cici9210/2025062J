"""
裝置服務測試 (test_device_service.py)
功能: 測試裝置綁定、狀態查詢、互動記錄等功能
相依: pytest、fastapi.testclient
"""
import pytest
from fastapi import HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
import random

from app.services.device_service import (
    bind_device,
    get_user_devices,
    get_device_status,
    record_interaction,
    create_pairing_request,
    create_random_pairing,
    get_friends,
    get_pending_requests,
    create_friend_request,
    accept_friend_request
)
from app.schemas.interaction import InteractionCreate, PairingRequest
from app.schemas.device import DeviceStatus
from app.database import models
from tests.conftest import TEST_USER_EMAIL, TEST_USER_PASSWORD


class TestDeviceService:
    """裝置服務測試類"""
    
    def test_bind_device(self, test_db: Session):
        """測試綁定裝置到使用者"""
        # 創建測試用戶
        user = models.User(email="devicetest@example.com", password_hash="hashed_password")
        test_db.add(user)
        test_db.commit()
        test_db.refresh(user)
        
        # 綁定新裝置
        device_uid = "test-device-123"
        device = bind_device(test_db, device_uid, user.id)
        
        # 驗證綁定結果
        assert device.device_uid == device_uid
        assert device.user_id == user.id
        
        # 檢查資料庫中是否存在這個裝置
        db_device = test_db.query(models.Device).filter(models.Device.device_uid == device_uid).first()
        assert db_device is not None
        assert db_device.user_id == user.id
    
    def test_bind_existing_device(self, test_db: Session):
        """測試綁定已存在但未綁定使用者的裝置"""
        # 創建測試用戶
        user = models.User(email="devicetest2@example.com", password_hash="hashed_password")
        test_db.add(user)
        test_db.commit()
        test_db.refresh(user)
        
        # 創建未綁定的裝置
        device_uid = "unbound-device-456"
        unbound_device = models.Device(device_uid=device_uid, user_id=None)
        test_db.add(unbound_device)
        test_db.commit()
        
        # 綁定裝置
        device = bind_device(test_db, device_uid, user.id)
        
        # 驗證綁定結果
        assert device.device_uid == device_uid
        assert device.user_id == user.id
    
    def test_bind_already_bound_device(self, test_db: Session):
        """測試綁定已經綁定其他使用者的裝置"""
        # 創建兩個測試用戶
        user1 = models.User(email="deviceuser1@example.com", password_hash="hashed_password")
        user2 = models.User(email="deviceuser2@example.com", password_hash="hashed_password")
        test_db.add(user1)
        test_db.add(user2)
        test_db.commit()
        test_db.refresh(user1)
        test_db.refresh(user2)
        
        # 創建已綁定的裝置
        device_uid = "bound-device-789"
        bound_device = models.Device(device_uid=device_uid, user_id=user1.id)
        test_db.add(bound_device)
        test_db.commit()
        
        # 嘗試綁定到另一個用戶，應該拋出異常
        with pytest.raises(HTTPException) as excinfo:
            bind_device(test_db, device_uid, user2.id)
        
        assert excinfo.value.status_code == 400
        assert "Device already bound to another user" in excinfo.value.detail
    
    def test_get_user_devices(self, test_db: Session):
        """測試獲取用戶所有裝置"""
        # 創建測試用戶
        user = models.User(email="multidevice@example.com", password_hash="hashed_password")
        test_db.add(user)
        test_db.commit()
        test_db.refresh(user)
        
        # 創建多個裝置並綁定到用戶
        device_uids = ["device-1", "device-2", "device-3"]
        for uid in device_uids:
            device = models.Device(device_uid=uid, user_id=user.id)
            test_db.add(device)
        
        test_db.commit()
        
        # 獲取用戶裝置
        devices = get_user_devices(test_db, user.id)
        
        # 驗證結果
        assert len(devices) == 3
        assert set(d.device_uid for d in devices) == set(device_uids)
        for device in devices:
            assert device.user_id == user.id
    
    def test_get_device_status_online(self, test_db: Session):
        """測試獲取在線裝置狀態"""
        # 創建測試用戶和裝置
        user = models.User(email="statustest@example.com", password_hash="hashed_password")
        test_db.add(user)
        test_db.commit()
        test_db.refresh(user)
        
        device = models.Device(device_uid="status-device", user_id=user.id)
        test_db.add(device)
        test_db.commit()
        test_db.refresh(device)
        
        # 創建最近的心跳日誌（10秒前，表示在線）
        log_time = datetime.now() - timedelta(seconds=10)
        heartbeat_log = models.HeartbeatLog(
            device_id=device.id,
            bpm=75,
            temperature=36.5,
            logged_at=log_time
        )
        test_db.add(heartbeat_log)
        test_db.commit()
        
        # 獲取裝置狀態
        status = get_device_status(test_db, device.id, user.id)
        
        # 驗證結果
        assert status.id == device.id
        assert status.device_uid == device.device_uid
        assert status.is_online == True
        assert status.last_bpm == 75
        assert status.last_temperature == 36.5
        assert status.last_heartbeat == log_time
    
    def test_get_device_status_offline(self, test_db: Session):
        """測試獲取離線裝置狀態"""
        # 創建測試用戶和裝置
        user = models.User(email="offlinetest@example.com", password_hash="hashed_password")
        test_db.add(user)
        test_db.commit()
        test_db.refresh(user)
        
        device = models.Device(device_uid="offline-device", user_id=user.id)
        test_db.add(device)
        test_db.commit()
        test_db.refresh(device)
        
        # 創建較早的心跳日誌（30秒前，表示離線）
        log_time = datetime.now() - timedelta(seconds=30)
        heartbeat_log = models.HeartbeatLog(
            device_id=device.id,
            bpm=80,
            temperature=36.7,
            logged_at=log_time
        )
        test_db.add(heartbeat_log)
        test_db.commit()
        
        # 獲取裝置狀態
        status = get_device_status(test_db, device.id, user.id)
        
        # 驗證結果
        assert status.id == device.id
        assert status.device_uid == device.device_uid
        assert status.is_online == False
        assert status.last_bpm == 80
        assert status.last_temperature == 36.7
        assert status.last_heartbeat == log_time
    
    def test_get_device_status_not_found(self, test_db: Session):
        """測試獲取不存在的裝置狀態"""
        # 創建測試用戶
        user = models.User(email="notfoundtest@example.com", password_hash="hashed_password")
        test_db.add(user)
        test_db.commit()
        test_db.refresh(user)
        
        # 嘗試獲取不存在的裝置狀態
        with pytest.raises(HTTPException) as excinfo:
            get_device_status(test_db, 9999, user.id)
        
        assert excinfo.value.status_code == 404
        assert "Device not found or not owned by user" in excinfo.value.detail
    
    def test_record_interaction(self, test_db: Session):
        """測試記錄互動"""
        # 創建測試用戶
        user = models.User(email="interactiontest@example.com", password_hash="hashed_password")
        test_db.add(user)
        test_db.commit()
        test_db.refresh(user)
        
        # 創建互動數據
        interaction_data = InteractionCreate(pressure_level=75)
        
        # 記錄互動
        interaction = record_interaction(test_db, interaction_data, user.id)
        
        # 驗證結果
        assert interaction.user_id == user.id
        assert interaction.pressure_level == 75
        
        # 檢查資料庫中是否存在這個互動記錄
        db_interaction = test_db.query(models.Interaction).filter(models.Interaction.id == interaction.id).first()
        assert db_interaction is not None
        assert db_interaction.user_id == user.id
        assert db_interaction.pressure_level == 75
