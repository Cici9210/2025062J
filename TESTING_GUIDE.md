# 功能測試腳本

## 測試準備

### 1. 啟動後端
```bash
cd backend
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 2. 創建測試用戶
```bash
# 用戶A
curl -X POST http://192.168.1.114:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "test_a@example.com", "password": "Test123!"}'

# 用戶B  
curl -X POST http://192.168.1.114:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "test_b@example.com", "password": "Test123!"}'
```

### 3. 獲取Token
```bash
# 用戶A登入
curl -X POST http://192.168.1.114:8000/api/auth/token \
  -d "username=test_a@example.com&password=Test123!"

# 保存返回的 access_token 為 TOKEN_A

# 用戶B登入
curl -X POST http://192.168.1.114:8000/api/auth/token \
  -d "username=test_b@example.com&password=Test123!"

# 保存返回的 access_token 為 TOKEN_B
```

---

## 功能1：ESP32裝置連接測試

### 模擬ESP32註冊裝置
```bash
curl -X POST "http://192.168.1.114:8000/api/devices/register?device_uid=ESP32_TEST_001" \
  -H "Content-Type: application/json"

# 預期響應
{
  "id": 1,
  "device_uid": "ESP32_TEST_001",
  "name": "ESP32-T_001",
  "is_online": true,
  "message": "裝置註冊成功"
}
```

### 模擬ESP32上傳壓力數據
```bash
curl -X POST "http://192.168.1.114:8000/api/devices/pressure?device_uid=ESP32_TEST_001&pressure=75" \
  -H "Content-Type: application/json"

# 預期響應
{
  "id": 1,
  "device_id": 1,
  "pressure_value": 75,
  "timestamp": "2025-01-15T10:30:00",
  "message": "壓力數據儲存成功"
}
```

### 用戶綁定裝置
```bash
curl -X POST "http://192.168.1.114:8000/api/devices/bind?device_uid=ESP32_TEST_001&name=我的心跳裝置" \
  -H "Authorization: Bearer $TOKEN_A"

# 預期響應
{
  "id": 1,
  "device_uid": "ESP32_TEST_001",
  "name": "我的心跳裝置",
  "is_online": true
}
```

### 獲取我的裝置
```bash
curl http://192.168.1.114:8000/api/devices/my \
  -H "Authorization: Bearer $TOKEN_A"

# 預期響應
[
  {
    "id": 1,
    "device_uid": "ESP32_TEST_001",
    "name": "我的心跳裝置",
    "is_online": true,
    "last_active": "2025-01-15T10:30:00"
  }
]
```

---

## 功能2：隨機配對測試

### 用戶A請求隨機配對
```bash
curl -X POST http://192.168.1.114:8000/api/pairing/random-match \
  -H "Authorization: Bearer $TOKEN_A"

# 第一次請求（無其他用戶等待）
{
  "matched": false,
  "message": "已加入配對隊列,請稍候..."
}
```

### 用戶B請求隨機配對
```bash
curl -X POST http://192.168.1.114:8000/api/pairing/random-match \
  -H "Authorization: Bearer $TOKEN_B"

# 第二次請求（匹配到用戶A）
{
  "matched": true,
  "pairing_id": 1,
  "other_user_id": <用戶A的ID>,
  "other_user_email": "test_a@example.com",
  "chat_room_id": 1,
  "message": "配對成功!已創建臨時聊天室"
}
```

### 查看我的聊天室
```bash
curl http://192.168.1.114:8000/api/pairing/chat-rooms \
  -H "Authorization: Bearer $TOKEN_A"

# 預期響應
[
  {
    "id": 1,
    "room_type": "temporary",
    "is_active": true,
    "expires_at": "2025-01-15T10:35:00",  # 5分鐘後
    "created_at": "2025-01-15T10:30:00",
    "other_user_id": <用戶B的ID>,
    "other_user_email": "test_b@example.com",
    "is_friend": false
  }
]
```

---

## 功能3：臨時聊天室測試

### 檢查聊天室是否過期（30秒後測試）
```bash
# 等待30秒（測試模式）或5分鐘（生產模式）

curl -X POST http://192.168.1.114:8000/api/pairing/chat-room/1/check-expiry \
  -H "Authorization: Bearer $TOKEN_A"

# 未過期時
{
  "expired": false,
  "invitation_created": false
}

# 過期後
{
  "expired": true,
  "invitation_created": true,
  "invitation_id": 1
}
```

---

## 功能4：好友功能測試

### 查看好友邀請
```bash
curl http://192.168.1.114:8000/api/pairing/invitations \
  -H "Authorization: Bearer $TOKEN_A"

