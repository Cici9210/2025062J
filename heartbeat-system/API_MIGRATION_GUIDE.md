# API 端點遷移指南

## 📌 重要更新說明

由於配對和好友功能的重構,部分 API 端點已經更新。請使用新的端點以獲得完整功能。

---

## 🔄 端點對應表

### 配對相關

| 舊端點 (已廢棄) | 新端點 | 說明 |
|----------------|--------|------|
| `POST /api/pairing/request` | `POST /api/pairing/match` | 創建配對 (自動創建臨時聊天室) |
| `POST /api/pairing/random` | *(暫無)* | 隨機配對 (待實現) |

**新端點額外功能:**
- 配對成功後自動創建 30 秒臨時聊天室
- 返回配對 ID 和狀態

### 好友相關

| 舊端點 (已廢棄) | 新端點 | 說明 |
|----------------|--------|------|
| `GET /api/friends` | `GET /api/pairing/friends` | 獲取好友列表 |
| `GET /api/friends/requests/pending` | `GET /api/pairing/invitations` | 獲取待處理的好友邀請 |
| `POST /api/friends/request` | *(自動觸發)* | 臨時聊天室過期後自動創建邀請 |
| `POST /api/friends/request/{id}/accept` | `POST /api/pairing/invitations/{id}/respond` | 回應好友邀請 |
| `POST /api/friends/request/{id}/reject` | `POST /api/pairing/invitations/{id}/respond` | 回應好友邀請 |
| `DELETE /api/friends/{id}` | *(待實現)* | 移除好友 |

**新端點額外功能:**
- 包含在線狀態 (is_online)
- 包含好友邀請過期時間
- 雙方接受後自動升級聊天室為永久

### 聊天室相關 (新增)

| 端點 | 說明 |
|------|------|
| `GET /api/pairing/chat-rooms` | 獲取我的所有聊天室 (臨時+永久) |
| `GET /api/pairing/chat-room/{user_id}` | 獲取與特定用戶的聊天室 |
| `POST /api/pairing/chat-room/{id}/check-expiry` | 檢查聊天室是否過期並觸發邀請 |

---

## 📋 新的工作流程

### 1. 配對流程

```
創建配對 → 自動創建臨時聊天室 (30秒) → 聊天互動
```

**API 調用:**
```http
POST /api/pairing/match
{
  "target_user_id": 2
}
```

**返回:**
```json
{
  "id": 1,
  "user_id_1": 1,
  "user_id_2": 2,
  "status": "active",
  "created_at": "2025-10-08T10:00:00",
  "matched_at": "2025-10-08T10:00:00"
}
```

### 2. 聊天室查詢

```http
GET /api/pairing/chat-rooms
```

**返回:**
```json
[
  {
    "id": 1,
    "room_type": "temporary",
    "is_active": true,
    "expires_at": "2025-10-08T10:00:30",
    "created_at": "2025-10-08T10:00:00",
    "other_user_id": 2,
    "other_user_email": "user2@example.com",
    "is_friend": false
  }
]
```

### 3. 好友邀請流程

**等待 30 秒後檢查過期:**
```http
POST /api/pairing/chat-room/1/check-expiry
```

**返回:**
```json
{
  "expired": true,
  "invitation_created": true,
  "invitation_id": 1
}
```

**查詢好友邀請:**
```http
GET /api/pairing/invitations
```

**返回:**
```json
[
  {
    "id": 1,
    "chat_room_id": 1,
    "other_user_id": 2,
    "other_user_email": "user2@example.com",
    "my_response": null,
    "other_response": null,
    "status": "pending",
    "created_at": "2025-10-08T10:00:30",
    "expires_at": "2025-10-09T10:00:30",
    "time_remaining": 86400
  }
]
```

**接受邀請:**
```http
POST /api/pairing/invitations/1/respond
{
  "response": "accept"
}
```

**雙方都接受後返回:**
```json
{
  "success": true,
  "became_friends": true,
  "friendship_id": 1,
  "message": "雙方都接受邀請,已成為好友!"
}
```

### 4. 查詢好友列表

```http
GET /api/pairing/friends
```

**返回:**
```json
[
  {
    "user_id": 2,
    "email": "user2@example.com",
    "is_online": false,
    "last_seen": null
  }
]
```

---

## ⚠️ 重要變更

### 1. 好友邀請自動觸發
- **舊版:** 手動創建好友請求
- **新版:** 臨時聊天室過期後自動創建好友邀請

### 2. 雙方確認制
- **舊版:** 一方發送請求,另一方接受/拒絕
- **新版:** 雙方都需要接受邀請才能成為好友

### 3. 聊天室永久化
- **舊版:** 無聊天室概念
- **新版:** 成為好友後,臨時聊天室自動升級為永久聊天室

### 4. 過期時間
- **臨時聊天室:** 30 秒 (測試模式,正式環境為 5 分鐘)
- **好友邀請:** 24 小時

---

## 🔧 測試工具

### 自動化測試腳本
```powershell
.\test_pairing_simple.ps1
```

此腳本會自動執行完整的配對→聊天→邀請→好友流程。

### 手動測試
參考 `SINGLE_DEVICE_TESTING.md` 獲取詳細的手動測試步驟。

---

## 📚 相關文檔

- **完整 API 文檔:** `PAIRING_CHAT_GUIDE.md`
- **單裝置測試指南:** `SINGLE_DEVICE_TESTING.md`
- **功能完成報告:** `CHAT_FEATURES_COMPLETION.txt`
- **快速參考:** `QUICK_REFERENCE.txt`

---

## ❓ 常見問題

### Q: 為什麼舊端點返回 400 錯誤?
A: 舊端點已被新的 pairing router 取代並註釋掉。請使用新端點。

### Q: 如何創建好友請求?
A: 新版本中無需手動創建。配對並聊天 30 秒後,系統會自動創建好友邀請。

### Q: 我的前端代碼使用舊端點怎麼辦?
A: 請參考本文檔的端點對應表更新前端代碼。

### Q: 測試環境下 30 秒太長怎麼辦?
A: 已設置為 30 秒 (測試模式)。正式環境建議改為 5 分鐘。

### Q: 如何改回 5 分鐘?
A: 修改 `backend/app/services/pairing_service.py` 第 52 行:
```python
expires_at = datetime.now() + timedelta(minutes=5)
```

---

## 🎯 下一步

1. ✅ 更新前端代碼使用新端點
2. ⏳ 實現 WebSocket 即時推送 (好友邀請通知)
3. ⏳ 實現在線狀態追蹤
4. ⏳ 實現移除好友功能
5. ⏳ 實現隨機配對功能

---

**最後更新:** 2025-10-08
**版本:** v2.0 (新配對聊天系統)
