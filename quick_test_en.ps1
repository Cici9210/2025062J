# Quick System Test - English Version
$ErrorActionPreference = "Continue"

Write-Host "`n========== Heartbeat System Test ==========" -ForegroundColor Cyan

$pass = 0
$fail = 0

# 1. Service Check
Write-Host "`n[1] Checking Services..." -ForegroundColor Yellow
try {
    $r1 = Invoke-WebRequest "http://localhost:8000/docs" -TimeoutSec 3
    $r2 = Invoke-WebRequest "http://localhost:8080" -TimeoutSec 3
    Write-Host "    Backend & Frontend: PASS" -ForegroundColor Green
    $pass++
} catch {
    Write-Host "    Services: FAIL" -ForegroundColor Red
    $fail++
}

# 2. User Auth
Write-Host "`n[2] Testing User Authentication..." -ForegroundColor Yellow
try {
    $ts = Get-Date -Format "HHmmss"
    $email = "test_${ts}@test.com"
    
    $reg = Invoke-RestMethod "http://localhost:8000/api/auth/register" `
        -Method POST -ContentType "application/json" `
        -Body "{`"email`":`"$email`",`"password`":`"test123`",`"username`":`"Test`"}"
    
    $login = Invoke-RestMethod "http://localhost:8000/api/auth/token" `
        -Method POST -ContentType "application/x-www-form-urlencoded" `
        -Body "username=$email&password=test123"
    
    Write-Host "    User Auth: PASS - Token: $($login.access_token.Substring(0,20))..." -ForegroundColor Green
    $token = $login.access_token
    $pass++
} catch {
    Write-Host "    User Auth: FAIL - $_" -ForegroundColor Red
    $fail++
}