# 預期響應
[
  {
    "id": 1,
    "chat_room_id": 1,
    "other_user_id": <用戶B的ID>,
    "other_user_email": "test_b@example.com",
    "my_response": null,
    "other_response": null,
    "status": "pending",
    "created_at": "2025-01-15T10:35:00",
    "expires_at": "2025-01-16T10:35:00",
    "time_remaining": 86400  # 24小時
  }
]
```

### 用戶A接受邀請
```bash
curl -X POST http://192.168.1.114:8000/api/pairing/invitations/1/respond \
  -H "Authorization: Bearer $TOKEN_A" \
  -H "Content-Type: application/json" \
  -d '{"response": "accept"}'

# 預期響應
{
  "success": true,
  "became_friends": false,
  "message": "已記錄您的回應: accept"
}
```

### 用戶B接受邀請
```bash
curl -X POST http://192.168.1.114:8000/api/pairing/invitations/1/respond \
  -H "Authorization: Bearer $TOKEN_B" \
  -H "Content-Type: application/json" \
  -d '{"response": "accept"}'

# 預期響應（雙方都接受）
{
  "success": true,
  "became_friends": true,
  "friendship_id": 1,
  "message": "雙方都接受邀請,已成為好友!"
}
```

### 查看好友列表
```bash
curl http://192.168.1.114:8000/api/pairing/friends \
  -H "Authorization: Bearer $TOKEN_A"

# 預期響應
[
  {
    "user_id": <用戶B的ID>,
    "email": "test_b@example.com",
    "is_online": false,
    "last_seen": null
  }
]
```

### 檢查聊天室是否升級為永久
```bash
curl http://192.168.1.114:8000/api/pairing/chat-rooms \
  -H "Authorization: Bearer $TOKEN_A"

# 預期響應（room_type已變為permanent）
[
  {
    "id": 1,
    "room_type": "permanent",  # 已升級
    "is_active": true,
    "expires_at": null,  # 不再過期
    "created_at": "2025-01-15T10:30:00",
    "other_user_id": <用戶B的ID>,
    "other_user_email": "test_b@example.com",
    "is_friend": true  # 現在是好友
  }
]
```

### 查看好友裝置狀態
```bash
# 首先用戶B綁定一個裝置
curl -X POST "http://192.168.1.114:8000/api/devices/register?device_uid=ESP32_TEST_002"
curl -X POST "http://192.168.1.114:8000/api/devices/bind?device_uid=ESP32_TEST_002&name=用戶B的裝置" \
  -H "Authorization: Bearer $TOKEN_B"

# 用戶A查看好友裝置狀態
curl http://192.168.1.114:8000/api/devices/friends/devices \
  -H "Authorization: Bearer $TOKEN_A"

# 預期響應
[
  {
    "friend_id": <用戶B的ID>,
    "friend_email": "test_b@example.com",
    "device_id": 2,
    "device_uid": "ESP32_TEST_002",
    "device_name": "用戶B的裝置",
    "is_online": true,
    "last_active": "2025-01-15T10:40:00",
    "latest_pressure": 75,
    "latest_timestamp": "2025-01-15T10:40:00"
  }
]
```

### 查看好友裝置壓力數據
```bash
curl http://192.168.1.114:8000/api/devices/pressure/2?minutes=5 \
  -H "Authorization: Bearer $TOKEN_A"

# 預期響應（最近5分鐘的數據）
[
  {
    "id": 1,
    "pressure_value": 75,
    "timestamp": "2025-01-15T10:40:00"
  },
  {
    "id": 2,
    "pressure_value": 80,
    "timestamp": "2025-01-15T10:40:05"
  }
]
```

---

## 完整測試流程

### PowerShell測試腳本
```powershell
# 設置變量
$API_URL = "http://192.168.1.114:8000"

# 1. 註冊用戶
$userA = Invoke-RestMethod -Uri "$API_URL/api/auth/register" -Method POST -Body (@{email="test_a@example.com"; password="Test123!"} | ConvertTo-Json) -ContentType "application/json"
$userB = Invoke-RestMethod -Uri "$API_URL/api/auth/register" -Method POST -Body (@{email="test_b@example.com"; password="Test123!"} | ConvertTo-Json) -ContentType "application/json"

# 2. 登入獲取Token
$tokenA = (Invoke-RestMethod -Uri "$API_URL/api/auth/token" -Method POST -Body "username=test_a@example.com&password=Test123!" -ContentType "application/x-www-form-urlencoded").access_token
$tokenB = (Invoke-RestMethod -Uri "$API_URL/api/auth/token" -Method POST -Body "username=test_b@example.com&password=Test123!" -ContentType "application/x-www-form-urlencoded").access_token

Write-Host "Token A: $tokenA"
Write-Host "Token B: $tokenB"

