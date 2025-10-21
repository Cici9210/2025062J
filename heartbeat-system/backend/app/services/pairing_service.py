"""
配對服務 (pairing_service.py)
功能: 處理用戶配對、臨時聊天室創建、好友邀請邏輯
相依: SQLAlchemy, models, datetime
"""
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, not_
from typing import Optional, List
import random

from ..database.models import Pairing, ChatRoom, FriendInvitation, Friendship, User, PairingQueue
from ..schemas.pairing import PairingCreate, ChatRoomResponse


class PairingService:
    """配對服務類"""
    
    @staticmethod
    def create_pairing(db: Session, user_id_1: int, user_id_2: int) -> Pairing:
        """
        創建新的配對關係
        """
        # 檢查是否已存在配對
        existing = db.query(Pairing).filter(
            or_(
                and_(Pairing.user_id_1 == user_id_1, Pairing.user_id_2 == user_id_2),
                and_(Pairing.user_id_1 == user_id_2, Pairing.user_id_2 == user_id_1)
            ),
            Pairing.status == "active"
        ).first()
        
        if existing:
            return existing
        
        pairing = Pairing(
            user_id_1=user_id_1,
            user_id_2=user_id_2,
            status="active",
            matched_at=datetime.now()
        )
        db.add(pairing)
        db.commit()
        db.refresh(pairing)
        
        # 配對成功後自動創建5分鐘臨時聊天室
        PairingService.create_temporary_chat_room(db, pairing)
        
        return pairing
    
    @staticmethod
    def create_temporary_chat_room(db: Session, pairing: Pairing) -> ChatRoom:
        """
        配對成功後創建5分鐘臨時聊天室
        """
        # 測試模式: 30 秒過期 (正式環境改為 minutes=5)
        expires_at = datetime.now() + timedelta(seconds=30)
        
        chat_room = ChatRoom(
            user_id_1=pairing.user_id_1,
            user_id_2=pairing.user_id_2,
            room_type="temporary",
            pairing_id=pairing.id,
            is_active=True,
            expires_at=expires_at
        )
        db.add(chat_room)
        db.commit()
        db.refresh(chat_room)
        
        return chat_room
    
    @staticmethod
    def check_and_create_friend_invitation(db: Session, chat_room_id: int) -> Optional[FriendInvitation]:
        """
        檢查臨時聊天室是否已過期(5分鐘),若是則創建好友邀請
        """
        chat_room = db.query(ChatRoom).filter(ChatRoom.id == chat_room_id).first()
        
        if not chat_room or chat_room.room_type != "temporary":
            return None
        
        # 檢查是否已過期
        if datetime.now() < chat_room.expires_at:
            return None  # 未過期,不創建邀請
        
        # 檢查是否已存在邀請
        existing = db.query(FriendInvitation).filter(
            FriendInvitation.chat_room_id == chat_room_id
        ).first()
        
        if existing:
            return existing
        
        # 創建好友邀請(有效期24小時)
        invitation = FriendInvitation(
            chat_room_id=chat_room_id,
            user_id_1=chat_room.user_id_1,
            user_id_2=chat_room.user_id_2,
            status="pending",
            expires_at=datetime.now() + timedelta(hours=24)
        )
        db.add(invitation)
        
        # 停用臨時聊天室
        chat_room.is_active = False
        
        db.commit()
        db.refresh(invitation)
        
        return invitation
    
    @staticmethod
    def respond_to_friend_invitation(
        db: Session, 
        invitation_id: int, 
        user_id: int, 
        response: str  # "accept" or "reject"
    ) -> Optional[Friendship]:
        """
        用戶回應好友邀請
        """
        invitation = db.query(FriendInvitation).filter(
            FriendInvitation.id == invitation_id
        ).first()
        
        if not invitation:
            return None
        
        # 檢查用戶是否為邀請的參與者
        if user_id == invitation.user_id_1:
            invitation.user_1_response = response
        elif user_id == invitation.user_id_2:
            invitation.user_2_response = response
        else:
            return None  # 非邀請參與者
        
        # 檢查雙方是否都已回應
        if invitation.user_1_response and invitation.user_2_response:
            if invitation.user_1_response == "accept" and invitation.user_2_response == "accept":
                # 雙方都接受,創建好友關係和永久聊天室
                invitation.status = "both_accepted"
                friendship = PairingService.create_friendship(
                    db, 
                    invitation.user_id_1, 
                    invitation.user_id_2,
                    invitation.chat_room_id
                )
                db.commit()
                return friendship
            else:
                # 至少一方拒絕
                invitation.status = "rejected"
                db.commit()
                return None
        
        db.commit()
        return None
    
    @staticmethod
    def create_friendship(
        db: Session, 
        user_id_1: int, 
        user_id_2: int,
        temp_chat_room_id: int
    ) -> Friendship:
        """
        創建好友關係並升級為永久聊天室
        """
        # 檢查是否已是好友
        existing = db.query(Friendship).filter(
            or_(
                and_(Friendship.user_id_1 == user_id_1, Friendship.user_id_2 == user_id_2),
                and_(Friendship.user_id_1 == user_id_2, Friendship.user_id_2 == user_id_1)
            )
        ).first()
        
        if existing:
            return existing
        
        # 創建好友關係
        friendship = Friendship(
            user_id_1=user_id_1,
            user_id_2=user_id_2
        )
        db.add(friendship)
        
        # 創建永久聊天室或升級臨時聊天室
        temp_room = db.query(ChatRoom).filter(ChatRoom.id == temp_chat_room_id).first()
        
        if temp_room:
            # 升級臨時聊天室為永久
            temp_room.room_type = "permanent"
            temp_room.is_active = True
            temp_room.expires_at = None
        else:
            # 創建新的永久聊天室
            permanent_room = ChatRoom(
                user_id_1=user_id_1,
                user_id_2=user_id_2,
                room_type="permanent",
                is_active=True,
                expires_at=None
            )
            db.add(permanent_room)
        
        db.commit()
        db.refresh(friendship)
        
        return friendship
    
    @staticmethod
    def get_user_chat_rooms(db: Session, user_id: int) -> List[ChatRoom]:
        """
        獲取用戶的所有聊天室(包括臨時和永久)
        """
        chat_rooms = db.query(ChatRoom).filter(
            or_(
                ChatRoom.user_id_1 == user_id,
                ChatRoom.user_id_2 == user_id
            ),
            ChatRoom.is_active == True
        ).all()
        
        return chat_rooms
    
    @staticmethod
    def get_active_chat_room(db: Session, user_id_1: int, user_id_2: int) -> Optional[ChatRoom]:
        """
        獲取兩個用戶之間的活躍聊天室
        """
        chat_room = db.query(ChatRoom).filter(
            or_(
                and_(ChatRoom.user_id_1 == user_id_1, ChatRoom.user_id_2 == user_id_2),
                and_(ChatRoom.user_id_1 == user_id_2, ChatRoom.user_id_2 == user_id_1)
            ),
            ChatRoom.is_active == True
        ).first()
        
        return chat_room
    
    @staticmethod
    def get_pending_friend_invitations(db: Session, user_id: int) -> List[FriendInvitation]:
        """
        獲取用戶待處理的好友邀請
        """
        invitations = db.query(FriendInvitation).filter(
            or_(
                FriendInvitation.user_id_1 == user_id,
                FriendInvitation.user_id_2 == user_id
            ),
            FriendInvitation.status == "pending",
            FriendInvitation.expires_at > datetime.now()
        ).all()
        
        return invitations
    
    @staticmethod
    def is_friends(db: Session, user_id_1: int, user_id_2: int) -> bool:
        """
        檢查兩個用戶是否為好友
        """
        friendship = db.query(Friendship).filter(
            or_(
                and_(Friendship.user_id_1 == user_id_1, Friendship.user_id_2 == user_id_2),
                and_(Friendship.user_id_1 == user_id_2, Friendship.user_id_2 == user_id_1)
            )
        ).first()
        
        return friendship is not None
    
    @staticmethod
    def get_user_friends(db: Session, user_id: int) -> List[User]:
        """
        獲取用戶的所有好友
        """
        friendships = db.query(Friendship).filter(
            or_(
                Friendship.user_id_1 == user_id,
                Friendship.user_id_2 == user_id
            )
        ).all()
        
        friend_ids = []
        for friendship in friendships:
            friend_id = friendship.user_id_2 if friendship.user_id_1 == user_id else friendship.user_id_1
            friend_ids.append(friend_id)
        
        friends = db.query(User).filter(User.id.in_(friend_ids)).all()
        return friends
    
    @staticmethod
    def join_pairing_queue(db: Session, user_id: int) -> Optional[Pairing]:
        """
        用戶加入配對隊列,嘗試與其他等待中的用戶配對
        如果找到匹配,創建配對並返回;否則加入等待隊列
        """
        # 清理舊的隊列記錄 (超過5分鐘)
        timeout = datetime.now() - timedelta(minutes=5)
        db.query(PairingQueue).filter(PairingQueue.created_at < timeout).delete()
        db.commit()
        
        # 檢查用戶是否已在隊列中
        existing = db.query(PairingQueue).filter(
            PairingQueue.user_id == user_id,
            PairingQueue.is_active == True
        ).first()
        
        if existing:
            # 已在隊列中,嘗試配對
            return PairingService._try_match_from_queue(db, user_id)
        
        # 獲取所有等待中的用戶(排除自己和已經是好友的用戶)
        waiting_users = db.query(PairingQueue).filter(
            PairingQueue.user_id != user_id,
            PairingQueue.is_active == True
        ).all()
        
        # 過濾掉已是好友的用戶
        available_users = []
        for queue_item in waiting_users:
            if not PairingService.is_friends(db, user_id, queue_item.user_id):
                # 檢查是否有活躍的配對
                existing_pairing = db.query(Pairing).filter(
                    or_(
                        and_(Pairing.user_id_1 == user_id, Pairing.user_id_2 == queue_item.user_id),
                        and_(Pairing.user_id_1 == queue_item.user_id, Pairing.user_id_2 == user_id)
                    ),
                    Pairing.status == "active"
                ).first()
                
                if not existing_pairing:
                    available_users.append(queue_item)
        
        if available_users:
            # 隨機選擇一個等待中的用戶
            matched_queue_item = random.choice(available_users)
            matched_user_id = matched_queue_item.user_id
            
            # 創建配對
            pairing = PairingService.create_pairing(db, user_id, matched_user_id)
            
            # 從隊列中移除雙方
            db.query(PairingQueue).filter(
                or_(
                    PairingQueue.user_id == user_id,
                    PairingQueue.user_id == matched_user_id
                )
            ).delete()
            db.commit()
            
            return pairing
        else:
            # 沒有可配對的用戶,加入隊列
            new_queue_item = PairingQueue(
                user_id=user_id,
                is_active=True
            )
            db.add(new_queue_item)
            db.commit()
            
            return None
    
    @staticmethod
    def _try_match_from_queue(db: Session, user_id: int) -> Optional[Pairing]:
        """
        嘗試從隊列中為用戶找到配對
        """
        # 獲取所有等待中的用戶(排除自己和已經是好友的用戶)
        waiting_users = db.query(PairingQueue).filter(
            PairingQueue.user_id != user_id,
            PairingQueue.is_active == True
        ).all()
        
        # 過濾掉已是好友的用戶
        available_users = []
        for queue_item in waiting_users:
            if not PairingService.is_friends(db, user_id, queue_item.user_id):
                # 檢查是否有活躍的配對
                existing_pairing = db.query(Pairing).filter(
                    or_(
                        and_(Pairing.user_id_1 == user_id, Pairing.user_id_2 == queue_item.user_id),
                        and_(Pairing.user_id_1 == queue_item.user_id, Pairing.user_id_2 == user_id)
                    ),
                    Pairing.status == "active"
                ).first()
                
                if not existing_pairing:
                    available_users.append(queue_item)
        
        if available_users:
            # 隨機選擇一個等待中的用戶
            matched_queue_item = random.choice(available_users)
            matched_user_id = matched_queue_item.user_id
            
            # 創建配對
            pairing = PairingService.create_pairing(db, user_id, matched_user_id)
            
            # 從隊列中移除雙方
            db.query(PairingQueue).filter(
                or_(
                    PairingQueue.user_id == user_id,
                    PairingQueue.user_id == matched_user_id
                )
            ).delete()
            db.commit()
            
            return pairing
        
        return None
    
    @staticmethod
    def leave_pairing_queue(db: Session, user_id: int):
        """
        用戶離開配對隊列
        """
        db.query(PairingQueue).filter(PairingQueue.user_id == user_id).delete()
        db.commit()
