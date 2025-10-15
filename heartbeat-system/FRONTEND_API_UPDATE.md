# 前端 API 更新說明

## 問題說明

你在 iPhone 測試時看到 `404 Not Found` 錯誤,這是因為:

1. **舊的 API 端點已被移除**:
   - ❌ `GET /api/friends` (已註釋)
   - ❌ `POST /api/friends/request` (已註釋)
   - ❌ `GET /api/friends/requests/pending` (已註釋)

2. **新的 API 端點**:
   - ✅ `GET /api/pairing/friends`
   - ✅ `POST /api/pairing/match`
   - ✅ `GET /api/pairing/invitations`

## 已完成的更新

### 1. 創建新的配對服務
文件: `frontend/lib/services/pairing_service.dart`

提供以下功能:
- `createPairing()` - 創建配對
- `getChatRooms()` - 獲取聊天室列表
- `checkChatRoomExpiry()` - 檢查過期並觸發邀請
- `getInvitations()` - 獲取好友邀請
- `respondToInvitation()` - 接受/拒絕邀請
- `getFriends()` - 獲取好友列表
- `isFriend()` - 檢查好友關係

### 2. 更新好友服務
文件: `frontend/lib/services/friend_service.dart`

- 更新 `getFriends()` 使用新端點 `/api/pairing/friends`
- 更新 `getPendingRequests()` 使用新端點 `/api/pairing/invitations`

## 需要重新構建前端

由於代碼已更新,需要重新構建前端:

```powershell
# 停止前端服務
Stop-Process -Name python -Force -ErrorAction SilentlyContinue

# 重新構建 Flutter Web
cd c:\Users\user\2J1134\heartbeat-system\frontend
flutter build web

# 重啟前端代理
python proxy.py
```

或者簡單地:

```powershell
# 重啟代理即可 (熱重載)
Stop-Process -Name python -Force
cd c:\Users\user\2J1134\heartbeat-system\frontend
python proxy.py
```

## 前端 UI 需要更新

目前前端 UI 還沒有實現新的配對聊天功能。

### 暫時解決方案

在 UI 實現之前,可以:

1. **使用 API 測試**:
   ```powershell
   cd c:\Users\user\2J1134\heartbeat-system
   .\test_pairing_simple.ps1
   ```

2. **在瀏覽器控制台測試**:
   ```javascript
   // 在 iPhone Safari 或電腦瀏覽器的控制台執行
   
   // 假設已登入並有 token
   const token = localStorage.getItem('token');
   
   // 創建配對
   fetch('http://172.20.10.2:8000/api/pairing/match', {
     method: 'POST',
     headers: {
       'Content-Type': 'application/json',
       'Authorization': `Bearer ${token}`
     },
     body: JSON.stringify({target_user_id: 20})
   }).then(r => r.json()).then(console.log);
   
   // 查看聊天室
   fetch('http://172.20.10.2:8000/api/pairing/chat-rooms', {
     headers: {'Authorization': `Bearer ${token}`}
   }).then(r => r.json()).then(console.log);
   
   // 查看好友
   fetch('http://172.20.10.2:8000/api/pairing/friends', {
     headers: {'Authorization': `Bearer ${token}`}
   }).then(r => r.json()).then(console.log);
   ```

### 需要實現的 UI 功能

1. **配對頁面** (新增):
   - 輸入對方用戶 ID
   - 點擊配對按鈕
   - 顯示配對成功訊息

2. **聊天室列表** (更新):
   - 顯示臨時/永久標籤
   - 顯示倒數計時(臨時聊天室)
   - 顯示對方 email

3. **好友邀請通知** (新增):
   - 30 秒後彈出通知
   - 顯示「接受」「拒絕」按鈕
   - 顯示剩餘時間(24小時)

4. **好友列表** (更新):
   - 顯示在線狀態
   - 點擊進入永久聊天室

## API 端點對照表

| 功能 | 舊端點 | 新端點 | 狀態 |
|------|--------|--------|------|
| 獲取好友列表 | GET /api/friends | GET /api/pairing/friends | ✅ 已更新 |
| 添加好友 | POST /api/friends/request | POST /api/pairing/match | 🔄 流程改變 |
| 好友請求列表 | GET /api/friends/requests/pending | GET /api/pairing/invitations | ✅ 已更新 |
| 接受請求 | POST /api/friends/request/{id}/accept | POST /api/pairing/invitations/{id}/respond | 🔄 流程改變 |
| 拒絕請求 | POST /api/friends/request/{id}/reject | POST /api/pairing/invitations/{id}/respond | 🔄 流程改變 |
| 聊天室列表 | *(無)* | GET /api/pairing/chat-rooms | ⭐ 新功能 |
| 檢查過期 | *(無)* | POST /api/pairing/chat-room/{id}/check-expiry | ⭐ 新功能 |

## 當前狀態

✅ **後端**: 新 API 全部實現並測試通過
✅ **服務層**: 新的 `PairingService` 已創建
🟡 **UI層**: 尚未實現,需要開發

## 下一步

1. **短期**: 使用測試腳本驗證後端功能
2. **中期**: 實現前端 UI (配對頁面、聊天室、邀請通知)
3. **長期**: 實現 WebSocket 即時推送

## 測試建議

目前最好的測試方式:

1. **電腦上運行測試腳本**:
   ```powershell
   .\test_pairing_simple.ps1
   ```

2. **在 iPhone 上查看結果**:
   - 登入帳號 A
   - 查看好友列表 (應該能看到)
   - 查看訊息 (如果實現了)

3. **等待 UI 實現後再做完整測試**

---

**最後更新**: 2025-10-08  
**API 版本**: v2.0 (配對聊天系統)  
**前端狀態**: 服務層已更新,UI 待實現
