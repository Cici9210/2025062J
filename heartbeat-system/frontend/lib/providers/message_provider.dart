// 消息狀態提供者 (message_provider.dart)
// 功能: 管理消息相關的狀態
// 相依: flutter, message_service, websocket_service

import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/message_service.dart';
import '../services/websocket_service.dart';

class MessageProvider with ChangeNotifier {
  final MessageService _messageService = MessageService();
  final WebSocketService _webSocketService = WebSocketService();
  
  List<Message> _messages = [];
  List<MessageConversation> _conversations = [];
  bool _isLoading = false;
  int? _currentUserId;
  int? _currentChatUserId;
  
  List<Message> get messages => _messages;
  List<MessageConversation> get conversations => _conversations;
  bool get isLoading => _isLoading;
    // 設置當前用戶ID
  void setCurrentUserId(int userId) {
    _currentUserId = userId;
  }
  
  // 設置當前聊天用戶ID
  void setCurrentChatUserId(int? userId) {
    _currentChatUserId = userId;
  }
  
  // 加載與特定用戶的消息歷史
  Future<void> loadMessages(String token, int otherUserId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final messages = await _messageService.getMessages(token, otherUserId);
      _messages = messages;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // 發送消息
  Future<void> sendMessage(String token, int receiverId, String content) async {
    try {
      final message = await _messageService.sendMessage(token, receiverId, content);
      _messages.add(message);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
  
  // 加載對話列表
  Future<void> loadConversations(String token) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final conversations = await _messageService.getConversations(token);
      _conversations = conversations;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
    // 添加本地消息（當WebSocket通知新消息到達時）
  void addMessage(Message message) {
    _messages.add(message);
    notifyListeners();
  }
  
  // 初始化WebSocket連接並設置消息監聽
  void initWebSocket(String deviceId) {
    // 連接WebSocket
    _webSocketService.connect(deviceId);
    
    // 設置新消息監聽
    _webSocketService.onMessageReceived((data) {
      if (data.containsKey('message')) {
        final message = Message.fromJson(data['message']);
        
        // 添加到當前消息列表（如果是當前聊天的對象）
        if (_currentChatUserId != null && 
            (message.senderId == _currentChatUserId || message.receiverId == _currentChatUserId)) {
          addMessage(message);
        }
        
        // 更新對話列表
        updateConversationWithMessage(message);
      }
    });
  }
  
  // 根據新消息更新對話列表
  void updateConversationWithMessage(Message message) {
    if (_currentUserId == null) return;
    
    // 確定對話對象ID（非當前用戶的ID）
    final otherUserId = message.senderId == _currentUserId ? message.receiverId : message.senderId;
    
    // 查找現有對話
    final existingIndex = _conversations.indexWhere((conv) => conv.userId == otherUserId);
    
    if (existingIndex >= 0) {
      // 更新現有對話
      final existing = _conversations[existingIndex];
      _conversations[existingIndex] = MessageConversation(
        userId: existing.userId,
        userName: existing.userName,
        latestMessage: message.content,
        latestTime: message.createdAt,
        unread: message.senderId != _currentUserId,  // 如果發送者不是當前用戶，則標記為未讀
      );
    }
    
    notifyListeners();
  }
  
  // 清理WebSocket連接
  void dispose() {
    _webSocketService.disconnect();
    super.dispose();
  }
}
