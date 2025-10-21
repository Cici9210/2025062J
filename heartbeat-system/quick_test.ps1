# 快速功能驗證測試
$ErrorActionPreference = "Continue"

Write-Host "`n========== 心跳系統功能測試摘要 ==========" -ForegroundColor Cyan
Write-Host ""

$testResults = @()

# 1. 服務狀態
Write-Host "[1] 檢查服務狀態..." -ForegroundColor Yellow
try {
    $backend = Invoke-WebRequest "http://localhost:8000/docs" -TimeoutSec 3
    $frontend = Invoke-WebRequest "http://localhost:8080" -TimeoutSec 3
    Write-Host "    ✓ 後端運行中 (Port 8000)" -ForegroundColor Green
    Write-Host "    ✓ 前端運行中 (Port 8080)" -ForegroundColor Green
    $testResults += @{name="服務狀態"; result="PASS"}
} catch {
    Write-Host "    ✗ 服務檢查失敗" -ForegroundColor Red
    $testResults += @{name="服務狀態"; result="FAIL"}
}

# 2. 用戶認證
Write-Host "`n[2] 測試用戶認證..." -ForegroundColor Yellow
try {
    $timestamp = Get-Date -Format "HHmmss"
    $email = "quicktest_$timestamp@test.com"
    
    # 註冊
    $user = Invoke-RestMethod "http://localhost:8000/api/auth/register" `
        -Method POST -ContentType "application/json" `
        -Body (@{email=$email; password="test123"; username="QuickTest"} | ConvertTo-Json)
    
    # 登錄
    $login = Invoke-RestMethod "http://localhost:8000/api/auth/token" `
        -Method POST -ContentType "application/x-www-form-urlencoded" `
        -Body @{username=$email; password="test123"}
    
    Write-Host "    ✓ 用戶註冊成功: $email" -ForegroundColor Green
    Write-Host "    ✓ 用戶登錄成功,獲得 Token" -ForegroundColor Green
    $testResults += @{name="用戶認證"; result="PASS"}
    $token = $login.access_token
} catch {
    Write-Host "    ✗ 認證測試失敗: $_" -ForegroundColor Red
    $testResults += @{name="用戶認證"; result="FAIL"}
}

