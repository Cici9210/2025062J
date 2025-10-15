# 🎯 接下來的開發計畫

## 📊 當前狀態總覽

### ✅ 已完成 (Backend)
- ✅ 配對系統完整實現 (POST /api/pairing/match)
- ✅ 臨時聊天室系統 (5分鐘自動過期)
- ✅ 好友邀請系統 (24小時有效期)
- ✅ 永久聊天室升級機制
- ✅ 好友關係管理 (GET /api/pairing/friends)
- ✅ 在線狀態追蹤
- ✅ 所有 API 端點已測試通過

### ✅ 已完成 (Frontend - 服務層)
- ✅ 創建 `pairing_service.dart` (包含所有配對 API)
- ✅ 更新 `friend_service.dart` (部分遷移到新 API)
- ✅ 基本 UI 框架 (首頁、訊息、好友、統計、個人)

### ⚠️ 待完成 (Frontend - UI 層)
- ❌ 配對功能 UI
- ❌ 聊天室列表 UI
- ❌ 好友邀請通知 UI
- ❌ 前端代碼重新構建
- ❌ 完整測試流程

---

## 🚀 接下來的工作清單

### 階段 1: 修復現有問題 (優先)

#### 1.1 重新構建前端 ⭐ **立即執行**
**目的**: 修復 404 錯誤,讓已更新的服務層生效

**步驟**:
```powershell
# 1. 停止前端服務
Stop-Process -Name python -Force -ErrorAction SilentlyContinue

# 2. 重新構建 Flutter Web
cd c:\Users\user\2J1134\heartbeat-system\frontend
flutter build web

# 3. 重啟前端代理
python proxy.py
```

**預期結果**:
- ✅ 好友列表 API 從 404 改為正常顯示
- ✅ 可以正常查看好友列表 (如果有好友)

---

### 階段 2: 實現配對聊天 UI (核心功能)

#### 2.1 創建配對頁面 ⭐⭐⭐
**文件**: `frontend/lib/screens/pairing/pairing_screen.dart` (新文件)

**功能需求**:
- [ ] 輸入對方 User ID 的輸入框
- [ ] 「開始配對」按鈕
- [ ] 顯示配對狀態 (配對中、成功、失敗)
- [ ] 成功後顯示聊天室資訊
- [ ] 倒數計時器 (顯示剩餘時間)
- [ ] 「進入聊天室」按鈕

**設計參考**:
```
┌─────────────────────────┐
│     💝 開始配對         │
├─────────────────────────┤
│                         │
│  輸入對方的 User ID:    │
│  ┌─────────────────┐   │
│  │ [    20       ] │   │
│  └─────────────────┘   │
│                         │
│  ┌─────────────────┐   │
│  │  🎯 開始配對    │   │
│  └─────────────────┘   │
│                         │
│  或                     │
│                         │
│  ┌─────────────────┐   │
│  │  🎲 隨機配對    │   │
│  └─────────────────┘   │
│                         │
└─────────────────────────┘
```

#### 2.2 創建聊天室列表頁面 ⭐⭐⭐
**文件**: `frontend/lib/screens/chat_room/chat_room_list_screen.dart` (新文件)

**功能需求**:
- [ ] 顯示所有聊天室 (臨時 + 永久)
- [ ] 每個聊天室卡片顯示:
  - 對方頭像和 Email
  - 聊天室類型標籤 (臨時/永久)
  - 倒數計時 (臨時聊天室)
  - 最後一條訊息預覽
  - 在線狀態指示器
- [ ] 點擊進入聊天室
- [ ] 自動檢查過期 (每 30 秒)
- [ ] 過期時顯示邀請通知

**設計參考**:
```
┌─────────────────────────┐
│     💬 聊天室列表       │
├─────────────────────────┤
│ 👤 user2@example.com   │
│    [臨時] ⏱ 3:24       │
│    "你好!" • 2分鐘前   │
├─────────────────────────┤
│ 👤 user3@example.com   │
│    [永久] 🟢 在線      │
│    "晚安~" • 5小時前   │
└─────────────────────────┘
```

#### 2.3 創建好友邀請通知 UI ⭐⭐⭐
**文件**: `frontend/lib/widgets/invitation_notification.dart` (新文件)

**功能需求**:
- [ ] 聊天室過期時彈出通知
- [ ] 顯示對方資訊
- [ ] 「接受」「拒絕」按鈕
- [ ] 倒數計時 (24小時)
- [ ] 接受/拒絕後的反饋

**設計參考**:
```
┌─────────────────────────┐
│  💌 好友邀請            │
├─────────────────────────┤
│  user2@example.com      │
│  想要成為您的好友       │
│                         │
│  有效期: 23:45:12       │
│                         │
│  ┌─────┐   ┌─────┐     │
│  │接受 │   │拒絕 │     │
│  └─────┘   └─────┘     │
└─────────────────────────┘
```

