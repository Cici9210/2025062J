"""
裝置服務 (device_service.py)
功能: 處理裝置綁定、狀態查詢、互動記錄等功能
相依: models.py中的資料庫模型
"""
from sqlalchemy.orm import Session
from fastapi import HTTPException
from datetime import datetime
import random

from ..database import models
from ..schemas import device, interaction, user, friend


def bind_device(db: Session, device_uid: str, user_id: int, name: str = None):
    """綁定裝置到使用者"""
    # 檢查裝置是否已存在
    db_device = db.query(models.Device).filter(models.Device.device_uid == device_uid).first()
    
    if db_device:
        # 如果裝置已被綁定到其他用戶
        if db_device.user_id is not None and db_device.user_id != user_id:
            raise HTTPException(status_code=400, detail="Device already bound to another user")
        
        # 更新裝置的使用者ID和名稱
        db_device.user_id = user_id
        if name:
            db_device.name = name
        db_device.is_online = True
        db_device.last_active = datetime.now()
    else:
        # 創建新裝置記錄
        db_device = models.Device(
            device_uid=device_uid,
            user_id=user_id,
            name=name or f"ESP32-{device_uid[-4:]}",
            is_online=True,
            last_active=datetime.now()
        )
        db.add(db_device)
    
    db.commit()
    db.refresh(db_device)
    return db_device


def get_user_devices(db: Session, user_id: int):
    """獲取用戶所有裝置"""
    devices = db.query(models.Device).filter(models.Device.user_id == user_id).all()
    
    # 轉換為schema回應並添加連接狀態
    from ..schemas.device import Device
    from ..main import connection_manager
    
    result = []
    for device in devices:
        # 檢查設備是否實際連接
        is_connected = connection_manager.is_device_connected(device.device_uid)
        
        # 創建設備數據對象
        device_data = Device(
            id=device.id,
            device_uid=device.device_uid,
            user_id=device.user_id,
            is_connected=is_connected  # 添加實際連接狀態
        )
        result.append(device_data)
    
    return result


def get_device_status(db: Session, device_id: int, user_id: int):
    """獲取裝置狀態"""
    # 檢查裝置是否存在且屬於當前使用者
    db_device = db.query(models.Device).filter(
        models.Device.id == device_id,
        models.Device.user_id == user_id
    ).first()
    
    if not db_device:
        raise HTTPException(status_code=404, detail="Device not found or not owned by user")
    
    # 從WebSocket連接管理器中獲取設備連接狀態
    from ..main import connection_manager
    is_online = connection_manager.is_device_connected(db_device.device_uid)
    
    # 獲取最新的心跳日誌
    latest_log = db.query(models.HeartbeatLog).filter(
        models.HeartbeatLog.device_id == device_id
    ).order_by(models.HeartbeatLog.logged_at.desc()).first()
    
    # 獲取心跳數據
    last_heartbeat = None
    last_bpm = None
    last_temperature = None
    
    if latest_log:
        last_heartbeat = latest_log.logged_at
        last_bpm = latest_log.bpm
        last_temperature = latest_log.temperature
    
    return device.DeviceStatus(
        id=db_device.id,
        device_uid=db_device.device_uid,
        is_online=is_online,
        last_heartbeat=last_heartbeat,
        last_bpm=last_bpm,
        last_temperature=last_temperature
    )


def record_interaction(db: Session, interaction_data: interaction.InteractionCreate, user_id: int):
    """記錄互動"""
    db_interaction = models.Interaction(
        user_id=user_id,
        pressure_level=interaction_data.pressure_level
    )
    db.add(db_interaction)
    db.commit()
    db.refresh(db_interaction)
    return db_interaction


