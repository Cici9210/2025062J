# 單裝置測試指南 - 配對聊天功能

## 📱 只有一台手機如何測試?

即使只有一台裝置,您也可以完整測試配對聊天功能!

---

## 方法 1: 使用兩個瀏覽器標籤 (推薦)

### 步驟:

1️⃣ **創建兩個測試帳號**

在同一台電腦上,使用 API 或前端創建兩個帳號:

```bash
# 使用 PowerShell 創建帳號
# 帳號 A
curl http://localhost:8000/api/auth/register -Method POST -Headers @{"Content-Type"="application/json"} -Body '{"email":"userA@test.com","password":"Test123!"}'

# 帳號 B  
curl http://localhost:8000/api/auth/register -Method POST -Headers @{"Content-Type"="application/json"} -Body '{"email":"userB@test.com","password":"Test123!"}'
```

2️⃣ **在手機 Safari 上開啟兩個標籤**

- **標籤 1**: 登入 userA@test.com
- **標籤 2**: 登入 userB@test.com (點擊右下角標籤圖示 → 新增標籤)

3️⃣ **模擬配對流程**

在標籤 1 (User A):
- 發起配對請求給 User B
- 系統自動創建 5 分鐘臨時聊天室

在標籤 2 (User B):
- 接受配對
- 進入臨時聊天室

4️⃣ **切換標籤測試聊天**

- 標籤 1 → 發送訊息
- 切換到標籤 2 → 查看訊息
- 標籤 2 → 回覆訊息  
- 切換到標籤 1 → 查看回覆

5️⃣ **測試 5 分鐘倒計時**

- 觀察聊天室頂部的倒計時
- 等待或手動觸發過期檢查

6️⃣ **測試好友邀請**

在標籤 1:
- 查看好友邀請通知
- 點擊 [接受]

在標籤 2:
- 查看好友邀請通知
- 點擊 [接受]

7️⃣ **確認成為好友**

- 雙方都接受後,聊天室升級為永久
- 在好友列表中看到對方
- 可以查看在線狀態

---

## 方法 2: 使用 API 直接測試 (開發者模式)

如果前端還沒實現,可以用 API 直接測試後端邏輯:

### 準備工作

```powershell
# 先獲取兩個帳號的 token
$tokenA = (curl http://localhost:8000/api/auth/token -Method POST -Headers @{"Content-Type"="application/x-www-form-urlencoded"} -Body "username=userA@test.com&password=Test123!" | ConvertFrom-Json).access_token

$tokenB = (curl http://localhost:8000/api/auth/token -Method POST -Headers @{"Content-Type"="application/x-www-form-urlencoded"} -Body "username=userB@test.com&password=Test123!" | ConvertFrom-Json).access_token

# 獲取 User B 的 ID (需要先實現獲取用戶列表 API,或直接查資料庫)
# 假設 User A 的 ID 是 1, User B 的 ID 是 2
```

### 測試流程

#### 1. User A 創建配對 (自動創建 5 分鐘聊天室)

```powershell
curl http://localhost:8000/api/pairing/match `
  -Method POST `
  -Headers @{
    "Authorization"="Bearer $tokenA"
    "Content-Type"="application/json"
  } `
  -Body '{"target_user_id":2}'
```

**預期結果:**
```json
{
  "id": 1,
  "user_id_1": 1,
  "user_id_2": 2,
  "status": "active",
  "matched_at": "2025-10-08T17:00:00"
}
```

#### 2. User A 查看聊天室

```powershell
curl http://localhost:8000/api/pairing/chat-rooms `
  -Headers @{"Authorization"="Bearer $tokenA"}
```

**預期結果:**
```json
[
  {
    "id": 1,
    "room_type": "temporary",
    "is_active": true,
    "expires_at": "2025-10-08T17:05:00",
    "other_user_id": 2,
    "other_user_email": "userB@test.com",
    "is_friend": false
  }
]
```

#### 3. User B 也查看聊天室

```powershell
curl http://localhost:8000/api/pairing/chat-rooms `
  -Headers @{"Authorization"="Bearer $tokenB"}
