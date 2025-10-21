"""
配對和聊天室 API (pairing.py)
功能: 處理配對、臨時聊天室、好友邀請的API端點
相依: FastAPI, SQLAlchemy
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime

from ..database.connection import get_db
from ..database.models import User
from ..services.pairing_service import PairingService
from ..services.auth_service import get_current_user
from ..schemas.pairing import (
    PairingCreate, PairingResponse, ChatRoomResponse, ChatRoomDetail,
    FriendInvitationResponse, FriendInvitationDetail, RespondInvitationRequest,
    FriendshipResponse, FriendDetail
)

router = APIRouter(prefix="/api/pairing", tags=["pairing"])


@router.post("/match", response_model=PairingResponse)
def create_pairing(
    pairing_data: PairingCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    創建配對(配對成功後自動創建5分鐘臨時聊天室)
    """
    try:
        pairing = PairingService.create_pairing(
            db, 
            current_user.id, 
            pairing_data.target_user_id
        )
        return pairing
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"配對失敗: {str(e)}"
        )


@router.get("/chat-rooms", response_model=List[ChatRoomDetail])
def get_my_chat_rooms(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    獲取我的所有聊天室(臨時和永久)
    """
    try:
        chat_rooms = PairingService.get_user_chat_rooms(db, current_user.id)
        
        result = []
        for room in chat_rooms:
            # 判斷對方用戶
            other_user_id = room.user_id_2 if room.user_id_1 == current_user.id else room.user_id_1
            other_user = db.query(User).filter(User.id == other_user_id).first()
            
            # 檢查是否為好友
            is_friend = PairingService.is_friends(db, current_user.id, other_user_id)
            
            result.append(ChatRoomDetail(
                id=room.id,
                room_type=room.room_type,
                is_active=room.is_active,
                expires_at=room.expires_at,
                created_at=room.created_at,
                other_user_id=other_user_id,
                other_user_email=other_user.email if other_user else "Unknown",
                is_friend=is_friend
            ))
        
        return result
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"獲取聊天室失敗: {str(e)}"
        )


@router.get("/chat-room/{other_user_id}", response_model=ChatRoomDetail)
def get_chat_room_with_user(
    other_user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    獲取與特定用戶的聊天室
    """
    try:
        room = PairingService.get_active_chat_room(db, current_user.id, other_user_id)
        
        if not room:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="未找到聊天室"
            )
        
        other_user = db.query(User).filter(User.id == other_user_id).first()
        is_friend = PairingService.is_friends(db, current_user.id, other_user_id)
        
        return ChatRoomDetail(
            id=room.id,
            room_type=room.room_type,
            is_active=room.is_active,
            expires_at=room.expires_at,
            created_at=room.created_at,
            other_user_id=other_user_id,
            other_user_email=other_user.email if other_user else "Unknown",
            is_friend=is_friend
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"獲取聊天室失敗: {str(e)}"
        )


@router.post("/chat-room/{chat_room_id}/check-expiry")
def check_chat_room_expiry(
    chat_room_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    檢查聊天室是否過期,如過期則創建好友邀請
    """
    try:
        invitation = PairingService.check_and_create_friend_invitation(db, chat_room_id)
        
        if invitation:
            return {
                "expired": True,
                "invitation_created": True,
                "invitation_id": invitation.id
            }
        else:
            return {
                "expired": False,
                "invitation_created": False
            }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"檢查失敗: {str(e)}"
        )


@router.get("/invitations", response_model=List[FriendInvitationDetail])
def get_my_friend_invitations(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    獲取我的待處理好友邀請
    """
    try:
        invitations = PairingService.get_pending_friend_invitations(db, current_user.id)
        
        result = []
        for inv in invitations:
            # 判斷對方用戶
            other_user_id = inv.user_id_2 if inv.user_id_1 == current_user.id else inv.user_id_1
            other_user = db.query(User).filter(User.id == other_user_id).first()
            
            # 判斷我的回應和對方回應
            my_response = inv.user_1_response if inv.user_id_1 == current_user.id else inv.user_2_response
            other_response = inv.user_2_response if inv.user_id_1 == current_user.id else inv.user_1_response
            
            # 計算剩餘時間
            time_remaining = int((inv.expires_at - datetime.now()).total_seconds())
            
            result.append(FriendInvitationDetail(
                id=inv.id,
                chat_room_id=inv.chat_room_id,
                other_user_id=other_user_id,
                other_user_email=other_user.email if other_user else "Unknown",
                my_response=my_response,
                other_response=other_response,
                status=inv.status,
                created_at=inv.created_at,
                expires_at=inv.expires_at,
                time_remaining=max(0, time_remaining)
            ))
        
        return result
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"獲取邀請失敗: {str(e)}"
        )


