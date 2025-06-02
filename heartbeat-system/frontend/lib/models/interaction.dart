// 互動模型 (interaction.dart)
// 功能: 定義互動資料模型
// 相依: 無

class Interaction {
  final int id;
  final int userId;
  final DateTime timestamp;
  final double pressureLevel;
  
  Interaction({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.pressureLevel,
  });
  
  factory Interaction.fromJson(Map<String, dynamic> json) {
    return Interaction(
      id: json['id'],
      userId: json['user_id'],
      timestamp: DateTime.parse(json['timestamp']),
      pressureLevel: json['pressure_level'].toDouble(),
    );
  }
}

class PairingRequest {
  final int? targetUserId;
  
  PairingRequest({this.targetUserId});
  
  Map<String, dynamic> toJson() {
    return {
      'target_user_id': targetUserId,
    };
  }
}

class PairingResponse {
  final int pairingId;
  final String status;
  final int targetUserId;
  
  PairingResponse({
    required this.pairingId,
    required this.status,
    required this.targetUserId,
  });
  
  factory PairingResponse.fromJson(Map<String, dynamic> json) {
    return PairingResponse(
      pairingId: json['pairing_id'],
      status: json['status'],
      targetUserId: json['target_user_id'],
    );
  }
}
