# 🚀 快速部署指南 - 3 步驟完成

## ✅ 已完成準備工作

- ✅ Git repository 已初始化
- ✅ 所有文件已提交
- ✅ 部署配置文件已創建
- ✅ 環境變數範例已準備

---

## 📝 下一步操作 (僅需 3 步驟)

### 步驟 1️⃣: 上傳到 GitHub

#### 選項 A: 使用 Git 命令行 (推薦)

```powershell
# 1. 在 GitHub 創建新 repository
#    前往: https://github.com/new
#    Repository name: heartbeat-system
#    描述: Heart Pressure Interaction System
#    類型: Public 或 Private
#    不要勾選 "Initialize with README"

# 2. 複製您的 GitHub 用戶名
#    例如: Cici9210

# 3. 執行以下命令 (替換 YOUR_USERNAME 為您的用戶名)
cd c:\Users\user\2J1134\heartbeat-system
git remote add origin https://github.com/YOUR_USERNAME/heartbeat-system.git
git branch -M main
git push -u origin main

# 如果提示輸入帳號密碼:
#   - 用戶名: 您的 GitHub 用戶名
#   - 密碼: Personal Access Token (不是密碼!)
#   
# 如何獲取 Personal Access Token:
#   1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
#   2. Generate new token → 勾選 "repo" 權限 → Generate
#   3. 複製 token (只會顯示一次!)
```

#### 選項 B: 使用 GitHub Desktop (更簡單)

```powershell
# 1. 下載 GitHub Desktop
#    https://desktop.github.com

# 2. 安裝並登入 GitHub 帳號

# 3. File → Add Local Repository
#    選擇: c:\Users\user\2J1134\heartbeat-system

# 4. 點擊 "Publish repository"
#    - Repository name: heartbeat-system
#    - 取消勾選 "Keep this code private" (如果想公開)
#    - 點擊 "Publish Repository"
```

---

### 步驟 2️⃣: 部署後端到 Render

1. **前往 Render**: https://dashboard.render.com

2. **創建 Web Service**:
   - 點擊 **New +** → **Web Service**
   - 連接 GitHub repository: `heartbeat-system`
   - 點擊 **Connect**

3. **配置服務**:
   ```
   Name: heartbeat-backend
   Region: Singapore
   Branch: main
   Root Directory: backend
   Runtime: Python 3
   Build Command: pip install -r requirements.txt
   Start Command: uvicorn app.main:app --host 0.0.0.0 --port $PORT
   Instance Type: Free
   ```

4. **創建 PostgreSQL 數據庫**:
   - 點擊 **New +** → **PostgreSQL**
   - Name: `heartbeat-db`
   - Region: `Singapore`
   - Instance Type: `Free`
   - 點擊 **Create Database**

5. **設置環境變數**:
   點擊 **Environment** → **Add Environment Variable**:
   
   ```
   DATABASE_URL
     → 點擊 "Add from a database" 
     → 選擇 heartbeat-db 
     → 選擇 "Internal Database URL"
   
   SECRET_KEY
     → 點擊 "Generate" (自動生成)
   
   ALGORITHM
     → HS256
   
   ACCESS_TOKEN_EXPIRE_MINUTES
     → 30
   
   ENVIRONMENT
     → production
   
   ALLOWED_ORIGINS
     → * (先暫時允許所有，稍後更新)
   ```

6. **部署**:
   - 點擊 **Create Web Service**
   - 等待部署 (5-10 分鐘)
   - **複製 Service URL**: `https://heartbeat-backend-XXXXX.onrender.com`

---

### 步驟 3️⃣: 部署前端到 Netlify

#### 方案 A: 本地構建 + 上傳 (最簡單，推薦)

```powershell
# 1. 安裝 Netlify CLI
npm install -g netlify-cli

# 2. 登入 Netlify
netlify login
# 瀏覽器會開啟，點擊 "Authorize"

# 3. 構建前端 (替換為您的後端 URL)
cd c:\Users\user\2J1134\heartbeat-system\frontend

flutter build web --release `
  --dart-define=API_BASE_URL=https://heartbeat-backend-XXXXX.onrender.com `
  --dart-define=WS_BASE_URL=wss://heartbeat-backend-XXXXX.onrender.com

# 4. 部署到 Netlify
netlify deploy --prod --dir=build/web

# 5. 選擇:
#    - Create & configure a new site
#    - Team: 選擇您的 team
#    - Site name: heartbeat-app (或其他名稱)
#    - 確認部署

# 6. 複製網站 URL: https://heartbeat-app.netlify.app
```

#### 方案 B: 連接 GitHub (需要額外設置)

1. **前往 Netlify**: https://app.netlify.com

2. **創建新站點**:
   - **Add new site** → **Import an existing project**
   - 選擇 **GitHub** → 授權
   - 選擇 `heartbeat-system` repository

3. **配置** (⚠️ 需要手動處理 Flutter 構建):
   - Base directory: `frontend`
   - Build command: `echo "Please build locally"`
   - Publish directory: `frontend/build/web`

4. **使用本地構建上傳** (見方案 A)

---

### 步驟 4️⃣: 更新 CORS 設置

部署完成後:

1. **回到 Render Dashboard**
2. 找到 `heartbeat-backend` 服務
3. **Environment** → 編輯 `ALLOWED_ORIGINS`
4. 更新為:
   ```
   https://heartbeat-app.netlify.app
   ```
5. 儲存 → 服務會自動重新部署

---

## 🎉 完成！測試您的 APP

### 1. 測試後端

瀏覽器打開:
```
https://heartbeat-backend-XXXXX.onrender.com/docs
```

應該看到 Swagger API 文檔 ✅

### 2. 測試前端

瀏覽器打開:
```
https://heartbeat-app.netlify.app
```

應該看到登入頁面 ✅

### 3. 手機測試

1. 手機瀏覽器打開前端網址
2. 註冊新帳號
3. 測試隨機配對功能
4. **添加到主畫面** (參考 `MOBILE_INSTALLATION_GUIDE.md`)

---

## 📱 分享給朋友

現在任何人都能使用！分享網址:

```
🌍 https://heartbeat-app.netlify.app
```

**特點**:
- ✅ 全球訪問，無需同一 Wi-Fi
- ✅ 支援 iOS 和 Android
- ✅ 可添加到手機主畫面
- ✅ 免費託管

---

## 🆘 需要幫助?

如遇到問題:
1. 查看 **`CLOUD_DEPLOYMENT_GUIDE.md`** - 完整詳細指南
2. 查看故障排除章節
3. 檢查 Render 和 Netlify 的日誌

---

## 📊 部署狀態檢查清單

- [ ] GitHub repository 已創建並推送
- [ ] Render PostgreSQL 數據庫已創建
- [ ] Render Web Service 已部署成功
- [ ] 後端 API 文檔可訪問 (`/docs`)
- [ ] Netlify 前端已部署成功
- [ ] 前端可以訪問並顯示登入頁面
- [ ] CORS 已正確配置
- [ ] 註冊/登入功能正常
- [ ] 隨機配對功能正常
- [ ] 手機可以訪問並添加到主畫面

---

**恭喜！您的 APP 現在已經在雲端運行了！** 🎊🚀
