"""
資料庫連接設定 (connection.py)
功能: 設定 SQLAlchemy 連接、工作階段與基礎模型
相依: MySQL 8.0 資料庫
"""
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# 資料庫連接字串 (使用 MySQL)
SQLALCHEMY_DATABASE_URL = "mysql+mysqlconnector://root:10856045@localhost/heartbeat_db"

# 建立資料庫引擎
engine = create_engine(
    SQLALCHEMY_DATABASE_URL
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
