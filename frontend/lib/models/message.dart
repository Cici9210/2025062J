// 訊息模型 (message.dart)
// 功能: 定義訊息相關的數據模型
// 相依: 無

class Message {
  final int id;
  final int senderId;
  final int receiverId;
  final String content;
  final DateTime createdAt;
  final String? senderName; // 可選的發送者名稱，用於顯示
  
  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    this.senderName,
  });
  
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      senderName: json['sender_name'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'sender_name': senderName,
    };
  }
}

class MessageConversation {
  final int userId;
  final String userName;
  final String latestMessage;
  final DateTime latestTime;
  final bool unread;
  
  MessageConversation({
    required this.userId,
    required this.userName,
    required this.latestMessage,
    required this.latestTime,
    required this.unread,
  });
  
  factory MessageConversation.fromJson(Map<String, dynamic> json) {
    return MessageConversation(
      userId: json['user_id'],
      userName: json['user_name'],
      latestMessage: json['latest_message'],
      latestTime: DateTime.parse(json['latest_time']),
      unread: json['unread'] ?? false,
    );
  }
}
