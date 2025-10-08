# 在iPhone上測試心跳互動系統APP

## 📱 快速開始指南

### 當前配置
- **您的電腦WiFi IP**: `172.20.10.2`
- **後端API地址**: `http://172.20.10.2:8000`
- **前端應用地址**: `http://172.20.10.2:8080`

### 步驟1: 啟動服務

#### 方法A: 使用批次文件（推薦）
1. 雙擊運行 `start_services.bat`
2. 會自動打開兩個命令視窗（後端和前端）
3. 等待幾秒鐘直到服務完全啟動

#### 方法B: 手動啟動
在PowerShell中運行以下命令：

```powershell
# 啟動後端
cd c:\Users\user\2J1134\heartbeat-system\backend
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# 在另一個終端啟動前端
cd c:\Users\user\2J1134\heartbeat-system\frontend
python proxy.py
```

### 步驟2: 確保電腦和iPhone在同一WiFi

- 確認iPhone連接到與電腦相同的WiFi網絡
- WiFi名稱應該一致

### 步驟3: 在iPhone上訪問應用

1. **打開Safari瀏覽器**（推薦使用Safari，而非Chrome）

2. **輸入地址**: `http://172.20.10.2:8080`

3. **如果無法訪問**，請檢查：
   - 電腦和iPhone是否在同一WiFi
   - Windows防火牆是否允許連接（見下方故障排除）

### 步驟4: 登入測試

使用以下測試帳號登入：

**測試用戶1:**
- Email: `testuser_integration@example.com`
- Password: `Test123!`

**測試用戶2:**
- Email: `test1@example.com`
- Password: `test123`

## 🔧 故障排除

### 問題1: iPhone無法訪問應用

**檢查Windows防火牆:**

```powershell
# 在PowerShell (以管理員身份運行) 中執行：

# 為Python添加防火牆規則
netsh advfirewall firewall add rule name="Python允許入站-8000" dir=in action=allow protocol=TCP localport=8000
netsh advfirewall firewall add rule name="Python允許入站-8080" dir=in action=allow protocol=TCP localport=8080
```

### 問題2: IP地址改變了

如果您的電腦IP地址改變（例如重新連接WiFi），需要：

1. **檢查新的IP地址:**
   ```powershell
   ipconfig
   ```
   查找"無線區域網路介面卡 Wi-Fi"下的"IPv4 位址"

2. **更新前端配置:**
   編輯 `frontend/lib/config/app_config.dart`:
   ```dart
   static const String apiBaseUrl = 'http://您的新IP:8000/api';
   static const String wsBaseUrl = 'ws://您的新IP:8000';
   ```

3. **重新構建並重啟服務**

### 問題3: 服務無法啟動

**清理並重啟:**
```powershell
# 停止所有Python進程
Stop-Process -Name python -Force -ErrorAction SilentlyContinue

# 重新運行start_services.bat
```

### 問題4: API請求失敗

**檢查後端日誌:**
- 查看後端命令視窗中的錯誤信息
- 確認CORS設置正確

## 📊 測試功能清單

在iPhone上測試以下功能：

### ✅ 基本功能
- [ ] 用戶註冊
- [ ] 用戶登入
- [ ] 查看設備列表
- [ ] 添加好友
- [ ] 查看好友列表

### ✅ 進階功能
- [ ] 發送消息
- [ ] 接收消息
- [ ] 查看對話列表
- [ ] WebSocket連接（實時狀態）
- [ ] 設備綁定
- [ ] 配對功能

## 🌐 使用ngrok建立公網訪問（可選）

如果您想讓不在同一WiFi的設備也能訪問，可以使用ngrok：

1. **下載並安裝ngrok**: https://ngrok.com/download

2. **啟動ngrok隧道:**
   ```powershell
   # 為後端創建隧道
   ngrok http 8000
   
   # 在另一個終端為前端創建隧道  
   ngrok http 8080
   ```

3. **更新配置:**
   使用ngrok提供的公網URL更新 `app_config.dart`

## 📝 注意事項

1. **性能**: 通過WiFi訪問可能比本地稍慢
2. **安全**: 這是開發環境，不適合生產使用
3. **電池**: WebSocket連接會消耗一些電池
4. **網絡**: 確保WiFi信號穩定

## 🆘 需要幫助？

如果遇到問題：
1. 檢查兩個服務的命令視窗日誌
2. 在iPhone的Safari中打開開發者工具（需要Mac）
3. 檢查網絡連接狀態
4. 嘗試重啟服務

## 📱 添加到iPhone主畫面（可選）

在Safari中訪問應用後：
1. 點擊分享按鈕
2. 選擇"加入主畫面"
3. 輸入名稱（例如：心跳互動系統）
4. 應用圖標會出現在主畫面上

這樣就可以像原生應用一樣使用了！
