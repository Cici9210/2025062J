import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/pairing_service.dart';
import '../../providers/auth_provider.dart';
import '../message/message_detail_screen.dart';

class RandomPairingScreen extends StatefulWidget {
  const RandomPairingScreen({Key? key}) : super(key: key);

  @override
  State<RandomPairingScreen> createState() => _RandomPairingScreenState();
}

class _RandomPairingScreenState extends State<RandomPairingScreen> {
  final PairingService _pairingService = PairingService();
  
  bool _isSearching = false;
  bool _isMatched = false;
  String _status = '';
  Map<String, dynamic>? _matchResult;
  
  @override
  void dispose() {
    // 離開頁面時自動離開隊列
    if (_isSearching && !_isMatched) {
      _leaveQueue();
    }
    super.dispose();
  }

  Future<void> _startRandomMatch() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    
    if (token == null) {
      _showError('請先登入');
      return;
    }

    setState(() {
      _isSearching = true;
      _isMatched = false;
      _status = '正在尋找配對對象...';
      _matchResult = null;
    });

    try {
      final result = await _pairingService.randomMatch(token);
      
      setState(() {
        if (result['status'] == 'matched') {
          _isMatched = true;
          _status = '配對成功！';
          _matchResult = result;
        } else if (result['status'] == 'waiting') {
          _status = '等待中...請稍候，正在尋找其他用戶';
        }
      });

      // 如果配對成功，顯示成功訊息
      if (_isMatched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 配對成功！已創建 30 秒臨時聊天室'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
        _status = '配對失敗';
      });
      _showError('配對失敗: ${e.toString()}');
    }
  }

  Future<void> _leaveQueue() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    
    if (token == null) return;

    try {
      await _pairingService.leaveQueue(token);
      setState(() {
        _isSearching = false;
        _status = '已取消配對';
      });
    } catch (e) {
      _showError('離開隊列失敗: ${e.toString()}');
    }
  }

  void _enterChatRoom() {
    if (_matchResult == null) return;

    final chatRoomId = _matchResult!['chat_room_id'];
    final partnerId = _matchResult!['partner_id'];
    final partnerName = _matchResult!['partner_username'] ?? '配對用戶';
    final expiresAt = _matchResult!['expires_at'];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageDetailScreen(
          userId: partnerId,
          userName: partnerName,
          chatRoomId: chatRoomId,
          expiresAt: expiresAt,
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('隨機配對'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 配對圖示
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _isMatched 
                      ? Colors.green.shade100 
                      : _isSearching 
                          ? Colors.blue.shade100 
                          : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isMatched 
                      ? Icons.favorite 
                      : _isSearching 
                          ? Icons.search 
                          : Icons.people,
                  size: 60,
                  color: _isMatched 
                      ? Colors.green 
                      : _isSearching 
                          ? Colors.blue 
                          : Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              // 狀態文字
              Text(
                _status.isEmpty ? '點擊下方按鈕開始隨機配對' : _status,
                style: TextStyle(
                  fontSize: 18,
                  color: _isMatched ? Colors.green : Colors.black87,
                  fontWeight: _isMatched ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // 配對成功後顯示對象信息
              if (_isMatched && _matchResult != null) ...[
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, color: Colors.blue),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '配對對象: ${_matchResult!['partner_username'] ?? '未知用戶'}',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.timer, color: Colors.orange),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '聊天室將在 30 秒後過期',
                                style: TextStyle(fontSize: 14, color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 32),

              // 操作按鈕
              if (!_isSearching && !_isMatched)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _startRandomMatch,
                    icon: Icon(Icons.search, size: 28),
                    label: Text(
                      '開始隨機配對',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

              if (_isSearching && !_isMatched) ...[
                // 等待動畫
                CircularProgressIndicator(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _leaveQueue,
                    child: Text('取消配對'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],

              if (_isMatched) ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _enterChatRoom,
                    icon: Icon(Icons.chat, size: 28),
                    label: Text(
                      '進入聊天室',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isMatched = false;
                        _isSearching = false;
                        _status = '';
                        _matchResult = null;
                      });
                    },
                    child: Text('再次配對'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // 說明文字
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          '隨機配對說明',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• 系統會自動為您匹配其他等待中的用戶\n'
                      '• 配對成功後會創建 30 秒臨時聊天室\n'
                      '• 聊天室過期後可以選擇成為好友\n'
                      '• 成為好友後可以獲得永久聊天室',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade700,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
