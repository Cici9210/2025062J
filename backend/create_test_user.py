from app.database import models, connection
from app.schemas.auth import UserCreate
from sqlalchemy.orm import Session

# 初始化數據庫
models.Base.metadata.create_all(bind=connection.engine)

# 建立連接
db = connection.SessionLocal()

# 直接創建用戶
test_user = models.User(
    email='test_demo@example.com',
    password_hash=''
)
db.add(test_user)
db.commit()
db.refresh(test_user)

print(f'已創建測試用戶: {test_user.email}, ID: {test_user.id}')

# 創建裝置
device1 = models.Device(device_uid='demo-device-001', user_id=test_user.id)
device2 = models.Device(device_uid='demo-device-002', user_id=test_user.id) 

db.add(device1)
db.add(device2)
db.commit()

print(f'已創建測試裝置: {device1.device_uid} (ID: {device1.id}), {device2.device_uid} (ID: {device2.id})')

# 關閉連接
db.close()
