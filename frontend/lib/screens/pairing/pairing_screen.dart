import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/pairing_service.dart';
import '../../providers/auth_provider.dart';
import '../message/message_detail_screen.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({Key? key}) : super(key: key);

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final TextEditingController _userIdController = TextEditingController();
  final PairingService _pairingService = PairingService();
  
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _chatRoom;

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _startPairing() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (_userIdController.text.isEmpty) {
      setState(() {
        _errorMessage = '請輸入對方的 User ID';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _chatRoom = null;
    });

    try {
      final token = authProvider.token;
      if (token == null) {
        throw Exception('未登入');
      }

      final targetUserId = int.parse(_userIdController.text);
      
      // 創建配對
      final pairing = await _pairingService.createPairing(token, targetUserId);
      
      // 獲取聊天室資訊
      final chatRooms = await _pairingService.getChatRooms(token);
      final chatRoom = chatRooms.firstWhere(
        (room) => room['other_user_id'] == targetUserId,
        orElse: () => throw Exception('聊天室創建失敗'),
      );

      setState(() {
        _chatRoom = chatRoom;
        _isLoading = false;
      });

      // 顯示成功訊息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 配對成功!已創建 5 分鐘臨時聊天室'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = '配對失敗: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _enterChatRoom() async {
    if (_chatRoom == null) return;

    final otherUserId = _chatRoom!['other_user_id'];
    final otherUserEmail = _chatRoom!['other_user_email'];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageDetailScreen(
          userId: otherUserId,
          userName: otherUserEmail,
        ),
      ),
    );
  }

  String _formatRemainingTime(String? expiresAt) {
    if (expiresAt == null) return '--:--';
    
    try {
      final expires = DateTime.parse(expiresAt);
      final now = DateTime.now();
      final remaining = expires.difference(now);
      
      if (remaining.isNegative) return '已過期';
      
      final minutes = remaining.inMinutes;
      final seconds = remaining.inSeconds % 60;
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    } catch (e) {
      return '--:--';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('開始配對'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF6B9D), Color(0xFFC06C84)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 標題和說明
            const Icon(
              Icons.favorite,
              size: 80,
              color: Color(0xFFFF6B9D),
            ),
            const SizedBox(height: 16),
            const Text(
              '心跳配對',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6B9D),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '輸入對方的 User ID 開始配對\n成功後將創建 5 分鐘臨時聊天室',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),

            // 輸入區域
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '對方的 User ID',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _userIdController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: '例如: 20',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      enabled: !_isLoading && _chatRoom == null,
                    ),
                    const SizedBox(height: 20),

                    // 開始配對按鈕
                    if (_chatRoom == null)
                      ElevatedButton(
                        onPressed: _isLoading ? null : _startPairing,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: const Color(0xFFFF6B9D),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.favorite),
                                  SizedBox(width: 8),
                                  Text(
                                    '開始配對',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                  ],
                ),
              ),
            ),

            // 錯誤訊息
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 配對成功後顯示聊天室資訊
            if (_chatRoom != null) ...[
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B9D), Color(0xFFC06C84)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 64,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '配對成功!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '對方: ${_chatRoom!['other_user_email']}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '臨時聊天室剩餘時間',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatRemainingTime(_chatRoom!['expires_at']),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _enterChatRoom,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFFF6B9D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble),
                            SizedBox(width: 8),
                            Text(
                              '進入聊天室',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '5 分鐘後聊天室過期,將產生好友邀請通知',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 13,
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
    );
  }
}
