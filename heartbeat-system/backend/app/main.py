"""
主程式檔案 (main.py)
功能: 定義 FastAPI 主應用程式、路由和WebSocket連接
執行方式: uvicorn app.main:app --reload
"""
from fastapi import FastAPI, Depends, HTTPException, status, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from typing import List

from .database import models, connection
from .schemas import auth, user, device, interaction, friend
from .services import auth_service, device_service, websocket_service
from .utils import security

# 初始化資料庫
models.Base.metadata.create_all(bind=connection.engine)

app = FastAPI(title="心臟壓感互動系統 API", description="壓感互動裝置後端服務")

# 配置 CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 實際部署時應限制來源
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 配置 JSON Response 處理中文
from fastapi.responses import JSONResponse
from fastapi.encoders import jsonable_encoder
from starlette.exceptions import HTTPException as StarletteHTTPException

@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request, exc):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": str(exc.detail)},
        media_type="application/json; charset=utf-8",
    )

# 請求處理中間件-處理請求前的設置，確保中文正確處理
@app.middleware("http")
async def handle_encoding(request, call_next):
    response = await call_next(request)
    return response

# 相依注入 - 獲取資料庫會話
def get_db():
    db = connection.SessionLocal()
    try:
        yield db
    finally:
        db.close()

# 認證相關端點
@app.post("/api/auth/register", response_model=user.User)
def register_user(user_data: auth.UserCreate, db: Session = Depends(get_db)):
    db_user = auth_service.get_user_by_email(db, email=user_data.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    return auth_service.create_user(db=db, user=user_data)

@app.post("/api/auth/token", response_model=auth.Token)
def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = auth_service.authenticate_user(db, form_data.username, form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = security.create_access_token(data={"sub": user.email})
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/api/users/me", response_model=user.User)
def get_current_user_info(current_user: models.User = Depends(auth_service.get_current_user)):
    """獲取當前登入使用者的資料"""
    return current_user

# 裝置相關端點
@app.post("/api/devices/bind", response_model=device.Device)
def bind_device(device_data: device.DeviceBind, db: Session = Depends(get_db), 
                current_user: models.User = Depends(auth_service.get_current_user)):
    return device_service.bind_device(db=db, device_uid=device_data.device_uid, user_id=current_user.id)

@app.get("/api/devices/status/{device_id}", response_model=device.DeviceStatus)
def get_device_status(device_id: int, db: Session = Depends(get_db),
                      current_user: models.User = Depends(auth_service.get_current_user)):
    return device_service.get_device_status(db=db, device_id=device_id, user_id=current_user.id)

# 互動相關端點
@app.post("/api/interactions/record", response_model=interaction.Interaction)
def record_interaction(interaction_data: interaction.InteractionCreate, db: Session = Depends(get_db),
                       current_user: models.User = Depends(auth_service.get_current_user)):
    return device_service.record_interaction(db=db, interaction=interaction_data, user_id=current_user.id)

# WebSocket 連接管理
connection_manager = websocket_service.ConnectionManager()

@app.websocket("/ws/{client_id}")
async def websocket_endpoint(websocket: WebSocket, client_id: str, db: Session = Depends(get_db)):
    await connection_manager.connect(websocket, client_id)
    try:
        while True:
            data = await websocket.receive_json()
            # 處理接收到的資料
            await connection_manager.process_message(client_id, data, db)
    except WebSocketDisconnect:
        connection_manager.disconnect(client_id)

# 配對相關端點
@app.post("/api/pairing/request", response_model=interaction.PairingResponse)
def request_pairing(pairing_data: interaction.PairingRequest, db: Session = Depends(get_db),
                   current_user: models.User = Depends(auth_service.get_current_user)):
    return device_service.create_pairing_request(db=db, pairing=pairing_data, user_id=current_user.id)

@app.post("/api/pairing/random", response_model=interaction.PairingResponse)
def random_pairing(db: Session = Depends(get_db),
                  current_user: models.User = Depends(auth_service.get_current_user)):
    return device_service.create_random_pairing(db=db, user_id=current_user.id)

# 好友相關端點
@app.get("/api/friends", response_model=List[user.UserWithStatus])
def get_friends(db: Session = Depends(get_db),
               current_user: models.User = Depends(auth_service.get_current_user)):
    return device_service.get_friends(db=db, user_id=current_user.id)

@app.get("/api/friends/requests/pending", response_model=List[friend.FriendRequest])
def get_pending_requests(db: Session = Depends(get_db),
                        current_user: models.User = Depends(auth_service.get_current_user)):
    """獲取待處理的好友請求"""
    return device_service.get_pending_requests(db=db, user_id=current_user.id)

@app.post("/api/friends/request", response_model=friend.FriendRequestResponse)
def create_friend_request(friend_data: friend.FriendRequestCreate, db: Session = Depends(get_db),
                          current_user: models.User = Depends(auth_service.get_current_user)):
    """創建好友請求"""
    return device_service.create_friend_request(db=db, friend_request=friend_data, user_id=current_user.id)

@app.post("/api/friends/request/{request_id}/accept", response_model=friend.FriendRequestResponse)
def accept_friend_request(request_id: int, db: Session = Depends(get_db),
                          current_user: models.User = Depends(auth_service.get_current_user)):
    """接受好友請求"""
    return device_service.accept_friend_request(db=db, request_id=request_id, user_id=current_user.id)

@app.post("/api/friends/request/{request_id}/reject", response_model=friend.FriendRequestResponse)
def reject_friend_request(request_id: int, db: Session = Depends(get_db),
                          current_user: models.User = Depends(auth_service.get_current_user)):
    """拒絕好友請求"""
    return device_service.reject_friend_request(db=db, request_id=request_id, user_id=current_user.id)

@app.delete("/api/friends/{friend_id}", status_code=204)
def remove_friend(friend_id: int, db: Session = Depends(get_db),
                  current_user: models.User = Depends(auth_service.get_current_user)):
    """移除好友"""
    device_service.remove_friend(db=db, friend_id=friend_id, user_id=current_user.id)
    return {"status": "success"}

# 健康檢查端點
@app.get("/health")
def health_check():
    return {"status": "healthy"}