@router.post("/invitations/{invitation_id}/respond")
def respond_to_invitation(
    invitation_id: int,
    response_data: RespondInvitationRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    回應好友邀請(雙方都接受後自動成為好友並升級為永久聊天室)
    """
    try:
        if response_data.response not in ["accept", "reject"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="無效的回應,必須是 'accept' 或 'reject'"
            )
        
        friendship = PairingService.respond_to_friend_invitation(
            db,
            invitation_id,
            current_user.id,
            response_data.response
        )
        
        if friendship:
            return {
                "success": True,
                "became_friends": True,
                "friendship_id": friendship.id,
                "message": "雙方都接受邀請,已成為好友!"
            }
        else:
            return {
                "success": True,
                "became_friends": False,
                "message": f"已記錄您的回應: {response_data.response}"
            }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"回應邀請失敗: {str(e)}"
        )


@router.get("/friends", response_model=List[FriendDetail])
def get_my_friends(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    獲取我的所有好友列表(含在線狀態)
    """
    try:
        friends = PairingService.get_user_friends(db, current_user.id)
        
        result = []
        for friend in friends:
            # TODO: 實現在線狀態檢測(可通過 WebSocket 或最後活動時間)
            is_online = False  # 暫時設為 False
            last_seen = None
            
            result.append(FriendDetail(
                user_id=friend.id,
                email=friend.email,
                is_online=is_online,
                last_seen=last_seen
            ))
        
        return result
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"獲取好友列表失敗: {str(e)}"
        )


@router.get("/is-friend/{user_id}")
def check_friendship(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    檢查與指定用戶是否為好友
    """
    try:
        is_friend = PairingService.is_friends(db, current_user.id, user_id)
        return {"is_friend": is_friend}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"檢查失敗: {str(e)}"
        )


@router.post("/random-match")
def random_match(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    隨機配對其他在線用戶
    如果找到匹配,創建配對並返回;否則加入等待隊列
    """
    try:
        pairing = PairingService.join_pairing_queue(db, current_user.id)
        
        if pairing:
            # 找到配對
            other_user_id = pairing.user_id_2 if pairing.user_id_1 == current_user.id else pairing.user_id_1
            other_user = db.query(User).filter(User.id == other_user_id).first()
            
            # 獲取聊天室
            chat_room = PairingService.get_active_chat_room(db, current_user.id, other_user_id)
            
            return {
                "matched": True,
                "pairing_id": pairing.id,
                "other_user_id": other_user_id,
                "other_user_email": other_user.email if other_user else "Unknown",
                "chat_room_id": chat_room.id if chat_room else None,
                "message": "配對成功!已創建臨時聊天室"
            }
        else:
            # 加入隊列等待
            return {
                "matched": False,
                "message": "已加入配對隊列,請稍候..."
            }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"隨機配對失敗: {str(e)}"
        )


@router.post("/leave-queue")
def leave_pairing_queue(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    離開配對隊列
    """
    try:
        PairingService.leave_pairing_queue(db, current_user.id)
        return {
            "success": True,
            "message": "已離開配對隊列"
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"離開隊列失敗: {str(e)}"
        )

