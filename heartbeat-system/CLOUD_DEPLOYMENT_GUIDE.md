# 🚀 Heartbeat App - 雲端部署完整指南

## 📋 目錄
1. [準備工作](#準備工作)
2. [部署後端到 Render](#部署後端到-render)
3. [部署前端到 Netlify](#部署前端到-netlify)
4. [測試部署](#測試部署)
5. [故障排除](#故障排除)

---

## 🎯 準備工作

### 1. 註冊必要帳號

#### Render (後端)
1. 前往 https://render.com
2. 點擊 **Sign Up**
3. 選擇 **Sign up with GitHub** (推薦)
4. 授權 Render 訪問您的 GitHub

#### Netlify (前端)
1. 前往 https://netlify.com
2. 點擊 **Sign Up**
3. 選擇 **Sign up with GitHub** (推薦)
4. 授權 Netlify 訪問您的 GitHub

#### GitHub (代碼託管)
1. 如果還沒有帳號，前往 https://github.com 註冊
2. 創建新的 repository: `heartbeat-system`

---

### 2. 上傳代碼到 GitHub

#### 方法 1: 使用 Git 命令行 (推薦)

```powershell
# 進入專案目錄
cd c:\Users\user\2J1134\heartbeat-system

# 初始化 Git repository
git init

# 添加所有文件
git add .

# 提交變更
git commit -m "Initial commit - Heartbeat App"

# 添加遠程 repository (替換為您的 GitHub 用戶名)
git remote add origin https://github.com/YOUR_USERNAME/heartbeat-system.git

# 推送到 GitHub
git branch -M main
git push -u origin main
```

#### 方法 2: 使用 GitHub Desktop

1. 下載並安裝 GitHub Desktop: https://desktop.github.com
2. 登入您的 GitHub 帳號
3. **File → Add Local Repository** → 選擇 `c:\Users\user\2J1134\heartbeat-system`
4. 點擊 **Publish repository**
5. 取消勾選 "Keep this code private" (如果您想公開)
6. 點擊 **Publish Repository**

---

## 🔧 部署後端到 Render

### 步驟 1: 創建 Web Service

1. 登入 Render Dashboard: https://dashboard.render.com
2. 點擊 **New +** → 選擇 **Web Service**
3. 選擇 **Connect a repository** → 找到 `heartbeat-system`
4. 點擊 **Connect**

### 步驟 2: 配置服務

填寫以下資訊:

| 欄位 | 值 |
|------|-----|
| **Name** | `heartbeat-backend` |
| **Region** | `Singapore` (新加坡最近) |
| **Branch** | `main` |
| **Root Directory** | `backend` |
| **Runtime** | `Python 3` |
| **Build Command** | `pip install -r requirements.txt` |
| **Start Command** | `uvicorn app.main:app --host 0.0.0.0 --port $PORT` |
| **Instance Type** | `Free` |

### 步驟 3: 創建 PostgreSQL 數據庫

1. 在 Render Dashboard 點擊 **New +**
2. 選擇 **PostgreSQL**
3. 填寫資訊:
   - **Name**: `heartbeat-db`
   - **Region**: `Singapore`
   - **PostgreSQL Version**: `16`
   - **Instance Type**: `Free`
4. 點擊 **Create Database**
5. 等待數據庫創建完成 (約 1-2 分鐘)

### 步驟 4: 設置環境變數

回到 Web Service 設定頁面:

1. 找到 **Environment** 區塊
2. 點擊 **Add Environment Variable**
3. 添加以下變數:

```
DATABASE_URL
  → 點擊 "Add from a database" → 選擇 heartbeat-db → 選擇 "Internal Database URL"

SECRET_KEY
  → 點擊 "Generate" 自動生成強密碼

ALGORITHM
  → HS256

ACCESS_TOKEN_EXPIRE_MINUTES
  → 30

ENVIRONMENT
  → production

ALLOWED_ORIGINS
  → https://your-app.netlify.app (稍後更新)
```

### 步驟 5: 部署

1. 點擊 **Create Web Service**
2. 等待部署完成 (約 5-10 分鐘)
3. 部署成功後，您會看到 Service URL，例如:
   ```
   https://heartbeat-backend.onrender.com
   ```
4. **複製此 URL**，稍後會用到

### 步驟 6: 驗證後端

在瀏覽器打開:
```
https://heartbeat-backend.onrender.com/docs
```

應該看到 FastAPI 的 Swagger 文檔頁面 ✅

---

## 🎨 部署前端到 Netlify

### 步驟 1: 創建新站點

1. 登入 Netlify: https://app.netlify.com
2. 點擊 **Add new site** → **Import an existing project**
3. 選擇 **Deploy with GitHub**
4. 授權後，找到 `heartbeat-system` repository
5. 點擊 **Select**

### 步驟 2: 配置構建設置

填寫以下資訊:

| 欄位 | 值 |
|------|-----|
| **Base directory** | `frontend` |
| **Build command** | `flutter build web --release --dart-define=API_BASE_URL=$API_BASE_URL --dart-define=WS_BASE_URL=$WS_BASE_URL` |
| **Publish directory** | `frontend/build/web` |

### 步驟 3: 設置環境變數

1. 在部署前，點擊 **Advanced build settings**
2. 點擊 **New variable**
3. 添加環境變數:

```
API_BASE_URL
  → https://heartbeat-backend.onrender.com
  (使用您剛才複製的 Render URL)

WS_BASE_URL
  → wss://heartbeat-backend.onrender.com
  (注意: ws 改為 wss)
```

### 步驟 4: 安裝 Flutter 構建包

由於 Netlify 預設沒有 Flutter，我們需要使用構建插件:

1. 回到專案根目錄，創建 `netlify.toml` 配置 (已創建)
2. 或者使用替代方案: **在本地構建，上傳構建結果**

#### 替代方案: 本地構建 + 手動部署

```powershell
# 在本地構建前端
cd c:\Users\user\2J1134\heartbeat-system\frontend

# 設置環境變數並構建
flutter build web --release `
  --dart-define=API_BASE_URL=https://heartbeat-backend.onrender.com `
  --dart-define=WS_BASE_URL=wss://heartbeat-backend.onrender.com

# 構建完成後，使用 Netlify CLI 部署
npm install -g netlify-cli
netlify login
netlify deploy --prod --dir=build/web
```

### 步驟 5: 部署

1. 如果使用 Git 部署: 點擊 **Deploy site**
2. 如果使用本地構建: 執行 `netlify deploy --prod --dir=build/web`
3. 等待部署完成 (約 2-5 分鐘)
4. 部署成功後，您會獲得網址，例如:
   ```
   https://heartbeat-app-abc123.netlify.app
   ```

### 步驟 6: 更新後端 CORS 設置

1. 回到 Render Dashboard
2. 找到 `heartbeat-backend` 服務
3. 進入 **Environment** 設定
4. 更新 `ALLOWED_ORIGINS` 變數:
   ```
   https://heartbeat-app-abc123.netlify.app
   ```
5. 儲存後，服務會自動重新部署

---

## ✅ 測試部署

### 1. 測試後端 API

```powershell
# 測試註冊
curl -X POST "https://heartbeat-backend.onrender.com/api/auth/register" `
  -H "Content-Type: application/json" `
  -d '{"email":"test@example.com","password":"Test123!"}'

# 測試登入
curl -X POST "https://heartbeat-backend.onrender.com/api/auth/token" `
  -d "username=test@example.com&password=Test123!"
```

### 2. 測試前端 APP

1. 打開瀏覽器，訪問您的 Netlify URL:
   ```
   https://heartbeat-app-abc123.netlify.app
   ```

2. 測試註冊功能:
   - 點擊「註冊」
   - 填寫 Email 和密碼
   - 應該成功註冊並自動登入

3. 測試隨機配對:
   - 使用兩個瀏覽器視窗 (或無痕模式)
   - 兩個帳號同時點擊「隨機配對」
   - 應該成功配對

### 3. 在手機上測試

1. **確保手機連接網路** (任何 Wi-Fi 或行動網路都可以)
2. 打開手機瀏覽器 (Safari 或 Chrome)
3. 輸入網址: `https://heartbeat-app-abc123.netlify.app`
4. **添加到主畫面** (參考 MOBILE_INSTALLATION_GUIDE.md)

---

## 🎉 分享給朋友

現在任何人都可以使用您的 APP 了！只需分享網址:

```
https://heartbeat-app-abc123.netlify.app
```

**特點**:
- ✅ 全球任何地方都能訪問
- ✅ 支援 iOS 和 Android
- ✅ 可以添加到手機主畫面
- ✅ 免費託管

---

## 🔧 故障排除

### 問題 1: Render 部署失敗

**檢查**:
1. 查看 Render Logs: Dashboard → Service → Logs
2. 常見錯誤:
   - `ModuleNotFoundError`: 檢查 `requirements.txt`
   - `Port binding error`: 確保使用 `$PORT` 環境變數

**解決**:
```bash
# 確保 start command 正確
uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

### 問題 2: Netlify 構建失敗

**原因**: Netlify 預設沒有 Flutter

**解決方案 A - 使用本地構建**:
```powershell
cd frontend
flutter build web --release `
  --dart-define=API_BASE_URL=https://heartbeat-backend.onrender.com `
  --dart-define=WS_BASE_URL=wss://heartbeat-backend.onrender.com

netlify deploy --prod --dir=build/web
```

**解決方案 B - 使用 GitHub Actions** (已創建配置文件):
- 推送到 GitHub 後自動構建和部署

### 問題 3: CORS 錯誤

**症狀**: 前端無法連接後端，瀏覽器控制台顯示 CORS 錯誤

**解決**:
1. 確認後端的 `ALLOWED_ORIGINS` 包含前端網址
2. 在 Render Dashboard 更新環境變數:
   ```
   ALLOWED_ORIGINS=https://your-app.netlify.app,https://another-app.netlify.app
   ```
3. 儲存後會自動重新部署

### 問題 4: 數據庫連接失敗

**檢查**:
1. Render Dashboard → PostgreSQL → 確認數據庫狀態為 "Available"
2. 確認 `DATABASE_URL` 環境變數已正確設置
3. 查看服務日誌確認連接字串

**解決**:
- 重新連接數據庫: Environment → DATABASE_URL → 選擇 "Internal Database URL"

### 問題 5: Render 服務進入休眠

**原因**: Free plan 閒置 15 分鐘後會休眠

**現象**: 第一次訪問很慢 (30-60 秒)

**解決方案**:
1. **升級到付費方案** ($7/月) - 不會休眠
2. **使用 Uptime Monitor** - 定期喚醒服務
   - 註冊 https://uptimerobot.com (免費)
   - 添加監控: 每 5 分鐘 ping 一次後端
3. **接受現狀** - 首次訪問較慢，後續正常

---

## 🔄 更新部署

### 更新後端

```powershell
cd c:\Users\user\2J1134\heartbeat-system

# 修改代碼後
git add .
git commit -m "Update backend features"
git push

# Render 會自動檢測變更並重新部署
```

### 更新前端

```powershell
# 方案 A: 推送到 GitHub (自動部署)
git add .
git commit -m "Update frontend UI"
git push

# 方案 B: 本地構建並部署
cd frontend
flutter build web --release `
  --dart-define=API_BASE_URL=https://heartbeat-backend.onrender.com `
  --dart-define=WS_BASE_URL=wss://heartbeat-backend.onrender.com
netlify deploy --prod --dir=build/web
```

---

## 💰 成本估算

### 免費方案
- **Render Free**: PostgreSQL 1GB, Web Service 750小時/月
- **Netlify Free**: 100GB 流量/月, 300 構建分鐘/月
- **總成本**: $0/月 ✅

**限制**:
- Render 服務閒置 15 分鐘後休眠
- PostgreSQL 數據庫 90 天後會被刪除 (需手動續期)

### 付費方案 (推薦生產環境)
- **Render Starter**: $7/月 (不休眠)
- **Render PostgreSQL**: $7/月 (永久保存)
- **Netlify Pro**: $19/月 (進階功能)
- **推薦組合**: Render Starter + PostgreSQL = $14/月

---

## 📊 監控和日誌

### Render 日誌
1. Dashboard → Service → Logs
2. 即時查看應用程式輸出
3. 可以下載歷史日誌

### Netlify 分析
1. Site → Analytics
2. 查看訪問量、流量使用
3. 查看構建歷史

---

## 🎓 下一步

部署完成後，您可以:

1. **設置自訂域名**:
   - Netlify: Site settings → Domain management
   - Render: Settings → Custom domain

2. **啟用 HTTPS** (自動):
   - Render 和 Netlify 都會自動提供 SSL 證書

3. **設置 CI/CD**:
   - 使用已創建的 `.github/workflows/deploy.yml`
   - 每次推送到 main 分支自動部署

4. **監控應用健康**:
   - 使用 UptimeRobot 監控服務可用性
   - 使用 Sentry 追蹤錯誤

---

## 📞 需要幫助?

如遇到問題:
1. 查看 Render 和 Netlify 的日誌
2. 檢查本指南的故障排除章節
3. 查看官方文檔:
   - Render: https://render.com/docs
   - Netlify: https://docs.netlify.com

---

**恭喜！您的 APP 現在已經部署到雲端，全世界的人都能使用了！** 🎉🌍
