"""
資料庫模型 (models.py)
功能: 定義系統所有資料表的SQLAlchemy模型
相依: connection.py中的Base類別
"""
from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Float, DateTime, Table
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from .connection import Base

class User(Base):
    """使用者資料表"""
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    email = Column(String(255), unique=True, index=True)
    password_hash = Column(String(255))
    created_at = Column(DateTime, server_default=func.now())
    
    # 關聯
    devices = relationship("Device", back_populates="owner")
    interactions = relationship("Interaction", back_populates="user")

class Device(Base):
    """裝置資料表"""
    __tablename__ = "devices"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    device_uid = Column(String(64), unique=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    name = Column(String(100), default="ESP32 Device")
    is_online = Column(Boolean, default=False)
    last_active = Column(DateTime, nullable=True)
    created_at = Column(DateTime, server_default=func.now())
    
    # 關聯
    owner = relationship("User", back_populates="devices")
    heartbeat_logs = relationship("HeartbeatLog", back_populates="device")
    pressure_data = relationship("PressureData", back_populates="device", cascade="all, delete-orphan")

class Interaction(Base):
    """互動記錄資料表"""
    __tablename__ = "interactions"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    timestamp = Column(DateTime, server_default=func.now())
    pressure_level = Column(Float)
    
    # 關聯
    user = relationship("User", back_populates="interactions")

class HeartbeatLog(Base):
    """心跳記錄資料表"""
    __tablename__ = "heartbeat_logs"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    device_id = Column(Integer, ForeignKey("devices.id"))
    bpm = Column(Integer)
    temperature = Column(Float)
    logged_at = Column(DateTime, server_default=func.now())
    
    # 關聯
    device = relationship("Device", back_populates="heartbeat_logs")

class Pairing(Base):
    """配對關係資料表"""
    __tablename__ = "pairings"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id_1 = Column(Integer, ForeignKey("users.id"))
    user_id_2 = Column(Integer, ForeignKey("users.id"))
    status = Column(String(20))  # "pending", "active", "rejected"
    created_at = Column(DateTime, server_default=func.now())
    matched_at = Column(DateTime, nullable=True)  # 配對成功時間
    
    # 關聯
    chat_room = relationship("ChatRoom", back_populates="pairing", uselist=False)

class Friendship(Base):
    """好友關係資料表"""
    __tablename__ = "friendships"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id_1 = Column(Integer, ForeignKey("users.id"))
    user_id_2 = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime, server_default=func.now())

class FriendRequest(Base):
    """好友請求資料表"""
    __tablename__ = "friend_requests"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id_1 = Column(Integer, ForeignKey("users.id"))  # 發送請求的用戶
    user_id_2 = Column(Integer, ForeignKey("users.id"))  # 接收請求的用戶
    status = Column(String(20))  # "pending", "accepted", "rejected"
    created_at = Column(DateTime, server_default=func.now())

class Message(Base):
    """用戶間文字交流資料表"""
    __tablename__ = "messages"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    sender_id = Column(Integer, ForeignKey("users.id"))  # 發送消息的用戶
    receiver_id = Column(Integer, ForeignKey("users.id"))  # 接收消息的用戶
    content = Column(String(1024))  # 消息内容
    is_read = Column(Boolean, default=False)  # 是否已讀
    chat_room_id = Column(Integer, ForeignKey("chat_rooms.id"), nullable=True)  # 所屬聊天室
    created_at = Column(DateTime, server_default=func.now())
    
    # 關聯
    chat_room = relationship("ChatRoom", back_populates="messages")

class ChatRoom(Base):
    """聊天室資料表"""
    __tablename__ = "chat_rooms"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id_1 = Column(Integer, ForeignKey("users.id"))  # 用戶1
    user_id_2 = Column(Integer, ForeignKey("users.id"))  # 用戶2
    room_type = Column(String(20))  # "temporary" 臨時(5分鐘), "permanent" 永久(好友)
    pairing_id = Column(Integer, ForeignKey("pairings.id"), nullable=True)  # 關聯的配對
    is_active = Column(Boolean, default=True)  # 聊天室是否啟用
    expires_at = Column(DateTime, nullable=True)  # 臨時聊天室過期時間
    created_at = Column(DateTime, server_default=func.now())
    
    # 關聯
    messages = relationship("Message", back_populates="chat_room")
    pairing = relationship("Pairing", back_populates="chat_room")

class FriendInvitation(Base):
    """好友邀請通知資料表(配對5分鐘後)"""
    __tablename__ = "friend_invitations"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    chat_room_id = Column(Integer, ForeignKey("chat_rooms.id"))  # 來源聊天室
    user_id_1 = Column(Integer, ForeignKey("users.id"))  # 用戶1
    user_id_2 = Column(Integer, ForeignKey("users.id"))  # 用戶2
    user_1_response = Column(String(20), nullable=True)  # "accept", "reject", null
    user_2_response = Column(String(20), nullable=True)  # "accept", "reject", null
    status = Column(String(20), default="pending")  # "pending", "both_accepted", "rejected"
    created_at = Column(DateTime, server_default=func.now())
    expires_at = Column(DateTime)  # 邀請過期時間

class PressureData(Base):
    """壓力數據資料表"""
    __tablename__ = "pressure_data"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    device_id = Column(Integer, ForeignKey("devices.id"))
    pressure_value = Column(Integer)  # 壓力值
    timestamp = Column(DateTime, server_default=func.now())
    
    # 關聯
    device = relationship("Device", back_populates="pressure_data")

class PairingQueue(Base):
    """配對等待隊列"""
    __tablename__ = "pairing_queue"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime, server_default=func.now())
    is_active = Column(Boolean, default=True)
