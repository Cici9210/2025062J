# iPhone 測試故障排除指南

## 問題: 無法載入頁面 / 顯示載入失敗

### 可能原因 1: iPhone 和電腦不在同一 WiFi

**檢查方法:**
1. iPhone: 設定 → WiFi → 查看連接的網絡名稱
2. 電腦: 工作列 WiFi 圖示 → 查看連接的網絡名稱
3. 確認兩者相同

**解決方案:**
- 將 iPhone 和電腦連接到同一個 WiFi 網絡

---

### 可能原因 2: 電腦 IP 地址改變

**檢查方法:**
在電腦 PowerShell 執行:
```powershell
ipconfig | Select-String "IPv4"
```

**解決方案:**
- 如果 IP 不是 `172.20.10.2`,請使用新的 IP
- 例如新 IP 是 `192.168.1.100`,則訪問:
  ```
  http://192.168.1.100:8080
  ```

---

### 可能原因 3: Windows 防火牆阻擋

**症狀:**
- 電腦上 `http://localhost:8080` 可以訪問
- iPhone 上 `http://172.20.10.2:8080` 無法訪問

**解決方案 A: 臨時關閉防火牆測試**
1. Windows 設定 → 更新與安全性 → Windows 安全性
2. 防火牆與網路保護
3. 暫時關閉「私人網路」防火牆
4. 測試 iPhone 是否可以訪問
5. 測試後記得重新開啟!

**解決方案 B: 添加防火牆規則 (推薦)**

在 PowerShell (以管理員身份) 執行:
```powershell
# 允許 Port 8000 (後端)
New-NetFirewallRule -DisplayName "Heartbeat Backend" -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow

# 允許 Port 8080 (前端)
New-NetFirewallRule -DisplayName "Heartbeat Frontend" -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow
```

---

### 可能原因 4: 服務未啟動

**檢查方法:**
在電腦 PowerShell 執行:
```powershell
curl http://localhost:8000/health
curl http://localhost:8080
```

**如果顯示錯誤:**

**解決方案: 重啟服務**
```powershell
# 停止舊服務
Stop-Process -Name python -Force -ErrorAction SilentlyContinue

# 方法1: 使用批次文件
cd c:\Users\user\2J1134\heartbeat-system
.\start_services.bat

# 方法2: 手動啟動
# 終端1:
cd c:\Users\user\2J1134\heartbeat-system\backend
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# 終端2:
cd c:\Users\user\2J1134\heartbeat-system\frontend
python proxy.py
```

---

### 可能原因 5: Safari 瀏覽器問題

**症狀:**
- 頁面一直載入中
- 顯示空白頁

**解決方案:**
1. 清除 Safari 快取:
   - Safari → 偏好設定 → 進階 → 顯示「開發」選單
   - 開發 → 清除快取
2. 關閉 Safari 並重新開啟
3. 嘗試使用「無痕式瀏覽」
4. 如果仍無法使用,嘗試 Chrome 或 Firefox

---

## 問題: 可以開啟頁面但無法登入

### 可能原因: 帳號不存在

**症狀:**
- 輸入帳號密碼後顯示錯誤
- 「Invalid credentials」或「User not found」

**解決方案:**
在電腦上創建測試帳號:

```powershell
cd c:\Users\user\2J1134\heartbeat-system\backend

# 創建帳號 A
python -c "from app.database.connection import get_db; from app.services.auth_service import create_user; from app.schemas.auth import UserCreate; db = next(get_db()); user = UserCreate(email='tester_a@example.com', password='Test123!'); create_user(db, user); print('User A created')"

# 創建帳號 B
python -c "from app.database.connection import get_db; from app.services.auth_service import create_user; from app.schemas.auth import UserCreate; db = next(get_db()); user = UserCreate(email='tester_b@example.com', password='Test123!'); create_user(db, user); print('User B created')"
```

---

## 問題: 登入後看不到配對功能

### 可能原因: 前端 UI 尚未實現

**症狀:**
- 可以登入
- 但沒有配對按鈕或功能

**暫時解決方案:**
使用電腦測試腳本模擬配對:

```powershell
cd c:\Users\user\2J1134\heartbeat-system
.\test_pairing_simple.ps1
```

這會自動執行完整的配對流程,你可以在 iPhone 上查看結果。

**長期解決方案:**
需要在 Flutter 前端實現配對 UI。

---

## 問題: 文字顯示為白色看不見

### 症狀:
- 可以看到頁面布局
- 但文字是白色在白色背景上

**解決方案:**
已修復!確認使用的是最新版本:
- `frontend/lib/main.dart` 中 `ThemeMode.light`
- `frontend/lib/config/theme.dart` 中有明確的文字顏色設定

**如果仍有問題:**
重新構建前端:
```powershell
cd c:\Users\user\2J1134\heartbeat-system\frontend
flutter build web
Stop-Process -Name python -Force
python proxy.py
```

---

## 問題: 觸控反應不靈敏

### 可能原因: 按鈕太小或間距不足

**暫時解決方案:**
- 使用 Safari 的「閱讀器視圖」
- 放大頁面 (雙擊或雙指縮放)
- 橫向使用 iPhone

**長期解決方案:**
需要優化前端 UI 為移動設備。

---

## 問題: 收不到即時更新

### 症狀:
- User A 配對後,User B 看不到
- 需要手動刷新頁面

**原因:**
WebSocket 實時推送尚未完全實現。

**暫時解決方案:**
手動下拉刷新或重新進入頁面。

---

## 快速診斷檢查清單

在開始測試前,在電腦上執行:

```powershell
# 1. 檢查服務狀態
curl http://localhost:8000/health
curl http://localhost:8080

# 2. 檢查 IP 地址
ipconfig | Select-String "IPv4"

# 3. 檢查測試帳號
cd c:\Users\user\2J1134\heartbeat-system\backend
python -c "from app.database.connection import get_db; from app.database.models import User; db = next(get_db()); users = db.query(User).filter(User.email.like('%tester%')).all(); [print(f'{u.id}: {u.email}') for u in users]"

# 4. 測試 API
curl http://localhost:8000/api/auth/token -Method POST -ContentType "application/x-www-form-urlencoded" -Body "username=tester_a@example.com&password=Test123!"
```

所有檢查都通過後,在 iPhone 上訪問:
```
http://172.20.10.2:8080
```

---

## 仍然無法解決?

1. 查看詳細日志:
   - 後端終端的錯誤訊息
   - Safari 開發者工具 (需要 Mac)
   
2. 重啟所有服務:
   ```powershell
   Stop-Process -Name python -Force
   .\start_services.bat
   ```

3. 嘗試使用電腦瀏覽器測試:
   - 先在電腦上 `http://localhost:8080` 測試
   - 確認功能正常後再用 iPhone

4. 參考其他文檔:
   - `API_MIGRATION_GUIDE.md` - API 使用說明
   - `SINGLE_DEVICE_TESTING.md` - 單裝置測試
   - `test_pairing_simple.ps1` - 自動化測試

---

**最後更新:** 2025-10-08  
**當前 IP:** 172.20.10.2  
**服務狀態:** ✅ 運行中
