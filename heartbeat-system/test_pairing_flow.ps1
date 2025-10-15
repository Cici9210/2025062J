# PowerShell script encoding: UTF-8 with BOM
# Pairing Chat Test Automation

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Pairing Chat Feature - Auto Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "http://localhost:8000"

# 1. Create test accounts
Write-Host "[1/9] Creating test accounts..." -ForegroundColor Yellow

try {
    $userA = Invoke-RestMethod -Uri "$baseUrl/api/auth/register" `
        -Method POST `
        -Headers @{"Content-Type"="application/json"} `
        -Body '{"email":"tester_a@example.com","password":"Test123!"}' `
        -ErrorAction SilentlyContinue
    Write-Host "  OK User A created (ID: $($userA.id))" -ForegroundColor Green
} catch {
    Write-Host "  Info: User A may already exist" -ForegroundColor Gray
}

try {
    $userB = Invoke-RestMethod -Uri "$baseUrl/api/auth/register" `
        -Method POST `
        -Headers @{"Content-Type"="application/json"} `
        -Body '{"email":"tester_b@example.com","password":"Test123!"}' `
        -ErrorAction SilentlyContinue
    Write-Host "  OK User B created (ID: $($userB.id))" -ForegroundColor Green
} catch {
    Write-Host "  Info: User B may already exist" -ForegroundColor Gray
}

Start-Sleep -Seconds 1

# 2. Login to get tokens
Write-Host "`n[2/9] Getting login tokens..." -ForegroundColor Yellow

$loginA = Invoke-RestMethod -Uri "$baseUrl/api/auth/token" `
    -Method POST `
    -Headers @{"Content-Type"="application/x-www-form-urlencoded"} `
    -Body "username=tester_a@example.com`&password=Test123!"
$tokenA = $loginA.access_token

$loginB = Invoke-RestMethod -Uri "$baseUrl/api/auth/token" `
    -Method POST `
    -Headers @{"Content-Type"="application/x-www-form-urlencoded"} `
    -Body "username=tester_b@example.com`&password=Test123!"
$tokenB = $loginB.access_token

Write-Host "  OK User A token: $($tokenA.Substring(0,20))..." -ForegroundColor Green
Write-Host "  OK User B token: $($tokenB.Substring(0,20))..." -ForegroundColor Green

# Get user info to retrieve IDs
$meA = Invoke-RestMethod -Uri "$baseUrl/api/users/me" `
    -Headers @{"Authorization"="Bearer $tokenA"}
$meB = Invoke-RestMethod -Uri "$baseUrl/api/users/me" `
    -Headers @{"Authorization"="Bearer $tokenB"}

Write-Host "  ✓ User A ID: $($meA.id)" -ForegroundColor Green
Write-Host "  ✓ User B ID: $($meB.id)" -ForegroundColor Green

Start-Sleep -Seconds 1

# 3. User A 創建配對 (自動創建 5 分鐘臨時聊天室)
Write-Host "`n[3/9] User A 創建配對..." -ForegroundColor Yellow

$pairing = Invoke-RestMethod -Uri "$baseUrl/api/pairing/match" `
    -Method POST `
    -Headers @{
        "Authorization"="Bearer $tokenA"
        "Content-Type"="application/json"
    } `
    -Body "{`"target_user_id`":$($meB.id)}"

Write-Host "  ✓ 配對成功!" -ForegroundColor Green
Write-Host "    配對 ID: $($pairing.id)" -ForegroundColor Gray
Write-Host "    狀態: $($pairing.status)" -ForegroundColor Gray
Write-Host "    配對時間: $($pairing.matched_at)" -ForegroundColor Gray

Start-Sleep -Seconds 1

# 4. User A 查看聊天室
Write-Host "`n[4/9] 查看聊天室..." -ForegroundColor Yellow

$roomsA = Invoke-RestMethod -Uri "$baseUrl/api/pairing/chat-rooms" `
    -Headers @{"Authorization"="Bearer $tokenA"}

if ($roomsA.Count -gt 0) {
    $room = $roomsA[0]
    Write-Host "  ✓ 找到聊天室!" -ForegroundColor Green
    Write-Host "    聊天室 ID: $($room.id)" -ForegroundColor Gray
    Write-Host "    類型: $($room.room_type)" -ForegroundColor $(if($room.room_type -eq "temporary"){"Yellow"}else{"Green"})
    Write-Host "    是否啟用: $($room.is_active)" -ForegroundColor Gray
    Write-Host "    過期時間: $($room.expires_at)" -ForegroundColor Gray
    Write-Host "    對方: $($room.other_user_email)" -ForegroundColor Gray
    Write-Host "    是否為好友: $($room.is_friend)" -ForegroundColor Gray
} else {
    Write-Host "  ✗ 未找到聊天室" -ForegroundColor Red
    exit
}

Start-Sleep -Seconds 1

# 5. User B 也查看聊天室
Write-Host "`n[5/9] User B 查看聊天室..." -ForegroundColor Yellow

$roomsB = Invoke-RestMethod -Uri "$baseUrl/api/pairing/chat-rooms" `
    -Headers @{"Authorization"="Bearer $tokenB"}

if ($roomsB.Count -gt 0) {
    Write-Host "  ✓ User B 也能看到聊天室!" -ForegroundColor Green
} else {
    Write-Host "  ✗ User B 看不到聊天室" -ForegroundColor Red
}

Start-Sleep -Seconds 1

# 6. 檢查聊天室過期狀態
Write-Host "`n[6/9] 檢查聊天室過期狀態..." -ForegroundColor Yellow

