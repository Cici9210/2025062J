// 好友請求模型 (friend_request.dart)
// 功能: 定義好友請求資料結構
// 相依: 無

class FriendRequest {
  final int id;
  final int userIdFrom;
  final int userIdTo;
  final String status;
  final DateTime createdAt;
  final String? fromUserEmail;
  
  FriendRequest({
    required this.id,
    required this.userIdFrom,
    required this.userIdTo,
    required this.status,
    required this.createdAt,
    this.fromUserEmail,
  });
  
  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'],
      userIdFrom: json['user_id_1'],
      userIdTo: json['user_id_2'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      fromUserEmail: json['from_user_email'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id_1': userIdFrom,
      'user_id_2': userIdTo,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'from_user_email': fromUserEmail,
    };
  }
}
