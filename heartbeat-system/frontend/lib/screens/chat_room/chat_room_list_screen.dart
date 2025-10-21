import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../services/pairing_service.dart';
import '../../providers/auth_provider.dart';
import '../message/message_detail_screen.dart';
import '../../widgets/invitation_notification_dialog.dart';

class ChatRoomListScreen extends StatefulWidget {
  const ChatRoomListScreen({Key? key}) : super(key: key);

  @override
  State<ChatRoomListScreen> createState() => _ChatRoomListScreenState();
}

class _ChatRoomListScreenState extends State<ChatRoomListScreen> {
  final PairingService _pairingService = PairingService();
  
  List<Map<String, dynamic>> _chatRooms = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _expiryCheckTimer;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
    _startExpiryCheckTimer();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _expiryCheckTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startExpiryCheckTimer() {
    // 每 30 秒檢查一次過期
    _expiryCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkExpiredRooms(),
    );
  }

  void _startCountdownTimer() {
    // 每秒更新倒數計時
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) {
          setState(() {
            // 觸發重繪以更新倒數計時
          });
        }
      },
    );
  }

  Future<void> _loadChatRooms() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = authProvider.token;
      if (token == null) {
        throw Exception('未登入');
      }

      final rooms = await _pairingService.getChatRooms(token);
      
      setState(() {
        _chatRooms = rooms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '載入失敗: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkExpiredRooms() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      final token = authProvider.token;
      if (token == null) return;

      for (var room in _chatRooms) {
        if (room['room_type'] == 'temporary' && room['is_active'] == true) {
          final result = await _pairingService.checkChatRoomExpiry(
            token,
            room['id'],
          );

          if (result['expired'] == true && result['invitation_created'] == true) {
            // 聊天室過期並創建了邀請,顯示通知
            if (mounted) {
              _showInvitationNotification(
                room['other_user_email'],
                result['invitation_id'],
              );
            }
            // 重新載入聊天室列表
            _loadChatRooms();
            break;
          }
        }
      }
    } catch (e) {
      print('檢查過期失敗: $e');
    }
  }

  void _showInvitationNotification(String otherUserEmail, int invitationId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => InvitationNotificationDialog(
        otherUserEmail: otherUserEmail,
        invitationId: invitationId,
        onResponse: () {
          _loadChatRooms();
        },
      ),
    );
  }

  String _formatRemainingTime(String? expiresAt) {
    if (expiresAt == null) return '';
    
    try {
      final expires = DateTime.parse(expiresAt);
      final now = DateTime.now();
      final remaining = expires.difference(now);
      
      if (remaining.isNegative) return '已過期';
      
      final minutes = remaining.inMinutes;
      final seconds = remaining.inSeconds % 60;
      return '⏱ $minutes:${seconds.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  Color _getRoomColor(String roomType) {
    return roomType == 'temporary' 
        ? Colors.blue 
        : Colors.purple;
  }

  IconData _getRoomIcon(String roomType) {
    return roomType == 'temporary'
        ? Icons.timer
        : Icons.favorite;
  }

  void _enterChatRoom(Map<String, dynamic> room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageDetailScreen(
          userId: room['other_user_id'],
          userName: room['other_user_email'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('聊天室'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF6B9D), Color(0xFFC06C84)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChatRooms,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadChatRooms,
              child: const Text('重試'),
            ),
          ],
        ),
      );
    }

    if (_chatRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '還沒有聊天室',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '開始配對來創建聊天室吧!',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChatRooms,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _chatRooms.length,
        itemBuilder: (context, index) {
          final room = _chatRooms[index];
          return _buildChatRoomCard(room);
        },
      ),
    );
  }

  Widget _buildChatRoomCard(Map<String, dynamic> room) {
    final roomType = room['room_type'] as String;
    final isTemporary = roomType == 'temporary';
    final isActive = room['is_active'] as bool;
    final otherUserEmail = room['other_user_email'] as String;
    final isFriend = room['is_friend'] as bool? ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: isActive ? () => _enterChatRoom(room) : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 頭像
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: _getRoomColor(roomType).withOpacity(0.2),
                    child: Icon(
                      _getRoomIcon(roomType),
                      color: _getRoomColor(roomType),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // 用戶資訊
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                otherUserEmail,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isFriend) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.verified,
                                size: 18,
                                color: Colors.green,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // 房間類型標籤
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getRoomColor(roomType).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isTemporary ? '臨時' : '永久',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getRoomColor(roomType),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            
                            // 倒數計時 (僅臨時聊天室)
                            if (isTemporary && isActive) ...[
                              const SizedBox(width: 8),
                              Text(
                                _formatRemainingTime(room['expires_at']),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                            
                            // 已過期標籤
                            if (!isActive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '已過期',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // 箭頭圖標
                  if (isActive)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                ],
              ),
              
              // 提示訊息
              if (isTemporary && isActive) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '時間到後將產生好友邀請',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