def create_pairing_request(db: Session, pairing: interaction.PairingRequest, user_id: int):
    """創建配對請求"""
    if pairing.target_user_id is None:
        return create_random_pairing(db, user_id)
    
    # 檢查目標使用者是否存在
    target_user = db.query(models.User).filter(models.User.id == pairing.target_user_id).first()
    if not target_user:
        raise HTTPException(status_code=404, detail="Target user not found")
    
    # 檢查是否已有未處理的配對請求
    existing_pairing = db.query(models.Pairing).filter(
        ((models.Pairing.user_id_1 == user_id) & (models.Pairing.user_id_2 == pairing.target_user_id)) |
        ((models.Pairing.user_id_1 == pairing.target_user_id) & (models.Pairing.user_id_2 == user_id)),
        models.Pairing.status == "pending"
    ).first()
    
    if existing_pairing:
        raise HTTPException(status_code=400, detail="Pairing request already exists")
    
    # 創建新的配對請求
    db_pairing = models.Pairing(
        user_id_1=user_id,
        user_id_2=pairing.target_user_id,
        status="pending"
    )
    db.add(db_pairing)
    db.commit()
    db.refresh(db_pairing)
    
    return interaction.PairingResponse(
        pairing_id=db_pairing.id,
        status=db_pairing.status,
        target_user_id=db_pairing.user_id_2
    )


def create_random_pairing(db: Session, user_id: int):
    """創建隨機配對"""
    # 獲取除了當前使用者外的所有使用者
    all_users = db.query(models.User).filter(models.User.id != user_id).all()
    
    if not all_users:
        raise HTTPException(status_code=404, detail="No users available for pairing")
    
    # 隨機選擇一個使用者
    target_user = random.choice(all_users)
    
    # 創建配對
    db_pairing = models.Pairing(
        user_id_1=user_id,
        user_id_2=target_user.id,
        status="active"  # 直接設為活躍，無需等待接受
    )
    db.add(db_pairing)
    db.commit()
    db.refresh(db_pairing)
    
    return interaction.PairingResponse(
        pairing_id=db_pairing.id,
        status=db_pairing.status,
        target_user_id=db_pairing.user_id_2
    )


def get_friends(db: Session, user_id: int):
    """獲取好友列表及其狀態"""
    # 查詢所有友誼關係
    friendships = db.query(models.Friendship).filter(
        (models.Friendship.user_id_1 == user_id) | (models.Friendship.user_id_2 == user_id)
    ).all()
    
    friend_ids = []
    for friendship in friendships:
        friend_id = friendship.user_id_1 if friendship.user_id_1 != user_id else friendship.user_id_2
        friend_ids.append(friend_id)
    
    # 查詢好友資料
    friends = db.query(models.User).filter(models.User.id.in_(friend_ids)).all()
    
    # 轉換為帶狀態的使用者資料
    result = []
    for friend in friends:
        # 獲取該好友的裝置
        device = db.query(models.Device).filter(models.Device.user_id == friend.id).first()
        
        # 判斷是否在線
        is_online = False
        last_active = None
        
        if device:
            # 獲取最新的心跳日誌
            latest_log = db.query(models.HeartbeatLog).filter(
                models.HeartbeatLog.device_id == device.id
            ).order_by(models.HeartbeatLog.logged_at.desc()).first()
            
            if latest_log:
                last_active = latest_log.logged_at
                time_diff = (datetime.now() - last_active).total_seconds()
                is_online = time_diff < 15  # 15秒內有心跳視為在線
        
        friend_with_status = user.UserWithStatus(
            id=friend.id,
            email=friend.email,
            created_at=friend.created_at,
            online=is_online,
            last_active=last_active
        )
        result.append(friend_with_status)
    
    return result

def get_pending_requests(db: Session, user_id: int):
    """獲取待處理的好友請求"""
    try:
        # 查詢發送給當前用戶的待處理好友請求
        pending_requests = db.query(models.FriendRequest).filter(
            models.FriendRequest.user_id_2 == user_id,
            models.FriendRequest.status == "pending"
        ).all()
        
        # 查詢發送請求用戶的信息
        result = []
        for request in pending_requests:
            try:
                # 獲取請求發送者的信息
                from_user = db.query(models.User).filter(models.User.id == request.user_id_1).first()
                
                request_with_user = friend.FriendRequest(
                    id=request.id,
                    user_id_1=request.user_id_1,
                    user_id_2=request.user_id_2,
                    status=request.status,
                    created_at=request.created_at,
                    from_user_email=from_user.email if from_user else None
                )
                result.append(request_with_user)
            except Exception as e:
                # 記錄特定請求處理中的錯誤，但繼續處理其他請求
                print(f"處理好友請求ID {request.id} 時出錯: {e}")
                continue
        
        return result
    except Exception as e:
        print(f"獲取待處理好友請求時發生錯誤: {e}")
        # 返回空列表而不是拋出錯誤，使API能夠正常響應
        return []