#### 2.4 更新好友列表頁面 ⭐⭐
**文件**: `frontend/lib/screens/friend/friend_list_screen.dart` (已存在)

**需要更新**:
- [ ] 移除舊的「添加好友」按鈕 (改用配對)
- [ ] 添加「開始配對」按鈕 → 跳轉配對頁面
- [ ] 顯示邀請數量徽章
- [ ] 點擊好友進入永久聊天室

---

### 階段 3: 整合和測試

#### 3.1 導航整合 ⭐
**文件**: `frontend/lib/main.dart` 或路由配置

**需要添加**:
- [ ] 配對頁面路由
- [ ] 聊天室列表路由
- [ ] 在底部導航欄添加入口

#### 3.2 WebSocket 整合 ⭐⭐
**目的**: 即時更新邀請通知

**需要實現**:
- [ ] 監聽邀請事件
- [ ] 監聽好友上線/下線
- [ ] 監聽聊天室過期事件

#### 3.3 完整測試流程 ⭐⭐⭐
**測試場景**:
1. [ ] 用戶 A 配對用戶 B
2. [ ] 創建臨時聊天室
3. [ ] 發送訊息
4. [ ] 等待 5 分鐘過期
5. [ ] 接收好友邀請
6. [ ] 雙方接受邀請
7. [ ] 升級為永久聊天室
8. [ ] 永久聊天室可正常使用

---

## 📋 建議的開發順序

### 第一天: 修復和基礎
1. ✅ 重新構建前端 (15 分鐘)
2. ⭐ 創建配對頁面 UI (2-3 小時)
3. ⭐ 測試配對功能 (30 分鐘)

### 第二天: 聊天室
4. ⭐ 創建聊天室列表頁面 (3-4 小時)
5. ⭐ 實現倒數計時器 (1 小時)
6. ⭐ 測試聊天室列表 (30 分鐘)

### 第三天: 邀請和整合
7. ⭐ 創建邀請通知 UI (2-3 小時)
8. ⭐ 整合導航和路由 (1 小時)
9. ⭐ 更新好友列表頁面 (1 小時)

### 第四天: WebSocket 和測試
10. ⭐ WebSocket 整合 (2-3 小時)
11. ⭐ 完整流程測試 (2-3 小時)
12. ⭐ Bug 修復和優化 (2 小時)

---

## 🎨 UI/UX 設計規範

### 顏色方案
- **主色**: 粉紅漸變 (配對/愛心主題)
  - `Color(0xFFFF6B9D)` → `Color(0xFFC06C84)`
- **成功**: 綠色 `Colors.green`
- **警告**: 橙色 `Colors.orange`
- **危險**: 紅色 `Colors.red`
- **臨時**: 藍色 `Colors.blue`
- **永久**: 紫色 `Colors.purple`

### 圖標規範
- 配對: 💝 `Icons.favorite` 或 `Icons.people`
- 臨時聊天室: ⏱ `Icons.timer`
- 永久聊天室: 💬 `Icons.chat_bubble`
- 邀請: 💌 `Icons.mail`
- 在線: 🟢 `Icons.circle` (綠色)
- 離線: ⚪ `Icons.circle_outlined` (灰色)

### 動畫效果
- [ ] 配對成功的慶祝動畫
- [ ] 倒數計時的脈動效果
- [ ] 邀請通知的滑入動畫
- [ ] 按鈕點擊的波紋效果

---

## 🔧 技術要點

### 定時任務
```dart
// 每 30 秒檢查聊天室過期
Timer.periodic(Duration(seconds: 30), (timer) {
  _checkChatRoomExpiry();
});
```

### 倒數計時
```dart
// 顯示剩餘時間
String formatRemainingTime(DateTime expiresAt) {
  final remaining = expiresAt.difference(DateTime.now());
  final minutes = remaining.inMinutes;
  final seconds = remaining.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
```

### 狀態管理
```dart
// 使用 Provider 管理邀請狀態
class InvitationProvider extends ChangeNotifier {
  List<Invitation> _invitations = [];
  
  void addInvitation(Invitation inv) {
    _invitations.add(inv);
    notifyListeners();
  }
}
```

---

## 📝 現在開始?

### 立即執行: 重新構建前端
```powershell
cd c:\Users\user\2J1134\heartbeat-system\frontend
flutter build web
```

### 接下來我可以幫你:
1. **創建配對頁面** - 輸入 User ID 開始配對
2. **創建聊天室列表** - 顯示所有聊天室
3. **創建邀請通知** - 彈出邀請提示
4. **整合導航** - 添加到主應用

**你想從哪個開始?** 🚀

---

**建議**: 先重新構建前端,確認好友列表 404 問題解決後,再開始實現配對 UI。
