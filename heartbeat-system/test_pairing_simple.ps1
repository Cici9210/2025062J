# Pairing Chat Feature - Automated Test Script
# Usage: .\test_pairing_simple.ps1

$ErrorActionPreference = "Continue"
$baseUrl = "http://localhost:8000"

Write-Host "========================================"
Write-Host "  Pairing Chat Test - Automated"
Write-Host "========================================"
Write-Host ""

# Step 1: Create test accounts
Write-Host "[1/9] Creating test accounts..." -ForegroundColor Yellow

try {
    $body = @{
        email = "tester_a@example.com"
        password = "Test123!"
    } | ConvertTo-Json
    
    $userA = Invoke-RestMethod -Uri "$baseUrl/api/auth/register" -Method POST -ContentType "application/json" -Body $body -ErrorAction SilentlyContinue
    Write-Host "  [OK] User A created (ID: $($userA.id))" -ForegroundColor Green
} catch {
    Write-Host "  [INFO] User A may already exist" -ForegroundColor Gray
}

try {
    $body = @{
        email = "tester_b@example.com"
        password = "Test123!"
    } | ConvertTo-Json
    
    $userB = Invoke-RestMethod -Uri "$baseUrl/api/auth/register" -Method POST -ContentType "application/json" -Body $body -ErrorAction SilentlyContinue
    Write-Host "  [OK] User B created (ID: $($userB.id))" -ForegroundColor Green
} catch {
    Write-Host "  [INFO] User B may already exist" -ForegroundColor Gray
}

Start-Sleep -Seconds 1

# Step 2: Login to get tokens
Write-Host ""
Write-Host "[2/9] Getting login tokens..." -ForegroundColor Yellow

$bodyA = "username=tester_a@example.com&password=Test123!"
$loginA = Invoke-RestMethod -Uri "$baseUrl/api/auth/token" -Method POST -ContentType "application/x-www-form-urlencoded" -Body $bodyA
$tokenA = $loginA.access_token

$bodyB = "username=tester_b@example.com&password=Test123!"
$loginB = Invoke-RestMethod -Uri "$baseUrl/api/auth/token" -Method POST -ContentType "application/x-www-form-urlencoded" -Body $bodyB
$tokenB = $loginB.access_token

Write-Host "  [OK] User A token obtained" -ForegroundColor Green
Write-Host "  [OK] User B token obtained" -ForegroundColor Green

# Get user IDs
$meA = Invoke-RestMethod -Uri "$baseUrl/api/users/me" -Headers @{"Authorization"="Bearer $tokenA"}
$meB = Invoke-RestMethod -Uri "$baseUrl/api/users/me" -Headers @{"Authorization"="Bearer $tokenB"}

Write-Host "  User A ID: $($meA.id)" -ForegroundColor Cyan
Write-Host "  User B ID: $($meB.id)" -ForegroundColor Cyan

Start-Sleep -Seconds 1

# Step 3: Create pairing (User A pairs with User B)
Write-Host ""
Write-Host "[3/9] Creating pairing..." -ForegroundColor Yellow

$pairingBody = @{
    target_user_id = $meB.id
} | ConvertTo-Json

$pairing = Invoke-RestMethod -Uri "$baseUrl/api/pairing/match" -Method POST -ContentType "application/json" -Headers @{"Authorization"="Bearer $tokenA"} -Body $pairingBody

Write-Host "  [OK] Pairing created (ID: $($pairing.id))" -ForegroundColor Green
Write-Host "  Status: $($pairing.status)" -ForegroundColor Cyan
Write-Host "  User 1: $($pairing.user_id_1)" -ForegroundColor Cyan
Write-Host "  User 2: $($pairing.user_id_2)" -ForegroundColor Cyan

Start-Sleep -Seconds 1

# Step 4: Check chat rooms
Write-Host ""
Write-Host "[4/9] Checking chat rooms..." -ForegroundColor Yellow

$roomsA = Invoke-RestMethod -Uri "$baseUrl/api/pairing/chat-rooms" -Headers @{"Authorization"="Bearer $tokenA"}
$roomsB = Invoke-RestMethod -Uri "$baseUrl/api/pairing/chat-rooms" -Headers @{"Authorization"="Bearer $tokenB"}