def create_friend_request(db: Session, friend_request: friend.FriendRequestCreate, user_id: int):
    """創建好友請求"""
    # 查詢目標用戶
    target_user = db.query(models.User).filter(models.User.email == friend_request.email).first()
    if not target_user:
        raise HTTPException(status_code=404, detail="找不到此電子郵件的用戶")
    
    # 檢查是否是自己
    if target_user.id == user_id:
        raise HTTPException(status_code=400, detail="不能添加自己為好友")
    
    # 檢查是否已經是好友
    existing_friendship = db.query(models.Friendship).filter(
        ((models.Friendship.user_id_1 == user_id) & (models.Friendship.user_id_2 == target_user.id)) |
        ((models.Friendship.user_id_1 == target_user.id) & (models.Friendship.user_id_2 == user_id))
    ).first()
    
    if existing_friendship:
        raise HTTPException(status_code=400, detail="此用戶已經是您的好友")
    
    # 檢查是否已經有未處理的好友請求
    existing_request = db.query(models.FriendRequest).filter(
        ((models.FriendRequest.user_id_1 == user_id) & (models.FriendRequest.user_id_2 == target_user.id)) |
        ((models.FriendRequest.user_id_1 == target_user.id) & (models.FriendRequest.user_id_2 == user_id)),
        models.FriendRequest.status == "pending"
    ).first()
    
    if existing_request:
        # 檢查請求的方向
        if existing_request.user_id_1 == user_id:
            raise HTTPException(status_code=400, detail="您已經發送過好友請求給此用戶")
        else:
            raise HTTPException(status_code=400, detail="此用戶已經發送好友請求給您，請查看待處理的請求")
    
    # 創建好友請求
    new_request = models.FriendRequest(
        user_id_1=user_id,
        user_id_2=target_user.id,
        status="pending"
    )
    
    db.add(new_request)
    db.commit()
    db.refresh(new_request)
    
    return friend.FriendRequestResponse(id=new_request.id, status=new_request.status)

def accept_friend_request(db: Session, request_id: int, user_id: int):
    """接受好友請求"""
    # 查詢好友請求
    friend_req = db.query(models.FriendRequest).filter(
        models.FriendRequest.id == request_id,
        models.FriendRequest.user_id_2 == user_id,  # 確保是發給當前用戶的請求
        models.FriendRequest.status == "pending"
    ).first()
    
    if not friend_req:
        raise HTTPException(status_code=404, detail="Friend request not found")
    
    # 更新請求狀態
    friend_req.status = "accepted"
    
    # 創建好友關係
    new_friendship = models.Friendship(
        user_id_1=friend_req.user_id_1,
        user_id_2=friend_req.user_id_2
    )
    
    db.add(new_friendship)
    db.commit()
    db.refresh(friend_req)
    
    return friend.FriendRequestResponse(id=friend_req.id, status=friend_req.status)

def reject_friend_request(db: Session, request_id: int, user_id: int):
    """拒絕好友請求"""
    # 查詢好友請求
    friend_req = db.query(models.FriendRequest).filter(
        models.FriendRequest.id == request_id,
        models.FriendRequest.user_id_2 == user_id,  # 確保是發給當前用戶的請求
        models.FriendRequest.status == "pending"
    ).first()
    
    if not friend_req:
        raise HTTPException(status_code=404, detail="Friend request not found")
    
    # 更新請求狀態
    friend_req.status = "rejected"
    
    db.commit()
    db.refresh(friend_req)
    
    return friend.FriendRequestResponse(id=friend_req.id, status=friend_req.status)

