# 好友及聊天功能完善 - 使用說明

## 功能概述

已完成的配對聊天流程:
1. **配對成功** → 自動創建 **5分鐘臨時聊天室**
2. **5分鐘後** → 自動產生 **好友邀請通知**
3. **雙方接受** → 成為好友 + 升級為 **永久聊天室**
4. **好友關係** → 可查看 **在線狀態** + **永久聊天**

---

## API 端點說明

### 1. 創建配對(自動創建5分鐘聊天室)

```http
POST /api/pairing/match
Authorization: Bearer <token>
Content-Type: application/json

{
  "target_user_id": 2
}
```

**回應:**
```json
{
  "id": 1,
  "user_id_1": 1,
  "user_id_2": 2,
  "status": "active",
  "created_at": "2025-10-08T16:00:00",
  "matched_at": "2025-10-08T16:00:00"
}
```

**說明:** 配對成功後會自動創建一個5分鐘的臨時聊天室

---

### 2. 獲取我的所有聊天室

```http
GET /api/pairing/chat-rooms
Authorization: Bearer <token>
```

**回應:**
```json
[
  {
    "id": 1,
    "room_type": "temporary",  // 或 "permanent"
    "is_active": true,
    "expires_at": "2025-10-08T16:05:00",  // 5分鐘後過期
    "created_at": "2025-10-08T16:00:00",
    "other_user_id": 2,
    "other_user_email": "user2@example.com",
    "is_friend": false
  }
]
```

---

### 3. 獲取與特定用戶的聊天室

```http
GET /api/pairing/chat-room/{other_user_id}
Authorization: Bearer <token>
```

---

### 4. 檢查聊天室是否過期(前端定時調用)

```http
POST /api/pairing/chat-room/{chat_room_id}/check-expiry
Authorization: Bearer <token>
```

**回應(未過期):**
```json
{
  "expired": false,
  "invitation_created": false
}
```

**回應(已過期,創建邀請):**
```json
{
  "expired": true,
  "invitation_created": true,
  "invitation_id": 1
}
```

**說明:** 前端應該每30秒檢查一次,當聊天室過期時會自動創建好友邀請

---

### 5. 獲取我的好友邀請

```http
GET /api/pairing/invitations
Authorization: Bearer <token>
```

**回應:**
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
    "created_at": "2025-10-08T16:05:00",
    "expires_at": "2025-10-09T16:05:00",
    "time_remaining": 86400  // 剩餘秒數(24小時)
  }
]
```

---

### 6. 回應好友邀請

```http
POST /api/pairing/invitations/{invitation_id}/respond
Authorization: Bearer <token>
Content-Type: application/json

{
  "response": "accept"  // 或 "reject"
}
```

**回應(雙方都接受):**
```json
{
  "success": true,
  "became_friends": true,
  "friendship_id": 1,
  "message": "雙方都接受邀請,已成為好友!"
}
```

**回應(等待對方):**
```json
{
  "success": true,
  "became_friends": false,
  "message": "已記錄您的回應: accept"
}
```

**說明:** 雙方都接受後,臨時聊天室會自動升級為永久聊天室

---

### 7. 獲取我的好友列表(含在線狀態)

```http
GET /api/pairing/friends
Authorization: Bearer <token>
```

**回應:**
```json
[
  {
    "user_id": 2,
    "email": "user2@example.com",
    "is_online": true,
    "last_seen": "2025-10-08T16:10:00"
  }
]
```

---

### 8. 檢查與某用戶是否為好友

```http
GET /api/pairing/is-friend/{user_id}
Authorization: Bearer <token>
```

**回應:**
```json
{
  "is_friend": true
}
```

---

## 前端實現流程

### 流程 1: 配對後進入臨時聊天室

```dart
// 1. 用戶配對成功
final pairing = await pairingService.createPairing(targetUserId);

// 2. 自動跳轉到聊天室
Navigator.push(context, ChatRoomScreen(
  otherUserId: targetUserId,
  roomType: 'temporary'
));

// 3. 在聊天室頁面定時檢查過期
Timer.periodic(Duration(seconds: 30), (timer) async {
  final result = await pairingService.checkRoomExpiry(chatRoomId);
  
  if (result['expired']) {
    // 顯示通知: 聊天時間已到,請查看好友邀請
    showNotification('聊天時間已到!您收到了來自 XXX 的好友邀請');
    timer.cancel();
  }
});
```

### 流程 2: 顯示倒計時

```dart
// 在聊天室UI頂部顯示倒計時
Widget buildCountdown(DateTime expiresAt) {
  final remaining = expiresAt.difference(DateTime.now());
  
  return Container(
    padding: EdgeInsets.all(8),
    color: Colors.orange,
    child: Text(
      '臨時聊天室 · 剩餘 ${remaining.inMinutes}:${remaining.inSeconds % 60}',
      style: TextStyle(color: Colors.white)
    ),
  );
}
```

### 流程 3: 處理好友邀請

```dart
// 在主頁或通知中心顯示邀請
final invitations = await pairingService.getInvitations();

