// 使用者模型 (user.dart)
// 功能: 定義使用者資料模型
// 相依: 無

class User {
  final int id;
  final String email;
  final DateTime createdAt;
  
  User({
    required this.id,
    required this.email,
    required this.createdAt,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class UserWithStatus extends User {
  final bool online;
  final DateTime? lastActive;
  
  UserWithStatus({
    required int id,
    required String email,
    required DateTime createdAt,
    this.online = false,
    this.lastActive,
  }) : super(id: id, email: email, createdAt: createdAt);
  
  factory UserWithStatus.fromJson(Map<String, dynamic> json) {
    return UserWithStatus(
      id: json['id'],
      email: json['email'],
      createdAt: DateTime.parse(json['created_at']),
      online: json['online'] ?? false,
      lastActive: json['last_active'] != null ? DateTime.parse(json['last_active']) : null,
    );
  }
  
  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    data['online'] = online;
    if (lastActive != null) {
      data['last_active'] = lastActive!.toIso8601String();
    }
    return data;
  }
}
