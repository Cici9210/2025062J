@echo off
echo ========================================
echo 啟動心跳系統服務
echo ========================================
echo.

echo 正在停止舊的Python進程...
taskkill /F /IM python.exe /T 2>nul

timeout /t 2 /nobreak >nul

echo.
echo 正在啟動後端服務...
start "後端服務 - FastAPI" cmd /k "cd /d %~dp0backend && uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"

timeout /t 3 /nobreak >nul

echo.
echo 正在啟動前端代理...
start "前端代理 - HTTP Server" cmd /k "cd /d %~dp0frontend && python proxy.py"

timeout /t 2 /nobreak >nul

echo.
echo ========================================
echo 服務已啟動！
echo ========================================
echo.
echo 後端 API: http://0.0.0.0:8000
echo 前端應用: http://0.0.0.0:8080
echo.
echo 您的WiFi IP地址: 172.20.10.2
echo.
echo 在iPhone上訪問: http://172.20.10.2:8080
echo.
echo 按任意鍵關閉此視窗...
pause >nul
