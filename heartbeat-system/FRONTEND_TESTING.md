# 前端測試快速指南

## 🚀 服務已啟動

### ✅ 運行中的服務

1. **後端API服務**
   - 地址: http://192.168.1.114:8000
   - 狀態: ✓ 運行中
   - API文檔: http://192.168.1.114:8000/docs

2. **前端Web應用**
   - 地址: http://localhost:8080
   - 狀態: ✓ 運行中
   - 已在VS Code Simple Browser中打開

---

## 📋 測試流程

### 第一步：用戶註冊和登入

1. 打開前端頁面: http://localhost:8080
2. 點擊「註冊」或「Register」
3. 創建兩個測試帳號：
   - **用戶A**: test_a@example.com / Test123!
   - **用戶B**: test_b@example.com / Test123!

### 第二步：測試隨機配對功能

**用戶A的操作**:
1. 使用 test_a@example.com 登入
2. 進入「配對」或「Pairing」頁面
3. 點擊「隨機配對」按鈕
4. 系統顯示「已加入配對隊列，等待配對...」

**用戶B的操作**:
1. 開啟無痕視窗或另一個瀏覽器
2. 訪問 http://localhost:8080
3. 使用 test_b@example.com 登入
4. 進入「配對」或「Pairing」頁面
5. 點擊「隨機配對」按鈕
6. 系統顯示「配對成功！」
7. 自動創建臨時聊天室

### 第三步：測試臨時聊天室（5分鐘）

**測試模式：30秒過期**

1. 配對成功後，雙方可以看到聊天室
2. 嘗試發送訊息
3. 觀察倒數計時器（顯示剩餘時間）
4. 等待30秒（測試模式）或5分鐘（生產模式）
5. 聊天室過期後會出現「好友邀請」通知

### 第四步：測試好友邀請功能

**當臨時聊天室過期後**:

1. 雙方都會收到「好友邀請」通知
2. 用戶A點擊「接受」邀請
3. 用戶B點擊「接受」邀請
4. 雙方都接受後：
   - 自動成為好友
   - 臨時聊天室升級為永久聊天室
   - 聊天室不再有過期時間

### 第五步：測試好友功能

**查看好友列表**:
1. 進入「好友」頁面
2. 應該看到對方的帳號
3. 顯示好友的在線狀態

**查看好友裝置狀態**:
1. 點擊好友進入詳情頁面
2. 可以看到好友綁定的ESP32裝置
3. 顯示裝置在線狀態
4. 顯示最新的壓力數據（如果裝置在線）

**永久聊天室**:
1. 進入「聊天室」頁面
2. 看到與好友的永久聊天室
3. 聊天室類型顯示為「永久」
4. 沒有過期時間
5. 可以隨時聊天

### 第六步：測試ESP32裝置（可選）

如果有ESP32裝置：

1. 在前端「裝置」頁面點擊「綁定裝置」
2. 輸入ESP32的裝置ID
3. 綁定成功後可以看到：
   - 裝置在線狀態
   - 實時壓力數據
   - 壓力變化圖表（如果前端有實現）

---

## 🧪 快速測試腳本（使用API）

如果想直接測試API，可以使用PowerShell：

```powershell
# 設置變量
$API = "http://192.168.1.114:8000"

# 1. 註冊兩個用戶
$userA = Invoke-RestMethod "$API/api/auth/register" -Method POST -Body (@{email="test_a@example.com"; password="Test123!"} | ConvertTo-Json) -ContentType "application/json"
$userB = Invoke-RestMethod "$API/api/auth/register" -Method POST -Body (@{email="test_b@example.com"; password="Test123!"} | ConvertTo-Json) -ContentType "application/json"

# 2. 獲取Token
$tokenA = (Invoke-RestMethod "$API/api/auth/token" -Method POST -Body "username=test_a@example.com&password=Test123!" -ContentType "application/x-www-form-urlencoded").access_token
$tokenB = (Invoke-RestMethod "$API/api/auth/token" -Method POST -Body "username=test_b@example.com&password=Test123!" -ContentType "application/x-www-form-urlencoded").access_token

Write-Host "✓ 用戶已創建並登入" -ForegroundColor Green
Write-Host "Token A: $tokenA" -ForegroundColor Cyan
Write-Host "Token B: $tokenB" -ForegroundColor Cyan

# 3. 隨機配對
Write-Host "`n開始配對..." -ForegroundColor Yellow
$matchA = Invoke-RestMethod "$API/api/pairing/random-match" -Method POST -Headers @{Authorization="Bearer $tokenA"}
Write-Host "用戶A: $($matchA.message)" -ForegroundColor Cyan

Start-Sleep -Seconds 2

$matchB = Invoke-RestMethod "$API/api/pairing/random-match" -Method POST -Headers @{Authorization="Bearer $tokenB"}
Write-Host "用戶B: $($matchB.message)" -ForegroundColor Green

if ($matchB.matched) {
    Write-Host "✓ 配對成功！聊天室ID: $($matchB.chat_room_id)" -ForegroundColor Green
}

