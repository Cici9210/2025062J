@echo off
chcp 65001 >nul
echo ========================================
echo 檢查心跳系統服務狀態
echo ========================================
echo.

echo [1/4] 檢查後端服務 (端口 8000)...
powershell -Command "try { $response = Invoke-WebRequest -Uri 'http://127.0.0.1:8000/health' -UseBasicParsing -TimeoutSec 5; if ($response.StatusCode -eq 200) { Write-Host '✓ 後端服務正常運行' -ForegroundColor Green } else { Write-Host '✗ 後端服務響應異常' -ForegroundColor Red } } catch { Write-Host '✗ 後端服務無法訪問' -ForegroundColor Red }"
echo.

echo [2/4] 檢查前端代理 (端口 8080)...
powershell -Command "try { $response = Invoke-WebRequest -Uri 'http://127.0.0.1:8080' -UseBasicParsing -TimeoutSec 5; if ($response.StatusCode -eq 200) { Write-Host '✓ 前端代理正常運行' -ForegroundColor Green } else { Write-Host '✗ 前端代理響應異常' -ForegroundColor Red } } catch { Write-Host '✗ 前端代理無法訪問' -ForegroundColor Red }"
echo.

echo [3/4] 檢查WiFi IP地址...
powershell -Command "$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -eq 'Wi-Fi'}).IPAddress; if ($ip) { Write-Host '✓ WiFi IP: ' -NoNewline -ForegroundColor Green; Write-Host $ip -ForegroundColor Cyan } else { Write-Host '✗ 未找到WiFi連接' -ForegroundColor Red }"
echo.

echo [4/4] 生成iPhone訪問URL...
powershell -Command "$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -eq 'Wi-Fi'}).IPAddress; if ($ip) { Write-Host '' ; Write-Host '📱 在iPhone上訪問:' -ForegroundColor Yellow ; Write-Host '   http://' -NoNewline -ForegroundColor White; Write-Host $ip -NoNewline -ForegroundColor Cyan; Write-Host ':8080' -ForegroundColor White }"
echo.

echo ========================================
echo 測試完成
echo ========================================
echo.
pause