# 3. ESP32 Device
Write-Host "`n[3] Testing ESP32 Device..." -ForegroundColor Yellow
try {
    $uid = "ESP32_$ts"
    
    $d1 = Invoke-RestMethod "http://localhost:8000/api/devices/register?device_uid=$uid" -Method POST -Body "{}"
    $d2 = Invoke-RestMethod "http://localhost:8000/api/devices/pressure?device_uid=$uid&pressure=75" -Method POST -Body "{}"
    $d3 = Invoke-RestMethod "http://localhost:8000/api/devices/bind?device_uid=$uid&name=TestDev" `
        -Method POST -Headers @{Authorization="Bearer $token"} -Body "{}"
    
    Write-Host "    ESP32: PASS - Device ID: $($d1.id), Pressure: $($d2.pressure_value)" -ForegroundColor Green
    $pass++
} catch {
    Write-Host "    ESP32: FAIL - $_" -ForegroundColor Red
    $fail++
}

# 4. Random Pairing
Write-Host "`n[4] Testing Random Pairing..." -ForegroundColor Yellow
try {
    $email2 = "test_${ts}_b@test.com"
    $reg2 = Invoke-RestMethod "http://localhost:8000/api/auth/register" `
        -Method POST -ContentType "application/json" `
        -Body "{`"email`":`"$email2`",`"password`":`"test123`",`"username`":`"Test2`"}"
    
    $login2 = Invoke-RestMethod "http://localhost:8000/api/auth/token" `
        -Method POST -ContentType "application/x-www-form-urlencoded" `
        -Body "username=$email2&password=test123"
    $token2 = $login2.access_token
    
    $p1 = Invoke-RestMethod "http://localhost:8000/api/pairing/random-match" `
        -Method POST -Headers @{Authorization="Bearer $token"} -Body "{}"
    
    $p2 = Invoke-RestMethod "http://localhost:8000/api/pairing/random-match" `
        -Method POST -Headers @{Authorization="Bearer $token2"} -Body "{}"
    
    if ($p2.chat_room_id) {
        Write-Host "    Pairing: PASS - Chat Room: $($p2.chat_room_id)" -ForegroundColor Green
        $chatId = $p2.chat_room_id
        $pass++
    } else {
        Write-Host "    Pairing: FAIL" -ForegroundColor Red
        $fail++
    }
} catch {
    Write-Host "    Pairing: FAIL - $_" -ForegroundColor Red
    $fail++
}

# 5. Temp Chat Room (30s)
Write-Host "`n[5] Testing Temp Chat Room (waiting 35s)..." -ForegroundColor Yellow
if ($chatId) {
    Start-Sleep -Seconds 35
    
    try {
        $exp = Invoke-RestMethod "http://localhost:8000/api/pairing/chat-room/$chatId/check-expiry" `
            -Method POST -Headers @{Authorization="Bearer $token"} -Body "{}"
        
        if ($exp.expired -and $exp.invitation_id) {
            Write-Host "    Temp Chat: PASS - Invitation: $($exp.invitation_id)" -ForegroundColor Green
            $invId = $exp.invitation_id
            $pass++
        } else {
            Write-Host "    Temp Chat: FAIL - Not expired" -ForegroundColor Red
            $fail++
        }
    } catch {
        Write-Host "    Temp Chat: FAIL - $_" -ForegroundColor Red
        $fail++
    }
} else {
    Write-Host "    Temp Chat: SKIP" -ForegroundColor Gray
}

# 6. Friend System
Write-Host "`n[6] Testing Friend System..." -ForegroundColor Yellow
if ($invId) {
    try {
        # User 2 accepts invitation
        $acc2 = Invoke-RestMethod "http://localhost:8000/api/pairing/invitations/$invId/respond" `
            -Method POST -Headers @{Authorization="Bearer $token2"} `
            -ContentType "application/json" `
            -Body '{"response":"accept"}'
        
        # User 1 also accepts invitation
        $acc1 = Invoke-RestMethod "http://localhost:8000/api/pairing/invitations/$invId/respond" `
            -Method POST -Headers @{Authorization="Bearer $token"} `
            -ContentType "application/json" `
            -Body '{"response":"accept"}'
        
        $friends = Invoke-RestMethod "http://localhost:8000/api/pairing/friends" `
            -Method GET -Headers @{Authorization="Bearer $token"}
        
        if ($acc1.became_friends -and $acc1.friendship_id -and $friends.Count -gt 0) {
            Write-Host "    Friends: PASS - Friendship: $($acc1.friendship_id)" -ForegroundColor Green
            $pass++
        } else {
            Write-Host "    Friends: FAIL - became_friends=$($acc1.became_friends)" -ForegroundColor Red
            $fail++
        }
    } catch {
        Write-Host "    Friends: FAIL - $_" -ForegroundColor Red
        $fail++
    }
} else {
    Write-Host "    Friends: SKIP" -ForegroundColor Gray
}

# 7. Friend Devices
Write-Host "`n[7] Testing Friend Device Status..." -ForegroundColor Yellow
try {
    $devs = Invoke-RestMethod "http://localhost:8000/api/devices/friends/devices" `
        -Method GET -Headers @{Authorization="Bearer $token2"}
    
    Write-Host "    Friend Devices: PASS - Found $($devs.Count) devices" -ForegroundColor Green
    $pass++
} catch {
    Write-Host "    Friend Devices: FAIL - $_" -ForegroundColor Red
    $fail++
}

# Summary
Write-Host "`n========== Summary ==========" -ForegroundColor Cyan
$total = $pass + $fail
$rate = if ($total -gt 0) { [math]::Round(($pass / $total) * 100, 1) } else { 0 }
Write-Host "Total: $total | Pass: $pass | Fail: $fail | Rate: $rate%" -ForegroundColor White

if ($fail -eq 0) {
    Write-Host "`nALL TESTS PASSED!" -ForegroundColor Green
} elseif ($rate -ge 80) {
    Write-Host "`nMost features working!" -ForegroundColor Yellow
} else {
    Write-Host "`nSome issues need fixing" -ForegroundColor Red
}
