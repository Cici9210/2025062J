// 裝置模型 (device.dart)
// 功能: 定義裝置資料模型
// 相依: 無

class Device {
  final int id;
  final String deviceUid;
  final int userId;
  final bool isConnected;  // 添加連接狀態
  
  Device({
    required this.id,
    required this.deviceUid,
    required this.userId,
    this.isConnected = false,  // 默認為未連接
  });
  
  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      deviceUid: json['device_uid'],
      userId: json['user_id'],
      isConnected: json['is_connected'] ?? false,  // 解析連接狀態
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_uid': deviceUid,
      'user_id': userId,
      'is_connected': isConnected,
    };
  }
}

class DeviceStatus {
  final int id;
  final String deviceUid;
  final bool isOnline;
  final DateTime? lastHeartbeat;
  final int? lastBpm;
  final double? lastTemperature;
  
  DeviceStatus({
    required this.id,
    required this.deviceUid,
    required this.isOnline,
    this.lastHeartbeat,
    this.lastBpm,
    this.lastTemperature,
  });
  
  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      id: json['id'],
      deviceUid: json['device_uid'],
      isOnline: json['is_online'],
      lastHeartbeat: json['last_heartbeat'] != null ? DateTime.parse(json['last_heartbeat']) : null,
      lastBpm: json['last_bpm'],
      lastTemperature: json['last_temperature'],
    );
  }
}