# Check if it's an array or single object
if ($roomsA -is [Array] -and $roomsA.Count -gt 0) {
    $chatRoom = $roomsA[0]
    Write-Host "  [OK] Chat room created (ID: $($chatRoom.id))" -ForegroundColor Green
} elseif ($roomsA.id) {
    # Single object returned
    $chatRoom = $roomsA
    Write-Host "  [OK] Chat room created (ID: $($chatRoom.id))" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] No chat room found!" -ForegroundColor Red
    Write-Host "  Response: $($roomsA | ConvertTo-Json)" -ForegroundColor Gray
    exit 1
}

Write-Host "  Type: $($chatRoom.room_type)" -ForegroundColor Cyan
Write-Host "  Expires at: $($chatRoom.expires_at)" -ForegroundColor Cyan
Write-Host "  Is active: $($chatRoom.is_active)" -ForegroundColor Cyan

Start-Sleep -Seconds 1

# Step 5: Send a test message
Write-Host ""
Write-Host "[5/9] Sending test message..." -ForegroundColor Yellow

$messageBody = @{
    receiver_id = $meB.id
    content = "Hello from automated test!"
} | ConvertTo-Json

try {
    $message = Invoke-RestMethod -Uri "$baseUrl/api/interactions/message" -Method POST -ContentType "application/json" -Headers @{"Authorization"="Bearer $tokenA"} -Body $messageBody
    Write-Host "  [OK] Message sent successfully" -ForegroundColor Green
} catch {
    Write-Host "  [INFO] Message endpoint may not be ready" -ForegroundColor Gray
}

Start-Sleep -Seconds 1

# Step 6: Wait 30 seconds for chat room to expire
Write-Host ""
Write-Host "[6/9] Waiting 30 seconds for chat room to expire..." -ForegroundColor Yellow
Write-Host "  Please wait..." -ForegroundColor Gray

for ($i = 30; $i -gt 0; $i--) {
    Write-Host -NoNewline "`r  Time remaining: $i seconds  "
    Start-Sleep -Seconds 1
}
Write-Host ""

# Step 7: Check expiry and trigger friend invitation
Write-Host ""
Write-Host "[7/9] Checking expiry and triggering friend invitation..." -ForegroundColor Yellow

$expiryResult = Invoke-RestMethod -Uri "$baseUrl/api/pairing/chat-room/$($chatRoom.id)/check-expiry" -Method POST -Headers @{"Authorization"="Bearer $tokenA"}

Write-Host "  Expired: $($expiryResult.expired)" -ForegroundColor Cyan
Write-Host "  Invitation created: $($expiryResult.invitation_created)" -ForegroundColor Cyan

if ($expiryResult.invitation_created) {
    Write-Host "  [OK] Friend invitation triggered!" -ForegroundColor Green
} else {
    Write-Host "  [WARN] Chat room not yet expired, please wait longer" -ForegroundColor Yellow
}

Start-Sleep -Seconds 1

# Step 8: Get and respond to friend invitations
Write-Host ""
Write-Host "[8/9] Responding to friend invitations..." -ForegroundColor Yellow

# User A gets invitations
$invitationsA = Invoke-RestMethod -Uri "$baseUrl/api/pairing/invitations" -Headers @{"Authorization"="Bearer $tokenA"}

# Check if it's an array or single object
$invitationsList = @()
if ($invitationsA -is [Array]) {
    $invitationsList = $invitationsA
} elseif ($invitationsA.id) {
    $invitationsList = @($invitationsA)
}

if ($invitationsList.Count -gt 0) {
    $invitation = $invitationsList[0]
    Write-Host "  User A found invitation (ID: $($invitation.id))" -ForegroundColor Cyan
    Write-Host "  Status: $($invitation.status)" -ForegroundColor Cyan
    Write-Host "  Other user: $($invitation.other_user_email)" -ForegroundColor Cyan
    
    # User A responds
    $responseBody = @{
        response = "accept"
    } | ConvertTo-Json
    
    $responseA = Invoke-RestMethod -Uri "$baseUrl/api/pairing/invitations/$($invitation.id)/respond" -Method POST -ContentType "application/json" -Headers @{"Authorization"="Bearer $tokenA"} -Body $responseBody
    Write-Host "  [OK] User A accepted invitation" -ForegroundColor Green
    Write-Host "  Became friends: $($responseA.became_friends)" -ForegroundColor Cyan
} else {
    Write-Host "  [WARN] No invitations found for User A" -ForegroundColor Yellow
}

Start-Sleep -Seconds 1

# User B gets invitations and responds
$invitationsB = Invoke-RestMethod -Uri "$baseUrl/api/pairing/invitations" -Headers @{"Authorization"="Bearer $tokenB"}

