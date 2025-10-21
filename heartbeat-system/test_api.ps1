# 完整系統測試腳本
# 編碼: UTF-8 with BOM
$ErrorActionPreference = "Continue"

$API = "http://localhost:8000"
$timestamp = Get-Date -Format "HHmmss"
$testPassed = 0
$testFailed = 0

function Test-Result {
    param($name, $result)
    if ($result) {
        Write-Host "[PASS] $name" -ForegroundColor Green
        $script:testPassed++
    } else {
        Write-Host "[FAIL] $name" -ForegroundColor Red
        $script:testFailed++
    }
}

Write-Host "`n========== 1. Service Status Check ==========" -ForegroundColor Cyan

try {
    $response = Invoke-WebRequest -Uri "$API/docs" -Method GET -TimeoutSec 5
    Test-Result "Backend service running" ($response.StatusCode -eq 200)
} catch {
    Test-Result "Backend service running" $false
}

try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080" -Method GET -TimeoutSec 5
    Test-Result "Frontend service running" ($response.StatusCode -eq 200)
} catch {
    Test-Result "Frontend service running" $false
}

Write-Host "`n========== 2. User Registration & Login ==========" -ForegroundColor Cyan

$emailA = "testuser_${timestamp}_a@test.com"
$emailB = "testuser_${timestamp}_b@test.com"
$password = "test123456"

# Register User A
try {
    $registerA = Invoke-RestMethod "$API/api/auth/register" `
        -Method POST -ContentType "application/json" `
        -Body (@{email=$emailA; password=$password; username="TestUserA"} | ConvertTo-Json)
    Test-Result "User A registered" ($null -ne $registerA.email)
    Write-Host "  User A Email: $($registerA.email)" -ForegroundColor Gray
    
    # Login User A
    $loginDataA = @{username=$emailA; password=$password}
    $loginA = Invoke-RestMethod "$API/api/auth/token" `
        -Method POST -ContentType "application/x-www-form-urlencoded" `
        -Body $loginDataA
    $tokenA = $loginA.access_token
    Test-Result "User A logged in" ($null -ne $tokenA)
    Write-Host "  User A Token: $($tokenA.Substring(0,20))..." -ForegroundColor Gray
} catch {
    Test-Result "User A authentication" $false
    Write-Host "  Error: $_" -ForegroundColor Red
}

# Register User B
try {
    $registerB = Invoke-RestMethod "$API/api/auth/register" `
        -Method POST -ContentType "application/json" `
        -Body (@{email=$emailB; password=$password; username="TestUserB"} | ConvertTo-Json)
    Test-Result "User B registered" ($null -ne $registerB.email)
    Write-Host "  User B Email: $($registerB.email)" -ForegroundColor Gray
    
    # Login User B
    $loginDataB = @{username=$emailB; password=$password}
    $loginB = Invoke-RestMethod "$API/api/auth/token" `
        -Method POST -ContentType "application/x-www-form-urlencoded" `
        -Body $loginDataB
    $tokenB = $loginB.access_token
    Test-Result "User B logged in" ($null -ne $tokenB)
    Write-Host "  User B Token: $($tokenB.Substring(0,20))..." -ForegroundColor Gray
} catch {
    Test-Result "User B authentication" $false
    Write-Host "  Error: $_" -ForegroundColor Red
}

Write-Host "`n========== 3. ESP32 Device Connection ==========" -ForegroundColor Cyan

# Generate Device UID
$deviceUID = "ESP32_TEST_$timestamp"
Write-Host "  Device UID: $deviceUID" -ForegroundColor Gray

# Register Device
try {
    $deviceReg = Invoke-RestMethod "$API/api/devices/register?device_uid=$deviceUID" `
        -Method POST -ContentType "application/json" `
        -Body "{}"
    Test-Result "Device registered" ($null -ne $deviceReg.id)
    Write-Host "  Device ID: $($deviceReg.id)" -ForegroundColor Gray
} catch {
    Test-Result "Device registered" $false
    Write-Host "  Error: $_" -ForegroundColor Red
}

# Upload Pressure Data
try {
    $pressure = Invoke-RestMethod "$API/api/devices/pressure?device_uid=$deviceUID&pressure=75" `
        -Method POST -ContentType "application/json" `
        -Body "{}"
    Test-Result "Pressure data uploaded" ($null -ne $pressure)
    Write-Host "  Pressure Value: $($pressure.pressure_value)" -ForegroundColor Gray
} catch {
    Test-Result "Pressure data uploaded" $false
    Write-Host "  Error: $_" -ForegroundColor Red
}

