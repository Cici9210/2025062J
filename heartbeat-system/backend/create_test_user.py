from app.database import models, connection
from app.schemas.auth import UserCreate
from sqlalchemy.orm import Session

# ��l�Ƽƾڮw
models.Base.metadata.create_all(bind=connection.engine)

# �إ߳s��
db = connection.SessionLocal()

# �����ЫإΤ�
test_user = models.User(
    email='test_demo@example.com',
    password_hash=''
)
db.add(test_user)
db.commit()
db.refresh(test_user)

print(f'�w�Ыش��եΤ�: {test_user.email}, ID: {test_user.id}')

# �Ыظ˸m
device1 = models.Device(device_uid='demo-device-001', user_id=test_user.id)
device2 = models.Device(device_uid='demo-device-002', user_id=test_user.id) 

db.add(device1)
db.add(device2)
db.commit()

print(f'�w�Ыش��ո˸m: {device1.device_uid} (ID: {device1.id}), {device2.device_uid} (ID: {device2.id})')

# �����s��
db.close()