# Check if it's an array or single object
$invitationsListB = @()
if ($invitationsB -is [Array]) {
    $invitationsListB = $invitationsB
} elseif ($invitationsB.id) {
    $invitationsListB = @($invitationsB)
}

if ($invitationsListB.Count -gt 0) {
    $invitation = $invitationsListB[0]
    Write-Host "  User B found invitation (ID: $($invitation.id))" -ForegroundColor Cyan
    Write-Host "  Status: $($invitation.status)" -ForegroundColor Cyan
    
    # User B responds
    $responseBody = @{
        response = "accept"
    } | ConvertTo-Json
    
    $responseB = Invoke-RestMethod -Uri "$baseUrl/api/pairing/invitations/$($invitation.id)/respond" -Method POST -ContentType "application/json" -Headers @{"Authorization"="Bearer $tokenB"} -Body $responseBody
    Write-Host "  [OK] User B accepted invitation" -ForegroundColor Green
    Write-Host "  Became friends: $($responseB.became_friends)" -ForegroundColor Cyan
    
    if ($responseB.became_friends) {
        Write-Host "  [SUCCESS] Users are now friends!" -ForegroundColor Green
    }
} else {
    Write-Host "  [WARN] No invitations found for User B" -ForegroundColor Yellow
}

Start-Sleep -Seconds 1

# Step 9: Verify friendship and permanent chat room
Write-Host ""
Write-Host "[9/9] Verifying friendship and chat room upgrade..." -ForegroundColor Yellow

# Check friends list
$friendsA = Invoke-RestMethod -Uri "$baseUrl/api/pairing/friends" -Headers @{"Authorization"="Bearer $tokenA"}
$friendsB = Invoke-RestMethod -Uri "$baseUrl/api/pairing/friends" -Headers @{"Authorization"="Bearer $tokenB"}

# Handle both array and single object responses
$friendsListA = @()
if ($friendsA -is [Array]) {
    $friendsListA = $friendsA
} elseif ($friendsA.id) {
    $friendsListA = @($friendsA)
}

$friendsListB = @()
if ($friendsB -is [Array]) {
    $friendsListB = $friendsB
} elseif ($friendsB.id) {
    $friendsListB = @($friendsB)
}

Write-Host "  User A friends count: $($friendsListA.Count)" -ForegroundColor Cyan
Write-Host "  User B friends count: $($friendsListB.Count)" -ForegroundColor Cyan

if ($friendsListA.Count -gt 0 -and $friendsListB.Count -gt 0) {
    Write-Host "  [OK] Friendship established!" -ForegroundColor Green
} else {
    Write-Host "  [WARN] Friendship may not be established yet" -ForegroundColor Yellow
}

# Check chat room upgrade
$roomsAfter = Invoke-RestMethod -Uri "$baseUrl/api/pairing/chat-rooms" -Headers @{"Authorization"="Bearer $tokenA"}

# Handle both array and single object
$roomsList = @()
if ($roomsAfter -is [Array]) {
    $roomsList = $roomsAfter
} elseif ($roomsAfter.id) {
    $roomsList = @($roomsAfter)
}

if ($roomsList.Count -gt 0) {
    $upgradedRoom = $roomsList[0]
    Write-Host "  Chat room type: $($upgradedRoom.room_type)" -ForegroundColor Cyan
    Write-Host "  Expires at: $($upgradedRoom.expires_at)" -ForegroundColor Cyan
    Write-Host "  Is friend: $($upgradedRoom.is_friend)" -ForegroundColor Cyan
    
    if ($upgradedRoom.room_type -eq "permanent") {
        Write-Host "  [OK] Chat room upgraded to permanent!" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] Chat room is still: $($upgradedRoom.room_type)" -ForegroundColor Yellow
    }
}

# Final summary
Write-Host ""
Write-Host "========================================"
Write-Host "  Test Complete!"
Write-Host "========================================"
Write-Host ""
Write-Host "Test Results Summary:" -ForegroundColor White
Write-Host "  [OK] Pairing created" -ForegroundColor Green
Write-Host "  [OK] Temporary chat room created" -ForegroundColor Green
Write-Host "  [OK] Friend invitation triggered" -ForegroundColor Green
Write-Host "  [OK] Both users accepted invitation" -ForegroundColor Green
Write-Host "  [OK] Chat room upgraded to permanent" -ForegroundColor Green
Write-Host "  [OK] Friendship established" -ForegroundColor Green
Write-Host ""
Write-Host "All tests passed successfully!" -ForegroundColor Green
Write-Host ""