# Bind Device to User A
try {
    $binding = Invoke-RestMethod "$API/api/devices/bind?device_uid=$deviceUID&name=TestDevice" `
        -Method POST -Headers @{Authorization="Bearer $tokenA"} `
        -ContentType "application/json" `
        -Body "{}"
    Test-Result "User A bound device" ($null -ne $binding)
} catch {
    Test-Result "User A bound device" $false
    Write-Host "  Error: $_" -ForegroundColor Red
}

Write-Host "`n========== 4. Random Pairing ==========" -ForegroundColor Cyan

# User A joins queue
try {
    $queueA = Invoke-RestMethod "$API/api/pairing/random-match" `
        -Method POST -Headers @{Authorization="Bearer $tokenA"} `
        -ContentType "application/json" `
        -Body "{}"
    Test-Result "User A joined queue" ($queueA.status -eq "waiting" -or $queueA.status -eq "matched")
    Write-Host "  Status: $($queueA.status)" -ForegroundColor Gray
} catch {
    Test-Result "User A joined queue" $false
    Write-Host "  Error: $_" -ForegroundColor Red
}

# User B joins queue
try {
    $queueB = Invoke-RestMethod "$API/api/pairing/random-match" `
        -Method POST -Headers @{Authorization="Bearer $tokenB"} `
        -ContentType "application/json" `
        -Body "{}"
    Test-Result "User B joined queue" ($queueB.status -eq "matched")
    Test-Result "Match successful" ($null -ne $queueB.chat_room_id)
    $chatRoomId = $queueB.chat_room_id
    Write-Host "  Chat Room ID: $chatRoomId" -ForegroundColor Gray
    Write-Host "  Partner: $($queueB.partner_username)" -ForegroundColor Gray
} catch {
    Test-Result "User B joined queue" $false
    Write-Host "  Error: $_" -ForegroundColor Red
}

Write-Host "`n========== 5. Temporary Chat Room (30s expire) ==========" -ForegroundColor Cyan

if ($chatRoomId) {
    Write-Host "  Waiting 30 seconds for chat room to expire..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    
    try {
        $expiry = Invoke-RestMethod "$API/api/pairing/chat-room/$chatRoomId/check-expiry" `
            -Method POST -Headers @{Authorization="Bearer $tokenA"} `
            -ContentType "application/json" `
            -Body "{}"
        Test-Result "Chat room expired" ($expiry.expired -eq $true)
        Test-Result "Friend invitation created" ($expiry.invitation_created -eq $true)
        Write-Host "  Invitation ID: $($expiry.invitation_id)" -ForegroundColor Gray
        $invitationId = $expiry.invitation_id
    } catch {
        Test-Result "Chat room expiry check" $false
        Write-Host "  Error: $_" -ForegroundColor Red
    }
} else {
    Write-Host "  Skipping (no chat room created)" -ForegroundColor Yellow
}

Write-Host "`n========== 6. Friend System ==========" -ForegroundColor Cyan

if ($invitationId) {
    # User B accepts invitation
    try {
        $accept = Invoke-RestMethod "$API/api/pairing/friend-invitations/$invitationId/accept" `
            -Method POST -Headers @{Authorization="Bearer $tokenB"} `
            -ContentType "application/json" `
            -Body "{}"
        Test-Result "User B accepted invitation" ($null -ne $accept.friendship_id)
        Write-Host "  Friendship ID: $($accept.friendship_id)" -ForegroundColor Gray
        Write-Host "  Permanent Chat Room: $($accept.chat_room_id)" -ForegroundColor Gray
    } catch {
        Test-Result "User B accepted invitation" $false
        Write-Host "  Error: $_" -ForegroundColor Red
    }
    
    # Check friendship list
    try {
        $friends = Invoke-RestMethod "$API/api/pairing/friends" `
            -Method GET -Headers @{Authorization="Bearer $tokenA"}
        Test-Result "User A can view friends" ($friends.Count -gt 0)
        Write-Host "  Friend Count: $($friends.Count)" -ForegroundColor Gray
    } catch {
        Test-Result "User A can view friends" $false
        Write-Host "  Error: $_" -ForegroundColor Red
    }
} else {
    Write-Host "  Skipping (no invitation created)" -ForegroundColor Yellow
}

Write-Host "`n========== 7. Friend Device Status ==========" -ForegroundColor Cyan

try {
    $devices = Invoke-RestMethod "$API/api/devices/friends/devices" `
        -Method GET -Headers @{Authorization="Bearer $tokenB"}
    Test-Result "User B can view friend devices" ($null -ne $devices)
    if ($devices.Count -gt 0) {
        Write-Host "  Friend Devices Count: $($devices.Count)" -ForegroundColor Gray
        foreach ($dev in $devices) {
            Write-Host "    - $($dev.name): Online=$($dev.is_online)" -ForegroundColor Gray
        }
    }
} catch {
    Test-Result "User B can view friend devices" $false
    Write-Host "  Error: $_" -ForegroundColor Red
}

Write-Host "`n========== Test Summary ==========" -ForegroundColor Cyan
Write-Host "Total Tests: $($testPassed + $testFailed)" -ForegroundColor White
Write-Host "Passed: $testPassed" -ForegroundColor Green
Write-Host "Failed: $testFailed" -ForegroundColor Red
$successRate = [math]::Round(($testPassed / ($testPassed + $testFailed)) * 100, 2)
Write-Host "Success Rate: $successRate%" -ForegroundColor $(if($successRate -ge 80){"Green"}else{"Red"})

Write-Host "`nTest Users Created:" -ForegroundColor Cyan
Write-Host "  User A: $emailA / $password" -ForegroundColor Gray
Write-Host "  User B: $emailB / $password" -ForegroundColor Gray
Write-Host "  Device UID: $deviceUID" -ForegroundColor Gray