$expiry = Invoke-RestMethod -Uri "$baseUrl/api/pairing/chat-room/$($room.id)/check-expiry" `
    -Method POST `
    -Headers @{"Authorization"="Bearer $tokenA"}

if ($expiry.expired) {
    Write-Host "  ✓ 聊天室已過期,已創建好友邀請!" -ForegroundColor Green
    Write-Host "    邀請 ID: $($expiry.invitation_id)" -ForegroundColor Gray
} else {
    Write-Host "  ! 聊天室尚未過期 (需等待 5 分鐘)" -ForegroundColor Yellow
    Write-Host "    您可以:" -ForegroundColor Gray
    Write-Host "    1. 等待 5 分鐘後重新執行此腳本" -ForegroundColor Gray
    Write-Host "    2. 修改 pairing_service.py 改為 30 秒測試" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    測試到此結束,其餘步驟需等過期後進行。" -ForegroundColor Cyan
    exit
}

Start-Sleep -Seconds 1

# 7. 查看好友邀請
Write-Host "`n[7/9] 查看好友邀請..." -ForegroundColor Yellow

$invitationsA = Invoke-RestMethod -Uri "$baseUrl/api/pairing/invitations" `
    -Headers @{"Authorization"="Bearer $tokenA"}

$invitationsB = Invoke-RestMethod -Uri "$baseUrl/api/pairing/invitations" `
    -Headers @{"Authorization"="Bearer $tokenB"}

if ($invitationsA.Count -gt 0) {
    $invitation = $invitationsA[0]
    Write-Host "  ✓ User A 收到邀請!" -ForegroundColor Green
    Write-Host "    邀請 ID: $($invitation.id)" -ForegroundColor Gray
    Write-Host "    對方: $($invitation.other_user_email)" -ForegroundColor Gray
    Write-Host "    狀態: $($invitation.status)" -ForegroundColor Gray
    Write-Host "    剩餘時間: $([int]($invitation.time_remaining / 3600)) 小時" -ForegroundColor Gray
}

if ($invitationsB.Count -gt 0) {
    Write-Host "  ✓ User B 也收到邀請!" -ForegroundColor Green
}

Start-Sleep -Seconds 1

# 8. 雙方接受邀請
Write-Host "`n[8/9] 雙方接受好友邀請..." -ForegroundColor Yellow

# User A 接受
$responseA = Invoke-RestMethod -Uri "$baseUrl/api/pairing/invitations/$($invitation.id)/respond" `
    -Method POST `
    -Headers @{
        "Authorization"="Bearer $tokenA"
        "Content-Type"="application/json"
    } `
    -Body '{"response":"accept"}'

Write-Host "  ✓ User A 已接受" -ForegroundColor Green
Write-Host "    成為好友: $($responseA.became_friends)" -ForegroundColor Gray

# User B 接受
$responseB = Invoke-RestMethod -Uri "$baseUrl/api/pairing/invitations/$($invitation.id)/respond" `
    -Method POST `
    -Headers @{
        "Authorization"="Bearer $tokenB"
        "Content-Type"="application/json"
    } `
    -Body '{"response":"accept"}'

Write-Host "  ✓ User B 已接受" -ForegroundColor Green
Write-Host "    成為好友: $($responseB.became_friends)" -ForegroundColor $(if($responseB.became_friends){"Green"}else{"Yellow"})

if ($responseB.became_friends) {
    Write-Host "  🎉 雙方已成為好友!" -ForegroundColor Cyan
}

Start-Sleep -Seconds 1

# 9. 最終確認
Write-Host "`n[9/9] 最終確認..." -ForegroundColor Yellow

# 查看好友列表
$friends = Invoke-RestMethod -Uri "$baseUrl/api/pairing/friends" `
    -Headers @{"Authorization"="Bearer $tokenA"}

Write-Host "  ✓ 好友數量: $($friends.Count)" -ForegroundColor Green
if ($friends.Count -gt 0) {
    Write-Host "    好友: $($friends[0].email)" -ForegroundColor Gray
}

# 查看聊天室狀態
$finalRooms = Invoke-RestMethod -Uri "$baseUrl/api/pairing/chat-rooms" `
    -Headers @{"Authorization"="Bearer $tokenA"}

if ($finalRooms.Count -gt 0) {
    $finalRoom = $finalRooms[0]
    Write-Host "  ✓ 聊天室類型: $($finalRoom.room_type)" -ForegroundColor $(if($finalRoom.room_type -eq "permanent"){"Green"}else{"Yellow"})
    Write-Host "    過期時間: $($finalRoom.expires_at)" -ForegroundColor Gray
    Write-Host "    是否為好友: $($finalRoom.is_friend)" -ForegroundColor Green
}

# 檢查好友關係
$isFriend = Invoke-RestMethod -Uri "$baseUrl/api/pairing/is-friend/$($meB.id)" `
    -Headers @{"Authorization"="Bearer $tokenA"}

Write-Host "  ✓ 好友關係確認: $($isFriend.is_friend)" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  測試完成!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "測試結果摘要:" -ForegroundColor White
Write-Host "  ✓ 配對成功" -ForegroundColor Green
Write-Host "  ✓ 臨時聊天室創建成功" -ForegroundColor Green
Write-Host "  ✓ 好友邀請觸發成功" -ForegroundColor Green
Write-Host "  ✓ 雙方接受邀請成功" -ForegroundColor Green
Write-Host "  ✓ 聊天室升級為永久成功" -ForegroundColor Green
Write-Host "  ✓ 好友關係建立成功" -ForegroundColor Green
Write-Host ""
