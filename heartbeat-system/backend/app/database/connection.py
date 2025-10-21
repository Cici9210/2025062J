"""
資料庫連接設定 (connection.py)
功能: 設定 SQLAlchemy 連接、工作階段與基礎模型
相依: PostgreSQL/MySQL 資料庫
"""
import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# 資料庫連接字串
# 優先使用環境變數 DATABASE_URL (用於 Render 等雲端平台)
# 否則使用本地 MySQL
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "mysql+mysqlconnector://root:10856045@localhost/heartbeat_db"
)

# 如果是 PostgreSQL URL，確保使用正確的驅動
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

# 建立資料庫引擎
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,  # 確保連接有效
    pool_recycle=300,    # 每 5 分鐘回收連接
)

# 建立工作階段工廠
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# 宣告映射基底類別
Base = declarative_base()

# 依賴注入函數
def get_db():
    """獲取資料庫會話"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
