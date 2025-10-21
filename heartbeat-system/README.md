"""
系統執行指南 (README.md)
功能: 提供系統架構、安裝和執行說明
"""
# 壓感互動裝置系統

這是一個基於壓力感測的心臟互動系統，允許使用者通過觸摸互動並透過網路感受彼此的心跳。

## 系統架構

- **前端**: Flutter
- **後端**: FastAPI (Python 3.11+)
- **資料庫**: MySQL 8.0
- **即時通訊**: WebSocket
- **實體連接**: ESP32

## 安裝指南

### 1. 後端設置

1. 確保已安裝 Python 3.11+ 和 MySQL 8.0

2. 建立資料庫:
   ```bash
   mysql -u root -p < scripts/setup_db.sql
   ```

3. 安裝相依套件:
   ```bash
   cd backend
   pip install -r requirements.txt
   ```

4. 啟動後端服務:
   ```bash
   cd backend
   uvicorn app.main:app --reload
   ```
   伺服器將運行於 http://localhost:8000

### 2. 前端設置

1. 確保已安裝 Flutter SDK

2. 安裝相依套件:
   ```bash
   cd frontend
   flutter pub get
   ```

3. 啟動應用:
   ```bash
   cd frontend
   flutter run
   ```

### 3. ESP32 設置

1. 安裝 Arduino IDE 及 ESP32 開發板支援

2. 開啟 `esp32/config.h` 並設置您的 WiFi 和 WebSocket 連接參數

3. 將程式碼上傳到 ESP32 裝置

4. 參考以下腳位連接壓力感測器、RGB LED 和加熱元件:
   - 壓力感測器: GPIO36
   - RGB LED: GPIO25 (R), GPIO26 (G), GPIO27 (B)
   - 加熱元件: GPIO13

## 系統功能

1. **使用者管理**
   - 註冊/登入 (JWT認證)
   - 使用者資料更新

2. **裝置管理**
   - 綁定 ESP32 裝置
   - 查詢裝置狀態

3. **心臟互動**
   - 傳送/接收壓力節奏
   - 心跳與呼吸模擬 (LED + 加熱元件)

4. **配對機制**
   - 隨機配對
   - 雙向 WebSocket 通道

5. **視覺效果**
   - 漸層背景與脈動動畫
   - 心臟狀態視覺化

## API 文檔

啟動後端服務後，可以訪問 http://localhost:8000/docs 查看完整 API 文檔。

## 項目結構

```
heartbeat-system/
├── backend/             # FastAPI 後端
│   ├── app/
│   │   ├── api/         # API 端點
│   │   ├── database/    # 資料庫模型和連接
│   │   ├── schemas/     # Pydantic 模型
│   │   ├── services/    # 業務邏輯
│   │   └── utils/       # 工具函數
│   └── requirements.txt # 相依套件
├── frontend/            # Flutter 前端
│   ├── lib/
│   │   ├── config/      # 配置
│   │   ├── models/      # 資料模型
│   │   ├── providers/   # 狀態管理
│   │   ├── screens/     # 畫面
│   │   ├── services/    # API 服務
│   │   └── widgets/     # UI 元件
│   └── pubspec.yaml     # 相依套件
├── esp32/               # ESP32 程式碼
└── scripts/             # 資料庫和部署腳本
```

## 使用說明

1. 註冊並登入系統
2. 綁定您的壓感裝置
3. 開始互動或請求配對
4. 享受心臟共振體驗！

## 系統維護

- 資料庫備份: 定期使用 MySQL 備份功能
- 日誌管理: 後端記錄於標準輸出
- 錯誤報告: 請將問題回報至問題追蹤系統

## 許可協議

本專案採用 MIT 許可協議。
