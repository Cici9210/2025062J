
// 好友詳情畫面 (friend_detail_screen.dart)
// 功能: 顯示好友心臟狀態及互動資訊
// 相依: flutter, provider

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/interaction_provider.dart';
import '../../widgets/heart_animation.dart';

class FriendDetailScreen extends StatefulWidget {
  final UserWithStatus friend;
  
  const FriendDetailScreen({Key? key, required this.friend}) : super(key: key);

  @override
  State<FriendDetailScreen> createState() => _FriendDetailScreenState();
}

class _FriendDetailScreenState extends State<FriendDetailScreen> {
  bool _isRequestingPairing = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.friend.email),
        actions: [
          // 在線狀態指示
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Chip(
              label: Text(
                widget.friend.online ? '在線' : '離線',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              backgroundColor: widget.friend.online 
                  ? Colors.green 
                  : Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF9A8B), Color(0xFFFF6B6B)],
          ),
        ),
        child: Consumer<InteractionProvider>(
          builder: (context, interactionProvider, _) {
            return Column(
              children: [
                // 好友資訊卡片
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            radius: 40,
                            child: const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.friend.email,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.friend.online 
                                ? '目前在線' 
                                : widget.friend.lastActive != null 
                                    ? '最後活躍: ${_formatDateTime(widget.friend.lastActive!)}'
                                    : '從未上線',
                            style: TextStyle(
                              color: widget.friend.online ? Colors.green : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // 配對請求按鈕
                          if (!interactionProvider.isPaired)
                            ElevatedButton.icon(
                              onPressed: _isRequestingPairing 
                                  ? null 
                                  : () => _requestPairing(widget.friend.id),
                              icon: const Icon(Icons.favorite),
                              label: _isRequestingPairing 
                                  ? const SizedBox(
                                      width: 20, 
                                      height: 20, 
                                      child: CircularProgressIndicator(strokeWidth: 2)
                                    )
                                  : const Text('請求心臟配對'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Theme.of(context).primaryColor,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                            )
                          else if (interactionProvider.pairedUserId == widget.friend.id)
                            ElevatedButton.icon(
                              onPressed: () => _endPairing(),
                              icon: const Icon(Icons.heart_broken),
                              label: const Text('結束配對'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // 心臟視覺化區域
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '好友的心臟',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // 心臟動畫
                        HeartAnimation(
                          size: 180,
                          color: Colors.red.shade800,
                          pulseRate: widget.friend.online ? 0.8 : 0.2,
                          isActive: widget.friend.online,
                        ),
                        const SizedBox(height: 30),
                        // 心臟狀態文字
                        Text(
                          widget.friend.online 
                              ? '心臟跳動中...' 
                              : '心臟休息中',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: widget.friend.online ? Colors.white : Colors.white.withOpacity(0.7),
                          ),
                        ),
                        if (interactionProvider.isPaired && 
                            interactionProvider.pairedUserId == widget.friend.id)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              '已配對 - 您可以感受對方的心跳',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
  
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} 天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} 小時前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} 分鐘前';
    } else {
      return '剛剛';
    }
  }
  
  Future<void> _requestPairing(int friendId) async {
    setState(() {
      _isRequestingPairing = true;
    });
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final interactionProvider = Provider.of<InteractionProvider>(context, listen: false);
    
    try {
      if (authProvider.token != null) {
        await interactionProvider.requestPairing(authProvider.token!, friendId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('配對請求已發送')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('配對請求失敗: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingPairing = false;
        });
      }
    }
  }
  
  void _endPairing() {
    final interactionProvider = Provider.of<InteractionProvider>(context, listen: false);
    interactionProvider.endPairing();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已結束配對')),
    );
  }
}
