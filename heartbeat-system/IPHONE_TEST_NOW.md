# 📱 iPhone 立即測試

## ✅ 服務狀態 (已確認運行中)

- ✅ **後端服務**: `http://192.168.1.114:8000` (運行中)
- ✅ **前端服務**: `http://192.168.1.114:8080` (運行中)

## 🚀 立即開始測試

### 步驟 1: 在 iPhone Safari 打開

```
http://192.168.1.114:8080
```

### 步驟 2: 登入測試帳號

**選擇一個帳號登入:**

| 帳號 | Email | 密碼 | User ID |
|------|-------|------|---------|
| 帳號 A | `tester_a@example.com` | `Test123!` | 19 |
| 帳號 B | `tester_b@example.com` | `Test123!` | 20 |

### 步驟 3: 測試目前可用功能

#### ✅ 應該可以使用的功能:

1. **登入/登出**
   - 輸入帳號密碼
   - 成功登入後看到主頁面

2. **查看個人資料**
   - 查看用戶資訊
   - 編輯個人資料

3. **訊息功能**
   - 查看訊息列表 (應該可以正常顯示)
   - 發送訊息
   - WebSocket 即時訊息

#### ⚠️ 可能出現錯誤的功能:

4. **好友列表** ❌ 會顯示 404 錯誤
   - 原因: 前端還在呼叫舊的 `/api/friends` 端點
   - 後端已改為 `/api/pairing/friends`
   - **這是預期的錯誤!**

5. **配對功能** ❌ UI 還沒實現
   - 畫面上可能沒有「配對」按鈕
   - 需要實現新的 UI

## 🔍 測試重點

### 重點 1: 驗證基本功能
- 登入是否成功?
- 訊息列表是否顯示?
- 能否發送訊息?

### 重點 2: 確認已知問題
- 好友列表是否顯示 404 錯誤? (預期會出現)
- 控制台有什麼錯誤訊息?

## 📝 查看錯誤訊息

### 在 iPhone Safari 查看控制台:

1. 在 Mac 上打開 Safari
2. 選單: `開發` → `[你的 iPhone]` → `[頁面名稱]`
3. 查看 Console 和 Network 標籤

### 或直接在頁面上查看:

如果頁面有錯誤提示,記下錯誤訊息。

## 🐛 預期會看到的錯誤

```
GET http://192.168.1.114:8000/api/friends
Response: 404 Not Found
```

**這是正常的!** 因為:
- 前端代碼還沒重新構建
- 還在呼叫已移除的舊 API 端點

## 🔧 如果無法連線

### 問題 1: 無法開啟網頁

**解決方法:**

1. 確認 iPhone 和電腦在同一個 WiFi:
```powershell
# 查看電腦的 WiFi 網路名稱
netsh wlan show interfaces
```

2. 檢查電腦 IP (可能會變):
```powershell
ipconfig | findstr "IPv4"
```

3. 確認防火牆允許:
```powershell
# 暫時關閉防火牆測試
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

# 測試完記得開回來
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
```

### 問題 2: 頁面空白

**可能原因:**
- Flutter web 構建檔案有問題
- 需要重新構建

**解決方法:**
```powershell
cd c:\Users\user\2J1134\heartbeat-system\frontend
flutter build web
```

## 📊 測試後回報

測試完請告訴我:

1. ✅ 能否成功登入?
2. ✅ 訊息功能是否正常?
3. ❌ 好友列表是否出現 404? (應該會)
4. 📸 有沒有其他錯誤訊息?

## 🎯 下一步計畫

根據測試結果:

### 如果基本功能正常:
1. 重新構建前端 (修正 API 端點)
2. 實現配對 UI
3. 完整測試新功能

### 如果有其他問題:
1. 先解決現有問題
2. 再進行 API 更新

---

**開始測試吧!** 🚀

用 iPhone 打開: `http://192.168.1.114:8080`
