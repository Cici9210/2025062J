"""
配對相關 Schema (pairing.py)
功能: 定義配對、聊天室、好友邀請的Pydantic模型
相依: pydantic
"""
from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List


class PairingCreate(BaseModel):
    """創建配對請求"""
    target_user_id: int


class PairingResponse(BaseModel):
    """配對回應"""
    id: int
    user_id_1: int
    user_id_2: int
    status: str
    created_at: datetime
    matched_at: Optional[datetime]
    
    class Config:
        from_attributes = True


class ChatRoomResponse(BaseModel):
    """聊天室回應"""
    id: int
    user_id_1: int
    user_id_2: int
    room_type: str  # "temporary" or "permanent"
    is_active: bool
    expires_at: Optional[datetime]
    created_at: datetime
    
    class Config:
        from_attributes = True


class ChatRoomDetail(BaseModel):
    """聊天室詳細資訊(含對方資訊)"""
    id: int
    room_type: str
    is_active: bool
    expires_at: Optional[datetime]
    created_at: datetime
    other_user_id: int
    other_user_email: str
    is_friend: bool  # 是否為好友
    
    class Config:
        from_attributes = True


class FriendInvitationResponse(BaseModel):
    """好友邀請回應"""
    id: int
    chat_room_id: int
    user_id_1: int
    user_id_2: int
    user_1_response: Optional[str]
    user_2_response: Optional[str]
    status: str
    created_at: datetime
    expires_at: datetime
    
    class Config:
        from_attributes = True


class FriendInvitationDetail(BaseModel):
    """好友邀請詳細資訊"""
    id: int
    chat_room_id: int
    other_user_id: int
    other_user_email: str
    my_response: Optional[str]
    other_response: Optional[str]
    status: str
    created_at: datetime
    expires_at: datetime
    time_remaining: int  # 剩餘秒數
    
    class Config:
        from_attributes = True


class RespondInvitationRequest(BaseModel):
    """回應好友邀請請求"""
    response: str  # "accept" or "reject"


class FriendshipResponse(BaseModel):
    """好友關係回應"""
    id: int
    user_id_1: int
    user_id_2: int
    created_at: datetime
    
    class Config:
        from_attributes = True


class FriendDetail(BaseModel):
    """好友詳細資訊"""
    user_id: int
    email: str
    is_online: bool  # 是否在線
    last_seen: Optional[datetime]  # 最後上線時間
    
    class Config:
        from_attributes = True