# 4. 查看聊天室
Write-Host "`n查看聊天室..." -ForegroundColor Yellow
$rooms = Invoke-RestMethod "$API/api/pairing/chat-rooms" -Headers @{Authorization="Bearer $tokenA"}
$rooms | ConvertTo-Json | Write-Host

Write-Host "`n等待30秒讓聊天室過期..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# 5. 檢查過期
$chatRoomId = $rooms[0].id
$expiry = Invoke-RestMethod "$API/api/pairing/chat-room/$chatRoomId/check-expiry" -Method POST -Headers @{Authorization="Bearer $tokenA"}
Write-Host "聊天室過期狀態: $($expiry | ConvertTo-Json)" -ForegroundColor Cyan

# 6. 查看邀請
Write-Host "`n查看好友邀請..." -ForegroundColor Yellow
$invitations = Invoke-RestMethod "$API/api/pairing/invitations" -Headers @{Authorization="Bearer $tokenA"}
$invitations | ConvertTo-Json | Write-Host

# 7. 雙方接受邀請
if ($invitations.Count -gt 0) {
    $invId = $invitations[0].id
    Write-Host "`n接受好友邀請..." -ForegroundColor Yellow
    
    $acceptA = Invoke-RestMethod "$API/api/pairing/invitations/$invId/respond" -Method POST -Headers @{Authorization="Bearer $tokenA"} -Body (@{response="accept"} | ConvertTo-Json) -ContentType "application/json"
    Write-Host "用戶A: $($acceptA.message)" -ForegroundColor Cyan
    
    $acceptB = Invoke-RestMethod "$API/api/pairing/invitations/$invId/respond" -Method POST -Headers @{Authorization="Bearer $tokenB"} -Body (@{response="accept"} | ConvertTo-Json) -ContentType "application/json"
    Write-Host "用戶B: $($acceptB.message)" -ForegroundColor Green
    
    if ($acceptB.became_friends) {
        Write-Host "✓ 成為好友！" -ForegroundColor Green
    }
}

# 8. 查看好友列表
Write-Host "`n查看好友列表..." -ForegroundColor Yellow
$friends = Invoke-RestMethod "$API/api/pairing/friends" -Headers @{Authorization="Bearer $tokenA"}
$friends | ConvertTo-Json | Write-Host

# 9. 查看升級後的聊天室
Write-Host "`n查看永久聊天室..." -ForegroundColor Yellow
$permanentRooms = Invoke-RestMethod "$API/api/pairing/chat-rooms" -Headers @{Authorization="Bearer $tokenA"}
$permanentRooms | ConvertTo-Json | Write-Host

Write-Host "`n✓ 所有測試完成！" -ForegroundColor Green
```

---

## 🔍 檢查服務狀態

### 檢查後端是否運行
```powershell
curl http://192.168.1.114:8000/docs
# 應該看到API文檔頁面
```

### 檢查前端是否運行
```powershell
curl http://localhost:8080
# 應該看到HTML頁面
```

### 查看後端日誌
後端應該在一個PowerShell視窗中運行，可以看到所有API請求

### 查看前端日誌
前端應該在另一個PowerShell視窗中運行，可以看到編譯和熱重載信息

---

## ❓ 常見問題

### Q1: 前端無法連接到後端
**解決方案**: 
1. 檢查 `frontend/lib/config/app_config.dart`
2. 確認 API URL 是 `http://192.168.1.114:8000`
3. 重新啟動前端

### Q2: 配對沒有反應
**解決方案**:
1. 確認兩個用戶都已登入
2. 確認都在配對頁面
3. 檢查後端日誌是否有錯誤

### Q3: 聊天室沒有過期
**解決方案**:
1. 檢查 `backend/app/services/pairing_service.py` 第55行
2. 確認是 `timedelta(seconds=30)` (測試模式)
3. 等待完整的30秒

### Q4: 好友邀請沒有出現
**解決方案**:
1. 手動檢查過期: 訪問 `/api/pairing/chat-room/{id}/check-expiry`
2. 刷新頁面
3. 重新登入

---

## 📊 測試檢查清單

- [ ] 用戶A註冊成功
- [ ] 用戶B註冊成功
- [ ] 用戶A可以登入
- [ ] 用戶B可以登入
- [ ] 隨機配對成功
- [ ] 臨時聊天室創建
- [ ] 可以發送訊息
- [ ] 倒數計時器顯示
- [ ] 30秒後聊天室過期
- [ ] 好友邀請出現
- [ ] 用戶A接受邀請
- [ ] 用戶B接受邀請
- [ ] 成為好友
- [ ] 聊天室升級為永久
- [ ] 好友列表顯示
- [ ] 可以查看好友裝置（如果已綁定）

---

## 🎯 下一步

1. **測試所有功能** - 按照上述流程完整測試一遍
2. **綁定ESP32裝置** - 如果有實體裝置，測試裝置綁定和數據上傳
3. **UI優化** - 根據測試結果優化用戶界面
4. **錯誤處理** - 添加更多的錯誤提示和處理

---

**祝測試順利！** 🎉

如有任何問題，請查看後端和前端的日誌輸出。
