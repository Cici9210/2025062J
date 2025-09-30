// 交流詳情畫面 (message_detail_screen.dart)
// 功能: 顯示與特定用戶的消息記錄，允許發送新消息
// 相依: flutter, provider

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/ui_constants.dart';
import '../../models/message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';

class MessageDetailScreen extends StatefulWidget {
  final int userId;
  final String userName;
  
  const MessageDetailScreen({
    Key? key, 
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  int? _currentUserId;
    @override
  void initState() {
    super.initState();
    _loadMessages();
    
    // 獲取當前用戶ID
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      _currentUserId = authProvider.user!.id;
      // 設置MessageProvider中的當前用戶ID
      messageProvider.setCurrentUserId(_currentUserId!);
    }
    
    // 設置當前聊天用戶ID
    messageProvider.setCurrentChatUserId(widget.userId);
  }
    @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    
    // 離開時清除當前聊天用戶ID
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    messageProvider.setCurrentChatUserId(null);
    
    super.dispose();
  }
  
  Future<void> _loadMessages() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    
    if (authProvider.token == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await messageProvider.loadMessages(authProvider.token!, widget.userId);
      // 載入後滾動到底部
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加載消息失敗: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    
    if (authProvider.token == null) return;
    
    final content = _messageController.text.trim();
    _messageController.clear();
    
    try {
      await messageProvider.sendMessage(authProvider.token!, widget.userId, content);
      // 發送後滾動到底部
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('發送消息失敗: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
        backgroundColor: UIConstants.primaryColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<MessageProvider>(
              builder: (context, messageProvider, _) {
                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (messageProvider.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.message_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '還沒有聊天記錄',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '開始發送訊息吧！',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(UIConstants.spaceM),
                  itemCount: messageProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = messageProvider.messages[index];
                    final bool isMe = message.senderId == _currentUserId;
                    return _buildMessageItem(message, isMe);
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(UIConstants.spaceM),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: '輸入訊息...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: UIConstants.spaceM,
                        vertical: UIConstants.spaceS,
                      ),
                      filled: true,
                      fillColor: Color(0xFFEFEFEF),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: UIConstants.spaceS),
                Container(
                  decoration: BoxDecoration(
                    color: UIConstants.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Message message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: UIConstants.spaceS),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              backgroundColor: Colors.grey.shade400,
              radius: 16,
              child: Text(
                widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: UIConstants.spaceS),
          ],
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            decoration: BoxDecoration(
              color: isMe ? UIConstants.primaryColor : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(UIConstants.radiusM),
            ),
            padding: const EdgeInsets.all(UIConstants.spaceM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    fontSize: 16,
                    color: isMe ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: isMe ? Colors.white.withOpacity(0.8) : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: UIConstants.spaceS),
            CircleAvatar(
              backgroundColor: UIConstants.primaryColor,
              radius: 16,
              child: const Text(
                '我',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
