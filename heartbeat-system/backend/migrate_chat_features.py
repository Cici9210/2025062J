"""
資料庫遷移腳本 - 添加聊天室和好友邀請功能
執行方式: python migrate_chat_features.py
"""
import sys
import os

# 添加項目根目錄到路徑
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import create_engine, text
from app.database.connection import SQLALCHEMY_DATABASE_URL

def run_migration():
    engine = create_engine(SQLALCHEMY_DATABASE_URL)
    
    with engine.connect() as conn:
        print("開始遷移資料庫...")
        
        # 1. 為 Pairing 表添加 matched_at 欄位
        try:
            conn.execute(text("""
                ALTER TABLE pairings 
                ADD COLUMN matched_at TIMESTAMP
            """))
            conn.commit()
            print("✓ 已添加 pairings.matched_at")
        except Exception as e:
            print(f"  pairings.matched_at 可能已存在: {e}")
        
        # 2. 為 Message 表添加新欄位
        try:
            conn.execute(text("""
                ALTER TABLE messages 
                ADD COLUMN is_read BOOLEAN DEFAULT 0
            """))
            conn.commit()
            print("✓ 已添加 messages.is_read")
        except Exception as e:
            print(f"  messages.is_read 可能已存在: {e}")
        
        try:
            conn.execute(text("""
                ALTER TABLE messages 
                ADD COLUMN chat_room_id INTEGER
            """))
            conn.commit()
            print("✓ 已添加 messages.chat_room_id")
        except Exception as e:
            print(f"  messages.chat_room_id 可能已存在: {e}")
        
        # 3. 創建 ChatRoom 表
        try:
            conn.execute(text("""
                CREATE TABLE IF NOT EXISTS chat_rooms (
                    id INTEGER PRIMARY KEY AUTO_INCREMENT,
                    user_id_1 INTEGER NOT NULL,
                    user_id_2 INTEGER NOT NULL,
                    room_type VARCHAR(20) NOT NULL,
                    pairing_id INTEGER,
                    is_active BOOLEAN DEFAULT TRUE,
                    expires_at TIMESTAMP NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (user_id_1) REFERENCES users(id),
                    FOREIGN KEY (user_id_2) REFERENCES users(id),
                    FOREIGN KEY (pairing_id) REFERENCES pairings(id)
                )
            """))
            conn.commit()
            print("✓ 已創建 chat_rooms 表")
        except Exception as e:
            print(f"  chat_rooms 表可能已存在: {e}")
        
        # 4. 創建 FriendInvitation 表
        try:
            conn.execute(text("""
                CREATE TABLE IF NOT EXISTS friend_invitations (
                    id INTEGER PRIMARY KEY AUTO_INCREMENT,
                    chat_room_id INTEGER NOT NULL,
                    user_id_1 INTEGER NOT NULL,
                    user_id_2 INTEGER NOT NULL,
                    user_1_response VARCHAR(20),
                    user_2_response VARCHAR(20),
                    status VARCHAR(20) DEFAULT 'pending',
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    expires_at TIMESTAMP NOT NULL,
                    FOREIGN KEY (chat_room_id) REFERENCES chat_rooms(id),
                    FOREIGN KEY (user_id_1) REFERENCES users(id),
                    FOREIGN KEY (user_id_2) REFERENCES users(id)
                )
            """))
            conn.commit()
            print("✓ 已創建 friend_invitations 表")
        except Exception as e:
            print(f"  friend_invitations 表可能已存在: {e}")
        
        print("\n遷移完成!")
        print("\n新功能說明:")
        print("1. 配對成功後會自動創建5分鐘臨時聊天室")
        print("2. 5分鐘後會自動觸發好友邀請通知")
        print("3. 雙方都接受後會成為好友,聊天室升級為永久")
        print("4. 好友之間可以查看彼此的在線狀態")

if __name__ == "__main__":
    run_migration()