```

#### 4. 檢查聊天室過期 (手動觸發,模擬 5 分鐘後)

```powershell
# User A 檢查
curl http://localhost:8000/api/pairing/chat-room/1/check-expiry `
  -Method POST `
  -Headers @{"Authorization"="Bearer $tokenA"}
```

**如果還沒過期:**
```json
{
  "expired": false,
  "invitation_created": false
}
```

**如果已過期 (5 分鐘後):**
```json
{
  "expired": true,
  "invitation_created": true,
  "invitation_id": 1
}
```

#### 5. 查看好友邀請

```powershell
# User A 查看
curl http://localhost:8000/api/pairing/invitations `
  -Headers @{"Authorization"="Bearer $tokenA"}

# User B 查看
curl http://localhost:8000/api/pairing/invitations `
  -Headers @{"Authorization"="Bearer $tokenB"}
```

**預期結果:**
```json
[
  {
    "id": 1,
    "other_user_id": 2,
    "other_user_email": "userB@test.com",
    "my_response": null,
    "other_response": null,
    "status": "pending",
    "time_remaining": 86400
  }
]
```

#### 6. User A 接受邀請

```powershell
curl http://localhost:8000/api/pairing/invitations/1/respond `
  -Method POST `
  -Headers @{
    "Authorization"="Bearer $tokenA"
    "Content-Type"="application/json"
  } `
  -Body '{"response":"accept"}'
```

**預期結果:**
```json
{
  "success": true,
  "became_friends": false,
  "message": "已記錄您的回應: accept"
}
```

#### 7. User B 也接受邀請 (雙方都接受後成為好友)

```powershell
curl http://localhost:8000/api/pairing/invitations/1/respond `
  -Method POST `
  -Headers @{
    "Authorization"="Bearer $tokenB"
    "Content-Type"="application/json"
  } `
  -Body '{"response":"accept"}'
```

**預期結果:**
```json
{
  "success": true,
  "became_friends": true,
  "friendship_id": 1,
  "message": "雙方都接受邀請,已成為好友!"
}
```

#### 8. 確認聊天室升級為永久

```powershell
# User A 再次查看聊天室
curl http://localhost:8000/api/pairing/chat-rooms `
  -Headers @{"Authorization"="Bearer $tokenA"}
```

**預期結果:**
```json
[
  {
    "id": 1,
    "room_type": "permanent",  // 已升級!
    "is_active": true,
    "expires_at": null,  // 不再過期!
    "other_user_id": 2,
    "other_user_email": "userB@test.com",
    "is_friend": true  // 已是好友!
  }
]
```

#### 9. 查看好友列表

```powershell
curl http://localhost:8000/api/pairing/friends `
  -Headers @{"Authorization"="Bearer $tokenA"}
```

**預期結果:**
```json
[
  {
    "user_id": 2,
    "email": "userB@test.com",
    "is_online": false,
    "last_seen": null
  }
]
```

---

## 方法 3: 使用資料庫直接驗證

如果 API 有問題,可以直接查資料庫:

```sql
-- 查看配對
SELECT * FROM pairings;

-- 查看聊天室
SELECT * FROM chat_rooms;

-- 查看好友邀請
SELECT * FROM friend_invitations;

-- 查看好友關係
SELECT * FROM friendships;

-- 查看訊息
SELECT * FROM messages;
```

---

## 🔧 快速測試腳本

我為您創建一個 PowerShell 腳本來自動化測試:

```powershell
# test_pairing_flow.ps1

# 1. 創建兩個測試帳號
Write-Host "1. 創建測試帳號..."
curl http://localhost:8000/api/auth/register -Method POST -Headers @{"Content-Type"="application/json"} -Body '{"email":"userA@test.com","password":"Test123!"}' | Out-Null
curl http://localhost:8000/api/auth/register -Method POST -Headers @{"Content-Type"="application/json"} -Body '{"email":"userB@test.com","password":"Test123!"}' | Out-Null

