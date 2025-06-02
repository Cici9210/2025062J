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
    user_id = Column(Integer, ForeignKey("users.id"))
    
    # 關聯
    owner = relationship("User", back_populates="devices")
    heartbeat_logs = relationship("HeartbeatLog", back_populates="device")

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
