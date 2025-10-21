"""
裝置API (device.py)
功能: 處理ESP32裝置連接、壓力數據、裝置狀態查詢
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from ..database.connection import get_db
from ..database.models import User
from ..services import device_service
from ..services.auth_service import get_current_user
from ..schemas import device as device_schema

router = APIRouter(prefix="/api/devices", tags=["devices"])


@router.post("/bind")
def bind_device(
    device_uid: str,
    name: str = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """綁定裝置到當前用戶"""
    try:
        bound_device = device_service.bind_device(
            db, 
            device_uid, 
            current_user.id,
            name
        )
        return {
            "id": bound_device.id,
            "device_uid": bound_device.device_uid,
            "name": bound_device.name,
            "is_online": bound_device.is_online
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"綁定裝置失敗: {str(e)}"
        )


@router.get("/my")
def get_my_devices(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """獲取當前用戶的所有裝置"""
    try:
        devices = device_service.get_user_devices(db, current_user.id)
        return [{
            "id": device.id,
            "device_uid": device.device_uid,
            "name": device.name,
            "is_online": device.is_online,
            "last_active": device.last_active.isoformat() if device.last_active else None
        } for device in devices]
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"獲取裝置失敗: {str(e)}"
        )


@router.get("/pressure/{device_id}")
def get_device_pressure_data(
    device_id: int,
    minutes: int = 5,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """獲取裝置最近的壓力數據"""
    try:
        # 檢查裝置是否屬於當前用戶
        devices = device_service.get_user_devices(db, current_user.id)
        device = next((d for d in devices if d.id == device_id), None)
        
        if not device:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="裝置不存在或不屬於當前用戶"
            )
        
        # 獲取壓力數據
        pressure_data = device_service.get_recent_pressure_data(db, device_id, minutes)
        
        return [{
            "id": data.id,
            "pressure_value": data.pressure_value,
            "timestamp": data.timestamp.isoformat()
        } for data in pressure_data]
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"獲取壓力數據失敗: {str(e)}"
        )


@router.get("/friends/devices")
def get_friend_devices(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """獲取好友裝置狀態"""
    try:
        friend_devices = device_service.get_friend_devices_status(db, current_user.id)
        return friend_devices
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"獲取好友裝置狀態失敗: {str(e)}"
        )


@router.post("/register")
def register_device(
    device_uid: str,
    db: Session = Depends(get_db)
):
    """註冊新裝置（用於ESP32首次連接）"""
    try:
        device = device_service.register_device(db, device_uid)
        return {
            "id": device.id,
            "device_uid": device.device_uid,
            "name": device.name,
            "is_online": device.is_online,
            "message": "裝置註冊成功"
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"註冊裝置失敗: {str(e)}"
        )


@router.post("/pressure")
def store_pressure(
    device_uid: str,
    pressure: int,
    db: Session = Depends(get_db)
):
    """存儲壓力數據（用於ESP32上傳數據）"""
    try:
        pressure_data = device_service.store_pressure_data(db, device_uid, pressure)
        return {
            "id": pressure_data.id,
            "device_id": pressure_data.device_id,
            "pressure_value": pressure_data.pressure_value,
            "timestamp": pressure_data.timestamp.isoformat(),
            "message": "壓力數據儲存成功"
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"存儲壓力數據失敗: {str(e)}"
        )