# 2. 登入獲取 token
Write-Host "2. 獲取登入 token..."
$tokenA = (curl http://localhost:8000/api/auth/token -Method POST -Headers @{"Content-Type"="application/x-www-form-urlencoded"} -Body "username=userA@test.com&password=Test123!" | ConvertFrom-Json).access_token
$tokenB = (curl http://localhost:8000/api/auth/token -Method POST -Headers @{"Content-Type"="application/x-www-form-urlencoded"} -Body "username=userB@test.com&password=Test123!" | ConvertFrom-Json).access_token

# 3. User A 創建配對
Write-Host "3. User A 創建配對..."
$pairing = curl http://localhost:8000/api/pairing/match -Method POST -Headers @{"Authorization"="Bearer $tokenA"; "Content-Type"="application/json"} -Body '{"target_user_id":2}' | ConvertFrom-Json
Write-Host "配對成功! ID: $($pairing.id)"

# 4. 查看聊天室
Write-Host "4. 查看聊天室..."
$rooms = curl http://localhost:8000/api/pairing/chat-rooms -Headers @{"Authorization"="Bearer $tokenA"} | ConvertFrom-Json
Write-Host "聊天室類型: $($rooms[0].room_type), 過期時間: $($rooms[0].expires_at)"

# 5. 檢查過期
Write-Host "5. 檢查過期狀態..."
$expiry = curl http://localhost:8000/api/pairing/chat-room/1/check-expiry -Method POST -Headers @{"Authorization"="Bearer $tokenA"} | ConvertFrom-Json
Write-Host "已過期: $($expiry.expired)"

# 6. 如果已創建邀請,則雙方接受
if ($expiry.invitation_created) {
    Write-Host "6. 雙方接受好友邀請..."
    curl http://localhost:8000/api/pairing/invitations/1/respond -Method POST -Headers @{"Authorization"="Bearer $tokenA"; "Content-Type"="application/json"} -Body '{"response":"accept"}' | Out-Null
    $result = curl http://localhost:8000/api/pairing/invitations/1/respond -Method POST -Headers @{"Authorization"="Bearer $tokenB"; "Content-Type"="application/json"} -Body '{"response":"accept"}' | ConvertFrom-Json
    Write-Host "成為好友: $($result.became_friends)"
}

# 7. 最終確認
Write-Host "7. 最終確認..."
$friends = curl http://localhost:8000/api/pairing/friends -Headers @{"Authorization"="Bearer $tokenA"} | ConvertFrom-Json
Write-Host "好友數量: $($friends.Count)"
$finalRooms = curl http://localhost:8000/api/pairing/chat-rooms -Headers @{"Authorization"="Bearer $tokenA"} | ConvertFrom-Json
Write-Host "聊天室類型: $($finalRooms[0].room_type)"

Write-Host "測試完成!"
```

---

## 📋 測試檢查清單

用這個清單確保所有功能都測試過:

- [ ] 創建配對成功
- [ ] 自動創建臨時聊天室
- [ ] 聊天室類型為 "temporary"
- [ ] expires_at 為 5 分鐘後
- [ ] 可以查看對方的聊天室
- [ ] 5 分鐘後觸發好友邀請
- [ ] 雙方可以看到邀請
- [ ] User A 接受邀請
- [ ] User B 接受邀請
- [ ] 雙方都接受後成為好友
- [ ] 聊天室升級為 "permanent"
- [ ] expires_at 變為 null
- [ ] is_friend 變為 true
- [ ] 好友列表中有對方

---

## ⚠️ 注意事項

1. **時間設定**: 如果不想等 5 分鐘,可以修改:
   ```python
   # backend/app/services/pairing_service.py 第 52 行
   expires_at = datetime.now() + timedelta(seconds=30)  # 改為 30 秒測試
   ```

2. **手動觸發過期**: 不用等時間到,直接調用 check-expiry API

3. **資料庫重置**: 測試前可能需要清空舊資料:
   ```sql
   DELETE FROM friend_invitations;
   DELETE FROM chat_rooms;
   DELETE FROM pairings;
   DELETE FROM friendships;
   ```

---

## 🎯 下一步

測試完後端邏輯後,您可以:
1. 開始實現前端 UI
2. 添加倒計時顯示
3. 實現好友邀請通知彈窗
4. 整合到現有的配對流程

祝測試順利! 🚀
