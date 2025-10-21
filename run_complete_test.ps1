# 完整系統測試腳本
# 測試所有四大功能：ESP32連接、隨機配對、臨時聊天室、好友功能

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   心跳壓感互動系統 - 完整測試" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 設置變量
$API = "http://192.168.1.114:8000"
$testPassed = 0
$testFailed = 0

function Test-Result {
    param($name, $result)
    if ($result) {
        Write-Host "✓ $name" -ForegroundColor Green
        $script:testPassed++
    } else {
        Write-Host "✗ $name" -ForegroundColor Red
        $script:testFailed++
    }
}

# ==========================================
# 測試 1: 檢查服務狀態
# ==========================================
Write-Host "`n[測試 1] 檢查服務狀態" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

try {
    $response = Invoke-WebRequest -Uri "$API/docs" -Method GET -TimeoutSec 5
    Test-Result "後端服務運行中" ($response.StatusCode -eq 200)
} catch {
    Test-Result "後端服務運行中" $false
    Write-Host "錯誤: $_" -ForegroundColor Red
}

try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080" -Method GET -TimeoutSec 5
    Test-Result "前端服務運行中" ($response.StatusCode -eq 200)
} catch {
    Test-Result "前端服務運行中" $false
    Write-Host "錯誤: $_" -ForegroundColor Red
}

# ==========================================
# 測試 2: 用戶註冊和登入
# ==========================================
Write-Host "`n[測試 2] 用戶註冊和登入" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

# 生成隨機測試用戶
$timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
$emailA = "test_a_$timestamp@example.com"
$emailB = "test_b_$timestamp@example.com"
$password = "Test123!"

# 註冊用戶A
try {
    $userA = Invoke-RestMethod "$API/api/auth/register" -Method POST `
        -Body (@{email=$emailA; password=$password} | ConvertTo-Json) `
        -ContentType "application/json"
    Test-Result "用戶A註冊成功 ($emailA)" ($null -ne $userA)
    Write-Host "  用戶ID: $($userA.id)" -ForegroundColor Gray
} catch {
    Test-Result "用戶A註冊成功" $false
    Write-Host "錯誤: $_" -ForegroundColor Red
}

# 註冊用戶B
try {
    $userB = Invoke-RestMethod "$API/api/auth/register" -Method POST `
        -Body (@{email=$emailB; password=$password} | ConvertTo-Json) `
        -ContentType "application/json"
    Test-Result "用戶B註冊成功 ($emailB)" ($null -ne $userB)
    Write-Host "  用戶ID: $($userB.id)" -ForegroundColor Gray
} catch {
    Test-Result "用戶B註冊成功" $false
    Write-Host "錯誤: $_" -ForegroundColor Red
}

# 用戶A登入
try {
    $tokenA = (Invoke-RestMethod "$API/api/auth/token" -Method POST `
        -Body "username=$emailA&password=$password" `
        -ContentType "application/x-www-form-urlencoded").access_token
    Test-Result "用戶A登入成功" ($null -ne $tokenA)
    Write-Host "  Token: $($tokenA.Substring(0, 20))..." -ForegroundColor Gray
} catch {
    Test-Result "用戶A登入成功" $false
    Write-Host "錯誤: $_" -ForegroundColor Red
}

# 用戶B登入
try {
    $tokenB = (Invoke-RestMethod "$API/api/auth/token" -Method POST `
        -Body "username=$emailB&password=$password" `
        -ContentType "application/x-www-form-urlencoded").access_token
    Test-Result "用戶B登入成功" ($null -ne $tokenB)
    Write-Host "  Token: $($tokenB.Substring(0, 20))..." -ForegroundColor Gray
} catch {
    Test-Result "用戶B登入成功" $false
    Write-Host "錯誤: $_" -ForegroundColor Red
}

# ==========================================
# 測試 3: ESP32裝置連接
# ==========================================
Write-Host "`n[測試 3] ESP32裝置連接和數據上傳" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

