"""
測試配置 (conftest.py)
功能: 提供測試所需的固定裝置和設置
相依: pytest、FastAPI、SQLAlchemy
"""

import sys
import os
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from fastapi.testclient import TestClient

# 將專案根目錄添加到Python路徑
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# 測試用的資料庫URL (使用SQLite記憶體數據庫)
TEST_DATABASE_URL = "sqlite:///:memory:"

# 測試用的密鑰
TEST_SECRET_KEY = "test_secret_key_for_testing_purposes_only"
TEST_ALGORITHM = "HS256"
TEST_ACCESS_TOKEN_EXPIRE_MINUTES = 30

# 測試用戶資料
TEST_USER_EMAIL = "test@example.com"
TEST_USER_PASSWORD = "testpassword123"

# 導入應用程序相依項
from app.database.connection import get_db
from app.database.models import Base
from app.main import app

# 創建測試數據庫引擎
@pytest.fixture
def test_db():
    """設置測試數據庫"""
    # 創建內存數據庫引擎
    engine = create_engine(
        TEST_DATABASE_URL,
        connect_args={"check_same_thread": False},
        poolclass=StaticPool
    )
    
    # 創建數據庫表
    Base.metadata.create_all(bind=engine)
    
    # 創建測試會話
    TestSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    
    # 使用上下文管理器確保會話在測試後關閉
    with TestSessionLocal() as db:
        yield db
    
    # 測試後刪除數據庫表
    Base.metadata.drop_all(bind=engine)


@pytest.fixture
def client(test_db):
    """設置測試客戶端"""
    # 覆蓋依賴項
    def override_get_db():
        try:
            yield test_db
        finally:
            pass
    
    app.dependency_overrides[get_db] = override_get_db
    
    # 創建測試客戶端
    from fastapi.testclient import TestClient
    with TestClient(app) as c:
        yield c
    
    # 測試後恢復依賴項
    app.dependency_overrides = {}


@pytest.fixture
def test_user(client):
    """創建測試用戶"""
    # 註冊測試用戶
    response = client.post(
        "/api/auth/register",
        json={"email": TEST_USER_EMAIL, "password": TEST_USER_PASSWORD}
    )
    assert response.status_code == 200
    
    # 登錄並獲取訪問令牌
    response = client.post(
        "/api/auth/token",
        data={"username": TEST_USER_EMAIL, "password": TEST_USER_PASSWORD},
        headers={"Content-Type": "application/x-www-form-urlencoded"}
    )
    assert response.status_code == 200
    
    return response.json()