// 用戶點擊接受
await pairingService.respondToInvitation(
  invitationId: invitation.id,
  response: 'accept'
);

// 如果雙方都接受,自動跳轉到永久聊天室
if (result['became_friends']) {
  Navigator.push(context, ChatRoomScreen(
    otherUserId: otherUserId,
    roomType: 'permanent'
  ));
}
```

### 流程 4: 好友列表顯示在線狀態

```dart
// 在好友列表中顯示在線狀態
ListTile(
  leading: Stack(
    children: [
      CircleAvatar(child: Icon(Icons.person)),
      if (friend.isOnline)
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2)
            ),
          ),
        ),
    ],
  ),
  title: Text(friend.email),
  subtitle: friend.isOnline 
    ? Text('在線', style: TextStyle(color: Colors.green))
    : Text('上次上線: ${formatTime(friend.lastSeen)}'),
  onTap: () {
    // 打開永久聊天室
    Navigator.push(context, ChatRoomScreen(
      otherUserId: friend.userId,
      roomType: 'permanent'
    ));
  },
)
```

---

## 資料庫表結構

### chat_rooms (聊天室)
- `id`: 聊天室ID
- `user_id_1`, `user_id_2`: 兩個用戶ID
- `room_type`: "temporary" 或 "permanent"
- `pairing_id`: 關聯的配對ID
- `is_active`: 是否啟用
- `expires_at`: 過期時間(臨時聊天室)
- `created_at`: 創建時間

### friend_invitations (好友邀請)
- `id`: 邀請ID
- `chat_room_id`: 來源聊天室
- `user_id_1`, `user_id_2`: 兩個用戶
- `user_1_response`, `user_2_response`: 各自回應
- `status`: "pending", "both_accepted", "rejected"
- `expires_at`: 邀請過期時間(24小時)

### messages (訊息)
- 新增 `chat_room_id`: 所屬聊天室
- 新增 `is_read`: 是否已讀

---

## 測試步驟

### 1. 創建兩個測試帳號
```bash
# 帳號1
POST /api/auth/register
{
  "email": "test1@example.com",
  "password": "Test123!"
}

# 帳號2
POST /api/auth/register
{
  "email": "test2@example.com",
  "password": "Test123!"
}
```

### 2. 帳號1配對帳號2
```bash
POST /api/pairing/match
Authorization: Bearer <test1_token>
{
  "target_user_id": <test2_id>
}
```

### 3. 查看臨時聊天室
```bash
GET /api/pairing/chat-rooms
Authorization: Bearer <test1_token>

# 應該看到一個 room_type="temporary" 的聊天室
```

### 4. 等待5分鐘或手動檢查過期
```bash
POST /api/pairing/chat-room/1/check-expiry
Authorization: Bearer <test1_token>
```

### 5. 查看好友邀請
```bash
GET /api/pairing/invitations
Authorization: Bearer <test1_token>
```

### 6. 雙方接受邀請
```bash
# 帳號1接受
POST /api/pairing/invitations/1/respond
Authorization: Bearer <test1_token>
{"response": "accept"}

# 帳號2接受
POST /api/pairing/invitations/1/respond
Authorization: Bearer <test2_token>
{"response": "accept"}
```

### 7. 確認成為好友
```bash
GET /api/pairing/friends
Authorization: Bearer <test1_token>

# 應該看到 test2 在好友列表中
```

### 8. 確認聊天室升級為永久
```bash
GET /api/pairing/chat-rooms
Authorization: Bearer <test1_token>

# 聊天室的 room_type 應該變為 "permanent"
# expires_at 應該為 null
```

---

## 下一步TODO

- [ ] 前端實現聊天室倒計時UI
- [ ] 前端實現好友邀請通知
- [ ] 前端實現在線狀態顯示
- [ ] WebSocket實時推送好友邀請
- [ ] WebSocket實時更新在線狀態
- [ ] 實現最後上線時間記錄
- [ ] 添加聊天室訊息已讀狀態

---

## 注意事項

1. **臨時聊天室時間**: 目前設定為5分鐘,可在 `pairing_service.py` 修改
2. **好友邀請有效期**: 目前設定為24小時
3. **在線狀態**: 目前返回模擬數據,需整合 WebSocket 實現真實在線檢測
4. **定時檢查**: 前端需要定時調用 `check-expiry` API 來觸發好友邀請創建