# 模擬ESP32註冊
$deviceUID = "ESP32_TEST_$timestamp"
try {
    $device = Invoke-RestMethod "$API/api/devices/register?device_uid=$deviceUID" `
        -Method POST -ContentType "application/json" -Body "{}"
    Test-Result "ESP32裝置註冊成功" ($null -ne $device)
    Write-Host "  裝置ID: $($device.id)" -ForegroundColor Gray
    Write-Host "  裝置UID: $($device.device_uid)" -ForegroundColor Gray
} catch {
    Test-Result "ESP32裝置註冊成功" $false
    Write-Host "錯誤: $_" -ForegroundColor Red
}

# 模擬上傳壓力數據
try {
    $pressureUrl = "$API/api/devices/pressure?device_uid=$deviceUID" + "&pressure=75"
    $pressure = Invoke-RestMethod $pressureUrl `
        -Method POST -ContentType "application/json" -Body "{}"
    Test-Result "壓力數據上傳成功" ($null -ne $pressure)
    Write-Host "  壓力值: $($pressure.pressure_value)" -ForegroundColor Gray
} catch {
    Test-Result "壓力數據上傳成功" $false
    Write-Host "錯誤: $_" -ForegroundColor Red
}

# 用戶A綁定裝置
try {
    $bindUrl = "$API/api/devices/bind?device_uid=$deviceUID" + "&name=TestDevice"
    $binding = Invoke-RestMethod $bindUrl `
        -Method POST -Headers @{Authorization="Bearer $tokenA"} `
        -ContentType "application/json"
    Test-Result "用戶A綁定裝置成功" ($null -ne $binding)
} catch {
    Test-Result "用戶A綁定裝置成功" $false
    Write-Host "錯誤: $_" -ForegroundColor Red
}

