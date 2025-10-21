"""
消息服務 (message_service.py)
功能: 提供消息相關的業務邏輯處理
相依: SQLAlchemy, datetime
"""
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_, desc
from datetime import datetime
from typing import List, Dict, Any

from ..database import models
from ..schemas import message as message_schema

def get_messages_between_users(db: Session, user_id: int, other_user_id: int) -> List[models.Message]:
    """獲取兩個用戶之間的所有消息"""
    # 查詢條件：(發送者=user_id 且 接收者=other_user_id) 或 (發送者=other_user_id 且 接收者=user_id)
    messages = db.query(models.Message).filter(
        or_(
            and_(models.Message.sender_id == user_id, models.Message.receiver_id == other_user_id),
            and_(models.Message.sender_id == other_user_id, models.Message.receiver_id == user_id)
        )
    ).order_by(models.Message.created_at).all()
    
    return messages

def create_message(db: Session, sender_id: int, message_data: message_schema.MessageCreate) -> models.Message:
    """創建新消息"""
    # 創建新消息對象
    db_message = models.Message(
        sender_id=sender_id,
        receiver_id=message_data.receiver_id,
        content=message_data.content
    )
    
    # 保存到數據庫
    db.add(db_message)
    db.commit()
    db.refresh(db_message)
    
    return db_message

def get_conversations(db: Session, user_id: int) -> List[Dict[str, Any]]:
    """獲取用戶的所有對話列表（每個好友的最後一條消息）"""
    try:
        # 使用原生SQL查詢找出每個對話的最後一條消息
        query = """
        WITH LastMessages AS (
            SELECT m.*,
                ROW_NUMBER() OVER (PARTITION BY 
                        CASE 
                            WHEN m.sender_id = :user_id THEN m.receiver_id 
                            ELSE m.sender_id 
                        END 
                        ORDER BY m.created_at DESC) as rn
            FROM messages m
            WHERE m.sender_id = :user_id OR m.receiver_id = :user_id
        )
        SELECT lm.*, 
            CASE WHEN lm.sender_id = :user_id THEN u2.email ELSE u1.email END as user_name,
            CASE WHEN lm.sender_id = :user_id THEN lm.receiver_id ELSE lm.sender_id END as user_id
        FROM LastMessages lm
        JOIN users u1 ON lm.sender_id = u1.id
        JOIN users u2 ON lm.receiver_id = u2.id
        WHERE rn = 1
        ORDER BY lm.created_at DESC;
        """
        
        result = db.execute(query, {"user_id": user_id}).fetchall()
        
        conversations = []
        for row in result:
            try:
                # 判斷消息是否已讀（這裡簡單地假設收到但不是自己發送的消息都是未讀）
                unread = row.receiver_id == user_id  # 如果當前用戶是接收者，則消息未讀
                
                # 另一個用戶的ID（與當前用戶聊天的用戶）
                other_user_id = row.receiver_id if row.sender_id == user_id else row.sender_id
                
                conversation = {
                    "user_id": other_user_id,
                    "user_name": row.user_name,
                    "latest_message": row.content,
                    "latest_time": row.created_at,
                    "unread": unread
                }
                conversations.append(conversation)
            except Exception as e:
                print(f"處理對話時出現錯誤: {e}")
                continue
        
        return conversations
    except Exception as e:
        print(f"獲取對話列表時發生錯誤: {e}")
        return []  # 返回空列表而不是拋出錯誤