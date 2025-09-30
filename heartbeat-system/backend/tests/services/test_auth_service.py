"""
認證服務測試 (test_auth_service.py)
功能: 測試使用者認證相關功能，包括註冊、登入和令牌驗證
相依: pytest、fastapi.testclient
"""
import pytest
from fastapi import HTTPException
from sqlalchemy.orm import Session
from jose import jwt

from app.services.auth_service import (
    get_user_by_email,
    create_user,
    authenticate_user,
    get_current_user,
)
from app.schemas.auth import UserCreate
from app.schemas.user import User, UserInDB
from tests.conftest import TEST_USER_EMAIL, TEST_USER_PASSWORD


class TestAuthService:
    """認證服務測試類"""
    
    def test_create_and_get_user(self, test_db: Session):
        """測試創建和獲取使用者"""
        # 創建使用者
        user_create = UserCreate(email=TEST_USER_EMAIL, password=TEST_USER_PASSWORD)
        created_user = create_user(test_db, user_create)
        
        # 確保創建成功
        assert created_user.email == TEST_USER_EMAIL
        assert created_user.password_hash is not None
        assert created_user.password_hash != TEST_USER_PASSWORD
        
        # 獲取使用者
        fetched_user = get_user_by_email(test_db, TEST_USER_EMAIL)
        
        # 確保獲取成功
        assert fetched_user is not None
        assert fetched_user.email == TEST_USER_EMAIL
        assert fetched_user.password_hash == created_user.password_hash
        
    def test_user_not_found(self, test_db: Session):
        """測試獲取不存在的使用者"""
        non_existent_email = "nonexistent@example.com"
        user = get_user_by_email(test_db, non_existent_email)
        assert user is None
    
    def test_authenticate_user_success(self, test_db: Session):
        """測試使用者認證成功"""
        # 創建使用者
        user_create = UserCreate(email=TEST_USER_EMAIL, password=TEST_USER_PASSWORD)
        create_user(test_db, user_create)
        
        # 認證使用者
        user = authenticate_user(test_db, TEST_USER_EMAIL, TEST_USER_PASSWORD)
        
        # 確保認證成功
        assert user is not None
        assert user.email == TEST_USER_EMAIL
    
    def test_authenticate_user_wrong_password(self, test_db: Session):
        """測試使用者認證失敗 (錯誤密碼)"""
        # 創建使用者
        user_create = UserCreate(email=TEST_USER_EMAIL, password=TEST_USER_PASSWORD)
        create_user(test_db, user_create)
        
        # 嘗試認證使用者 (錯誤密碼)
        user = authenticate_user(test_db, TEST_USER_EMAIL, "wrong_password")
        
        # 確保認證失敗
        assert user is False
    
    def test_authenticate_user_not_found(self, test_db: Session):
        """測試使用者認證失敗 (用戶不存在)"""
        # 嘗試認證不存在的使用者
        user = authenticate_user(test_db, "nonexistent@example.com", TEST_USER_PASSWORD)
        
        # 確保認證失敗
        assert user is False
    
    def test_get_current_user_with_valid_token(self, test_db: Session, monkeypatch):
        """測試使用有效令牌獲取當前使用者"""
        # 創建使用者
        user_create = UserCreate(email=TEST_USER_EMAIL, password=TEST_USER_PASSWORD)
        created_user = create_user(test_db, user_create)
        
        # 模擬 jwt.decode 函數的行為
        def mock_decode(*args, **kwargs):
            return {"sub": TEST_USER_EMAIL}
        
        # 套用模擬函數
        monkeypatch.setattr(jwt, "decode", mock_decode)
        
        # 獲取當前使用者
        user = get_current_user(test_db, "fake_token")
        
        # 確保獲取成功
        assert user is not None
        assert user.email == TEST_USER_EMAIL
        assert user.id == created_user.id
        
        # 確保獲取成功
        assert user is not None
        assert user.email == TEST_USER_EMAIL