# 獲取用戶裝置列表
try {
    $devices = Invoke-RestMethod "$API/api/devices/my" `
        -Headers @{Authorization="Bearer $tokenA"}
    Test-Result "獲取裝置列表成功" ($devices.Count -gt 0)
    Write-Host "  裝置數量: $($devices.Count)" -ForegroundColor Gray
} catch {
    Test-Result "獲取裝置列表成功" $false
    Write-Host "錯誤: $_" -ForegroundColor Red
}

# ==========================================
# 測試 4: 隨機配對功能
# ==========================================
Write-Host "`n[測試 4] 隨機配對功能" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

# 用戶A請求配對
try {
    $matchA = Invoke-RestMethod "$API/api/pairing/random-match" `
        -Method POST -Headers @{Authorization="Bearer $tokenA"}
    Test-Result "用戶A加入配對隊列" ($null -ne $matchA)
    Write-Host "  狀態: $($matchA.message)" -ForegroundColor Gray
} catch {
    Test-Result "用戶A加入配對隊列" $false
    Write-Host "錯誤: $_" -ForegroundColor Red
}

Start-Sleep -Seconds 2

# 用戶B請求配對
try {
    $matchB = Invoke-RestMethod "$API/api/pairing/random-match" `
        -Method POST -Headers @{Authorization="Bearer $tokenB"}
    Test-Result "用戶B配對成功" ($matchB.matched -eq $true)
    Write-Host "  配對ID: $($matchB.pairing_id)" -ForegroundColor Gray
    Write-Host "  聊天室ID: $($matchB.chat_room_id)" -ForegroundColor Gray
    Write-Host "  對方: $($matchB.other_user_email)" -ForegroundColor Gray
    $chatRoomId = $matchB.chat_room_id
} catch {
    Test-Result "用戶B配對成功" $false
    Write-Host "錯誤: $_" -ForegroundColor Red
}

# ==========================================
# 測試 5: 臨時聊天室
# ==========================================
Write-Host "`n[測試 5] 臨時聊天室功能" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

# 查看聊天室
try {
    $rooms = Invoke-RestMethod "$API/api/pairing/chat-rooms" `
        -Headers @{Authorization="Bearer $tokenA"}
    Test-Result "獲取聊天室列表成功" ($rooms.Count -gt 0)
    
    if ($rooms.Count -gt 0) {
        $room = $rooms[0]
        Write-Host "  聊天室ID: $($room.id)" -ForegroundColor Gray
        Write-Host "  類型: $($room.room_type)" -ForegroundColor Gray
        Write-Host "  過期時間: $($room.expires_at)" -ForegroundColor Gray
        Write-Host "  對方: $($room.other_user_email)" -ForegroundColor Gray
    }
} catch {
    Test-Result "獲取聊天室列表成功" $false
    Write-Host "錯誤: $_" -ForegroundColor Red
}

# 等待聊天室過期（測試模式：30秒）
Write-Host "`n  等待聊天室過期 (30秒測試模式)..." -ForegroundColor Cyan
for ($i = 30; $i -gt 0; $i--) {
    Write-Host "`r  倒數: $i 秒... " -NoNewline -ForegroundColor Yellow
    Start-Sleep -Seconds 1
}
Write-Host "`r  倒數完成!        " -ForegroundColor Green

# 檢查過期並創建邀請
try {
    $expiry = Invoke-RestMethod "$API/api/pairing/chat-room/$chatRoomId/check-expiry" `
        -Method POST -Headers @{Authorization="Bearer $tokenA"}
    $isExpired = $expiry.expired -eq $true
    $isInvited = $expiry.invitation_created -eq $true
    Test-Result "聊天室過期檢查成功" $isExpired
    Test-Result "好友邀請已創建" $isInvited
    Write-Host "  邀請ID: $($expiry.invitation_id)" -ForegroundColor Gray
} catch {
    Test-Result "聊天室過期檢查成功" $false
    Write-Host "錯誤: $_" -ForegroundColor Red
}

# ==========================================
# 測試 6: 好友邀請和永久聊天室
# ==========================================
Write-Host "`n[測試 6] 好友邀請和永久聊天室" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

# 查看邀請
try {
    $invitations = Invoke-RestMethod "$API/api/pairing/invitations" `
        -Headers @{Authorization="Bearer $tokenA"}
    Test-Result "獲取好友邀請列表成功" ($invitations.Count -gt 0)
    
    if ($invitations.Count -gt 0) {
        $invitation = $invitations[0]
        Write-Host "  邀請ID: $($invitation.id)" -ForegroundColor Gray
        Write-Host "  對方: $($invitation.other_user_email)" -ForegroundColor Gray
        Write-Host "  狀態: $($invitation.status)" -ForegroundColor Gray
        $invitationId = $invitation.id
    }
} catch {
    Test-Result "獲取好友邀請列表成功" $false
    Write-Host "錯誤: $_" -ForegroundColor Red
}

# 用戶A接受邀請
try {
    $acceptA = Invoke-RestMethod "$API/api/pairing/invitations/$invitationId/respond" `
        -Method POST -Headers @{Authorization="Bearer $tokenA"} `
        -Body (@{response="accept"} | ConvertTo-Json) `
        -ContentType "application/json"
    Test-Result "用戶A接受邀請成功" ($acceptA.success -eq $true)
    Write-Host "  訊息: $($acceptA.message)" -ForegroundColor Gray
} catch {
    Test-Result "用戶A接受邀請成功" $false
    Write-Host "錯誤: $_" -ForegroundColor Red
}

# 用戶B接受邀請
try {
    $acceptB = Invoke-RestMethod "$API/api/pairing/invitations/$invitationId/respond" `
        -Method POST -Headers @{Authorization="Bearer $tokenB"} `
        -Body (@{response="accept"} | ConvertTo-Json) `
        -ContentType "application/json"
    Test-Result "用戶B接受邀請成功" ($acceptB.success -eq $true)
    Test-Result "雙方成為好友" ($acceptB.became_friends -eq $true)
    Write-Host "  訊息: $($acceptB.message)" -ForegroundColor Gray
} catch {
    Test-Result "用戶B接受邀請成功" $false
    Write-Host "錯誤: $_" -ForegroundColor Red
}

# 查看好友列表
try {
    $friends = Invoke-RestMethod "$API/api/pairing/friends" `
        -Headers @{Authorization="Bearer $tokenA"}
    Test-Result "獲取好友列表成功" ($friends.Count -gt 0)
    Write-Host "  好友數量: $($friends.Count)" -ForegroundColor Gray
    if ($friends.Count -gt 0) {
        Write-Host "  好友: $($friends[0].email)" -ForegroundColor Gray
    }
} catch {
    Test-Result "獲取好友列表成功" $false
    Write-Host "錯誤: $_" -ForegroundColor Red
}

# 檢查聊天室是否升級為永久
try {
    $permanentRooms = Invoke-RestMethod "$API/api/pairing/chat-rooms" `
        -Headers @{Authorization="Bearer $tokenA"}
    
    if ($permanentRooms.Count -gt 0) {
        $permanentRoom = $permanentRooms[0]
        $isPermanent = $permanentRoom.room_type -eq "permanent"
        Test-Result "聊天室已升級為永久" $isPermanent
        Write-Host "  聊天室類型: $($permanentRoom.room_type)" -ForegroundColor Gray
        Write-Host "  是否為好友: $($permanentRoom.is_friend)" -ForegroundColor Gray
        Write-Host "  過期時間: $($permanentRoom.expires_at)" -ForegroundColor Gray
    } else {
        Test-Result "聊天室已升級為永久" $false
    }
} catch {
    Test-Result "聊天室已升級為永久" $false
    Write-Host "錯誤: $_" -ForegroundColor Red
}

# ==========================================
# 測試 7: 好友裝置狀態查看
# ==========================================
Write-Host "`n[測試 7] 好友裝置狀態查看" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

# 用戶B綁定裝置
$deviceUIDB = "ESP32_TEST_B_$timestamp"
try {
    Invoke-RestMethod "$API/api/devices/register?device_uid=$deviceUIDB" `
        -Method POST -ContentType "application/json" -Body "{}" | Out-Null
    
    $bindingB = Invoke-RestMethod "$API/api/devices/bind?device_uid=$deviceUIDB&name=測試裝置B" `
        -Method POST -Headers @{Authorization="Bearer $tokenB"} `
        -ContentType "application/json"
    Test-Result "用戶B綁定裝置成功" ($null -ne $bindingB)
} catch {
    Test-Result "用戶B綁定裝置成功" $false
    Write-Host "錯誤: $_" -ForegroundColor Red
}

# 用戶A查看好友裝置狀態
try {
    $friendDevices = Invoke-RestMethod "$API/api/devices/friends/devices" `
        -Headers @{Authorization="Bearer $tokenA"}
    Test-Result "獲取好友裝置狀態成功" ($friendDevices.Count -gt 0)
    
    if ($friendDevices.Count -gt 0) {
        $friendDevice = $friendDevices[0]
        Write-Host "  好友: $($friendDevice.friend_email)" -ForegroundColor Gray
        Write-Host "  裝置: $($friendDevice.device_name)" -ForegroundColor Gray
        Write-Host "  在線: $($friendDevice.is_online)" -ForegroundColor Gray
    }
} catch {
    Test-Result "獲取好友裝置狀態成功" $false
    Write-Host "錯誤: $_" -ForegroundColor Red
}

# ==========================================
# 測試總結
# ==========================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "            測試總結" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "通過測試: " -NoNewline
Write-Host "$testPassed" -ForegroundColor Green
Write-Host "失敗測試: " -NoNewline
Write-Host "$testFailed" -ForegroundColor Red
Write-Host "總計測試: " -NoNewline
Write-Host "$($testPassed + $testFailed)" -ForegroundColor Cyan

$successRate = [math]::Round(($testPassed / ($testPassed + $testFailed)) * 100, 2)
Write-Host "成功率: " -NoNewline
if ($successRate -eq 100) {
    Write-Host "$successRate%" -ForegroundColor Green
} elseif ($successRate -ge 80) {
    Write-Host "$successRate%" -ForegroundColor Yellow
} else {
    Write-Host "$successRate%" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan

if ($testFailed -eq 0) {
    Write-Host "🎉 所有測試通過！系統運行正常！" -ForegroundColor Green
} else {
    Write-Host "⚠️  部分測試失敗，請檢查上面的錯誤信息" -ForegroundColor Yellow
}

Write-Host ""

# 測試用戶信息
Write-Host "測試用戶信息（保存以便後續使用）:" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Gray
Write-Host "用戶A: $emailA" -ForegroundColor White
Write-Host "用戶B: $emailB" -ForegroundColor White
Write-Host "密碼: $password" -ForegroundColor White
Write-Host "Token A: $($tokenA.Substring(0, 30))..." -ForegroundColor Gray
Write-Host "Token B: $($tokenB.Substring(0, 30))..." -ForegroundColor Gray
Write-Host ""
