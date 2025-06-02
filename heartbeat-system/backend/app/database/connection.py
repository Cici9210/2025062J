"""
資料庫連接設定 (connection.py)
功能: 設定 SQLAlchemy 連接、工作階段與基礎模型
相依: MySQL 8.0 資料庫
"""
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# 資料庫連接字串 (應該從環境變數取得)
SQLALCHEMY_DATABASE_URL = "mysql+mysqlconnector://2j113:2j113@localhost/heartbeat_db"

# 建立資料庫引擎
engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    pool_size=5,  # 連接池大小
    max_overflow=10,  # 超出連接池大小時的最大連接數
    pool_timeout=30,  # 連接池超時時間（秒）
    pool_recycle=1800  # 連接回收時間（秒）
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