def remove_friend(db: Session, friend_id: int, user_id: int):
    """移除好友"""
    # 查詢好友關係
    friendship = db.query(models.Friendship).filter(
        ((models.Friendship.user_id_1 == user_id) & (models.Friendship.user_id_2 == friend_id)) |
        ((models.Friendship.user_id_1 == friend_id) & (models.Friendship.user_id_2 == user_id))
    ).first()
    
    if not friendship:
        raise HTTPException(status_code=404, detail="Friendship not found")
    
    # 刪除好友關係
    db.delete(friendship)
    db.commit()
    
    return


def update_device_online_status(db: Session, device_uid: str, is_online: bool):
    """更新裝置在線狀態"""
    device = db.query(models.Device).filter(models.Device.device_uid == device_uid).first()
    if device:
        device.is_online = is_online
        if is_online:
            device.last_active = datetime.now()
        db.commit()
        db.refresh(device)
    return device


def store_pressure_data(db: Session, device_uid: str, pressure: int):
    """存儲壓力數據"""
    from datetime import timedelta
    
    device = db.query(models.Device).filter(models.Device.device_uid == device_uid).first()
    if not device:
        # 如果裝置不存在，創建一個未綁定的裝置
        device = models.Device(
            device_uid=device_uid,
            name=f"ESP32-{device_uid[-4:]}",
            is_online=True,
            last_active=datetime.now()
        )
        db.add(device)
        db.commit()
        db.refresh(device)
    
    pressure_data = models.PressureData(
        device_id=device.id,
        pressure_value=pressure,
        timestamp=datetime.now()
    )
    
    db.add(pressure_data)
    db.commit()
    db.refresh(pressure_data)
    
    # 更新裝置在線狀態
    device.last_active = datetime.now()
    device.is_online = True
    db.commit()
    
    return pressure_data


def get_recent_pressure_data(db: Session, device_id: int, minutes: int = 5):
    """獲取最近一段時間的壓力數據"""
    from datetime import timedelta
    
    recent_time = datetime.now() - timedelta(minutes=minutes)
    
    return db.query(models.PressureData).filter(
        models.PressureData.device_id == device_id,
        models.PressureData.timestamp >= recent_time
    ).order_by(models.PressureData.timestamp).all()


def get_friend_devices_status(db: Session, user_id: int):
    """獲取好友的裝置狀態"""
    # 獲取用戶的好友列表
    friends1 = db.query(models.User).join(
        models.Friendship, models.Friendship.user_id_2 == models.User.id
    ).filter(models.Friendship.user_id_1 == user_id).all()
    
    friends2 = db.query(models.User).join(
        models.Friendship, models.Friendship.user_id_1 == models.User.id
    ).filter(models.Friendship.user_id_2 == user_id).all()
    
    friends = friends1 + friends2
    result = []
    
    # 對於每個好友，獲取其裝置狀態
    for friend in friends:
        devices = db.query(models.Device).filter(models.Device.user_id == friend.id).all()
        
        for device in devices:
            # 獲取最新的壓力數據
            latest_data = db.query(models.PressureData).filter(
                models.PressureData.device_id == device.id
            ).order_by(models.PressureData.timestamp.desc()).first()
            
            result.append({
                "friend_id": friend.id,
                "friend_email": friend.email,
                "device_id": device.id,
                "device_uid": device.device_uid,
                "device_name": device.name,
                "is_online": device.is_online,
                "last_active": device.last_active.isoformat() if device.last_active else None,
                "latest_pressure": latest_data.pressure_value if latest_data else None,
                "latest_timestamp": latest_data.timestamp.isoformat() if latest_data else None
            })
    
    return result


def register_device(db: Session, device_uid: str):
    """註冊新裝置（未綁定用戶）"""
    device = db.query(models.Device).filter(models.Device.device_uid == device_uid).first()
    
    if device:
        device.is_online = True
        device.last_active = datetime.now()
        db.commit()
        db.refresh(device)
        return device
    
    new_device = models.Device(
        device_uid=device_uid,
        name=f"ESP32-{device_uid[-4:]}",
        is_online=True,
        last_active=datetime.now()
    )
    
    db.add(new_device)
    db.commit()
    db.refresh(new_device)
    
    return new_device