# 3. 隨機配對
$matchA = Invoke-RestMethod -Uri "$API_URL/api/pairing/random-match" -Method POST -Headers @{Authorization="Bearer $tokenA"}
Write-Host "User A matching..." -ForegroundColor Yellow
Write-Host ($matchA | ConvertTo-Json)

Start-Sleep -Seconds 2

$matchB = Invoke-RestMethod -Uri "$API_URL/api/pairing/random-match" -Method POST -Headers @{Authorization="Bearer $tokenB"}
Write-Host "User B matching..." -ForegroundColor Yellow
Write-Host ($matchB | ConvertTo-Json)

# 4. 查看聊天室
$rooms = Invoke-RestMethod -Uri "$API_URL/api/pairing/chat-rooms" -Method GET -Headers @{Authorization="Bearer $tokenA"}
Write-Host "Chat rooms:" -ForegroundColor Green
Write-Host ($rooms | ConvertTo-Json)

Write-Host "`nWaiting 30 seconds for chat room to expire..." -ForegroundColor Cyan
Start-Sleep -Seconds 30

# 5. 檢查過期並創建邀請
$chatRoomId = $rooms[0].id
$expiry = Invoke-RestMethod -Uri "$API_URL/api/pairing/chat-room/$chatRoomId/check-expiry" -Method POST -Headers @{Authorization="Bearer $tokenA"}
Write-Host "Chat room expiry check:" -ForegroundColor Green
Write-Host ($expiry | ConvertTo-Json)

# 6. 查看邀請
$invitations = Invoke-RestMethod -Uri "$API_URL/api/pairing/invitations" -Method GET -Headers @{Authorization="Bearer $tokenA"}
Write-Host "Friend invitations:" -ForegroundColor Green
Write-Host ($invitations | ConvertTo-Json)

# 7. 雙方接受邀請
$invitationId = $invitations[0].id
$acceptA = Invoke-RestMethod -Uri "$API_URL/api/pairing/invitations/$invitationId/respond" -Method POST -Headers @{Authorization="Bearer $tokenA"} -Body (@{response="accept"} | ConvertTo-Json) -ContentType "application/json"
Write-Host "User A accepts:" -ForegroundColor Yellow
Write-Host ($acceptA | ConvertTo-Json)

$acceptB = Invoke-RestMethod -Uri "$API_URL/api/pairing/invitations/$invitationId/respond" -Method POST -Headers @{Authorization="Bearer $tokenB"} -Body (@{response="accept"} | ConvertTo-Json) -ContentType "application/json"
Write-Host "User B accepts:" -ForegroundColor Yellow
Write-Host ($acceptB | ConvertTo-Json)

# 8. 查看好友列表
$friends = Invoke-RestMethod -Uri "$API_URL/api/pairing/friends" -Method GET -Headers @{Authorization="Bearer $tokenA"}
Write-Host "Friends list:" -ForegroundColor Green
Write-Host ($friends | ConvertTo-Json)

# 9. 查看聊天室是否升級為永久
$permanentRooms = Invoke-RestMethod -Uri "$API_URL/api/pairing/chat-rooms" -Method GET -Headers @{Authorization="Bearer $tokenA"}
Write-Host "Chat rooms (should be permanent now):" -ForegroundColor Green
Write-Host ($permanentRooms | ConvertTo-Json)

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
```

---

## 測試檢查清單

- [ ] ESP32裝置註冊成功
- [ ] ESP32壓力數據上傳成功
- [ ] 用戶可以綁定裝置
- [ ] 隨機配對成功創建臨時聊天室
- [ ] 臨時聊天室30秒後過期
- [ ] 過期後自動創建好友邀請
- [ ] 雙方接受邀請後成為好友
- [ ] 臨時聊天室升級為永久聊天室
- [ ] 好友可以查看對方裝置狀態
- [ ] 好友可以查看對方壓力數據

---

## 故障排除

### 問題：後端無法啟動
解決：檢查數據庫連接和端口占用
```bash
# 檢查端口
netstat -an | findstr :8000

# 重啟數據庫
net start MySQL80
```

### 問題：ESP32無法連接
解決：
1. 檢查WiFi配置
2. 檢查API_SERVER IP地址
3. 確認後端正在運行

### 問題：配對失敗
解決：檢查用戶Token是否有效
```bash
curl http://192.168.1.114:8000/api/users/me \
  -H "Authorization: Bearer $TOKEN"
```

### 問題：數據庫錯誤
解決：重新創建數據庫表
```bash
cd backend
python -c "from app.database.models import Base; from app.database.connection import engine; Base.metadata.drop_all(bind=engine); Base.metadata.create_all(bind=engine)"
```
