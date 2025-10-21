// 交流列表畫面 (message_list_screen.dart)
// 功能: 顯示所有對話列表
// 相依: flutter, provider

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/ui_constants.dart';
import '../../models/message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import 'message_detail_screen.dart';

class MessageListScreen extends StatefulWidget {
  const MessageListScreen({Key? key}) : super(key: key);

  @override
  State<MessageListScreen> createState() => _MessageListScreenState();
}

class _MessageListScreenState extends State<MessageListScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    
    if (authProvider.token == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await messageProvider.loadConversations(authProvider.token!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加載對話失敗: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('交流'),
        backgroundColor: UIConstants.primaryColor,
      ),
      body: RefreshIndicator(
        onRefresh: _loadConversations,
        child: Consumer<MessageProvider>(
          builder: (context, messageProvider, _) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (messageProvider.conversations.isEmpty) {
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
                      '沒有聊天記錄',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              padding: const EdgeInsets.all(UIConstants.spaceM),
              itemCount: messageProvider.conversations.length,
              itemBuilder: (context, index) {
                final conversation = messageProvider.conversations[index];
                return _buildConversationItem(conversation);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildConversationItem(MessageConversation conversation) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: UIConstants.spaceM),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MessageDetailScreen(
                userId: conversation.userId,
                userName: conversation.userName,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(UIConstants.spaceM),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: UIConstants.primaryColor.withOpacity(0.8),
                child: Text(
                  conversation.userName.isNotEmpty 
                      ? conversation.userName[0].toUpperCase() 
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: UIConstants.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          conversation.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _formatDateTime(conversation.latestTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: UIConstants.spaceXS),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.latestMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        if (conversation.unread)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: UIConstants.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
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
  
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      // 今天的消息只顯示時間
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      // 其他日期顯示月/日
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}