# 3. ESP32 設備連接
Write-Host "`n[3] 測試 ESP32 設備連接..." -ForegroundColor Yellow
try {
    $deviceUID = "ESP32_QUICK_$timestamp"
    
    # 註冊設備
    $device = Invoke-RestMethod "http://localhost:8000/api/devices/register?device_uid=$deviceUID" `
        -Method POST -ContentType "application/json" -Body "{}"
    
    # 上傳壓力數據
    $pressure = Invoke-RestMethod "http://localhost:8000/api/devices/pressure?device_uid=$deviceUID&pressure=80" `
        -Method POST -ContentType "application/json" -Body "{}"
    
    # 綁定設備
    $bind = Invoke-RestMethod "http://localhost:8000/api/devices/bind?device_uid=$deviceUID&name=QuickTestDevice" `
        -Method POST -Headers @{Authorization="Bearer $token"} -ContentType "application/json" -Body "{}"
    
    Write-Host "    ✓ 設備註冊成功: $deviceUID" -ForegroundColor Green
    Write-Host "    ✓ 壓力數據上傳成功: $($pressure.pressure_value)" -ForegroundColor Green
    Write-Host "    ✓ 設備綁定成功" -ForegroundColor Green
    $testResults += @{name="ESP32 連接"; result="PASS"}
} catch {
    Write-Host "    ✗ 設備測試失敗: $_" -ForegroundColor Red
    $testResults += @{name="ESP32 連接"; result="FAIL"}
}

# 4. 隨機配對
Write-Host "`n[4] 測試隨機配對..." -ForegroundColor Yellow
try {
    # 創建第二個用戶
    $email2 = "quicktest_${timestamp}_b@test.com"
    $user2 = Invoke-RestMethod "http://localhost:8000/api/auth/register" `
        -Method POST -ContentType "application/json" `
        -Body (@{email=$email2; password="test123"; username="QuickTest2"} | ConvertTo-Json)
    
    $login2 = Invoke-RestMethod "http://localhost:8000/api/auth/token" `
        -Method POST -ContentType "application/x-www-form-urlencoded" `
        -Body @{username=$email2; password="test123"}
    $token2 = $login2.access_token
    
    # 用戶1加入隊列
    $queue1 = Invoke-RestMethod "http://localhost:8000/api/pairing/random-match" `
        -Method POST -Headers @{Authorization="Bearer $token"} -ContentType "application/json" -Body "{}"
    
    # 用戶2加入隊列(應該匹配)
    $queue2 = Invoke-RestMethod "http://localhost:8000/api/pairing/random-match" `
        -Method POST -Headers @{Authorization="Bearer $token2"} -ContentType "application/json" -Body "{}"
    
    if ($queue2.status -eq "matched" -and $queue2.chat_room_id) {
        Write-Host "    ✓ 隨機配對成功" -ForegroundColor Green
        Write-Host "    ✓ 創建臨時聊天室 ID: $($queue2.chat_room_id)" -ForegroundColor Green
        $testResults += @{name="隨機配對"; result="PASS"}
        $chatRoomId = $queue2.chat_room_id
    } else {
        Write-Host "    ✗ 配對失敗" -ForegroundColor Red
        $testResults += @{name="隨機配對"; result="FAIL"}
    }
} catch {
    Write-Host "    ✗ 配對測試失敗: $_" -ForegroundColor Red
    $testResults += @{name="隨機配對"; result="FAIL"}
}

# 5. 聊天室到期機制
Write-Host "`n[5] 測試臨時聊天室 (30秒過期)..." -ForegroundColor Yellow
if ($chatRoomId) {
    Write-Host "    等待 35 秒讓聊天室過期..." -ForegroundColor Gray
    Start-Sleep -Seconds 35
    
    try {
        $expiry = Invoke-RestMethod "http://localhost:8000/api/pairing/chat-room/$chatRoomId/check-expiry" `
            -Method POST -Headers @{Authorization="Bearer $token"} -ContentType "application/json" -Body "{}"
        
        if ($expiry.expired -and $expiry.invitation_created) {
            Write-Host "    ✓ 聊天室成功過期" -ForegroundColor Green
            Write-Host "    ✓ 自動創建好友邀請 ID: $($expiry.invitation_id)" -ForegroundColor Green
            $testResults += @{name="臨時聊天室"; result="PASS"}
            $invitationId = $expiry.invitation_id
        } else {
            Write-Host "    ✗ 聊天室未按預期過期" -ForegroundColor Red
            $testResults += @{name="臨時聊天室"; result="FAIL"}
        }
    } catch {
        Write-Host "    ✗ 過期檢查失敗: $_" -ForegroundColor Red
        $testResults += @{name="臨時聊天室"; result="FAIL"}
    }
} else {
    Write-Host "    - 跳過 (無聊天室)" -ForegroundColor Gray
    $testResults += @{name="臨時聊天室"; result="SKIP"}
}

# 6. 好友系統
Write-Host "`n[6] 測試好友系統..." -ForegroundColor Yellow
if ($invitationId) {
    try {
        # 用戶2接受邀請
        $accept = Invoke-RestMethod "http://localhost:8000/api/pairing/friend-invitations/$invitationId/accept" `
            -Method POST -Headers @{Authorization="Bearer $token2"} -ContentType "application/json" -Body "{}"
        
        # 查看好友列表
        $friends = Invoke-RestMethod "http://localhost:8000/api/pairing/friends" `
            -Method GET -Headers @{Authorization="Bearer $token"}
        
        if ($accept.friendship_id -and $friends.Count -gt 0) {
            Write-Host "    ✓ 接受好友邀請成功" -ForegroundColor Green
            Write-Host "    ✓ 創建永久聊天室 ID: $($accept.chat_room_id)" -ForegroundColor Green
            Write-Host "    ✓ 好友列表顯示正常 (共 $($friends.Count) 個好友)" -ForegroundColor Green
            $testResults += @{name="好友系統"; result="PASS"}
        } else {
            Write-Host "    ✗ 好友功能異常" -ForegroundColor Red
            $testResults += @{name="好友系統"; result="FAIL"}
        }
    } catch {
        Write-Host "    ✗ 好友測試失敗: $_" -ForegroundColor Red
        $testResults += @{name="好友系統"; result="FAIL"}
    }
} else {
    Write-Host "    - 跳過 (無好友邀請)" -ForegroundColor Gray
    $testResults += @{name="好友系統"; result="SKIP"}
}

# 7. 好友裝置狀態
Write-Host "`n[7] 測試好友裝置狀態查看..." -ForegroundColor Yellow
try {
    $devices = Invoke-RestMethod "http://localhost:8000/api/devices/friends/devices" `
        -Method GET -Headers @{Authorization="Bearer $token2"}
    
    Write-Host "    ✓ 獲取好友裝置列表成功" -ForegroundColor Green
    if ($devices.Count -gt 0) {
        Write-Host "    ✓ 找到 $($devices.Count) 個好友裝置" -ForegroundColor Green
        foreach ($dev in $devices) {
            $status = if ($dev.is_online) { "在線" } else { "離線" }
            Write-Host "      - $($dev.name): $status" -ForegroundColor Gray
        }
    }
    $testResults += @{name="好友裝置狀態"; result="PASS"}
} catch {
    Write-Host "    ✗ 裝置狀態測試失敗: $_" -ForegroundColor Red
    $testResults += @{name="好友裝置狀態"; result="FAIL"}
}

# 測試摘要
Write-Host "`n========== 測試摘要 ==========" -ForegroundColor Cyan
$passed = ($testResults | Where-Object {$_.result -eq "PASS"}).Count
$failed = ($testResults | Where-Object {$_.result -eq "FAIL"}).Count
$skipped = ($testResults | Where-Object {$_.result -eq "SKIP"}).Count
$total = $testResults.Count

Write-Host "總測試數: $total" -ForegroundColor White
Write-Host "通過: $passed" -ForegroundColor Green
Write-Host "失敗: $failed" -ForegroundColor Red
Write-Host "跳過: $skipped" -ForegroundColor Yellow

if ($failed -eq 0) {
    Write-Host "`n✓ 所有測試通過! 四大功能全部正常運作!" -ForegroundColor Green
} else {
    $rate = [math]::Round(($passed / ($total - $skipped)) * 100, 1)
    Write-Host "`n成功率: $rate%" -ForegroundColor $(if($rate -ge 80){"Green"}elseif($rate -ge 60){"Yellow"}else{"Red"})
}

Write-Host "`n測試完成!" -ForegroundColor Cyan
