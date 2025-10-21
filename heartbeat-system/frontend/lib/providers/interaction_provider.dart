// 互動狀態提供者 (interaction_provider.dart)
// 功能: 管理互動和配對狀態
// 相依: flutter

import 'package:flutter/material.dart';
import '../models/interaction.dart';
import '../services/device_service.dart';
import '../services/websocket_service.dart';

class InteractionProvider with ChangeNotifier {
  final DeviceService _deviceService = DeviceService();
  final WebSocketService _webSocketService = WebSocketService();
  
  bool _isPaired = false;
  int? _pairedUserId;
  double _localPressure = 0.0;
  double _remotePressure = 0.0;
  int _remoteBpm = 70;
  double _remoteTemperature = 36.5;
  
  // Getters
  bool get isPaired => _isPaired;
  int? get pairedUserId => _pairedUserId;
  double get localPressure => _localPressure;
  double get remotePressure => _remotePressure;
  int get remoteBpm => _remoteBpm;
  double get remoteTemperature => _remoteTemperature;
  bool get isConnected => _webSocketService.isConnected;
  
  // 初始化WebSocket連接
  void initializeWebSocket(String deviceId, String token) {
    if (!_webSocketService.isConnected) {
      _webSocketService.connect(deviceId);
      
      // 設置回調函數
      _webSocketService.onHeartbeatReceived((data) {
        _remoteBpm = data['bpm'];
        _remoteTemperature = data['temperature'].toDouble();
        notifyListeners();
      });
      
      _webSocketService.onPressureReceived((data) {
        _remotePressure = data['pressure_level'].toDouble();
        notifyListeners();
      });
    }
  }
  
  // 更新本地壓力值並發送到伺服器
  void updatePressure(double pressure) {
    _localPressure = pressure;
    
    // 發送壓力數據
    if (_webSocketService.isConnected) {
      _webSocketService.sendPressure(pressure);
    }
    
    notifyListeners();
  }
  
  // 發送心跳數據 (模擬)
  void sendHeartbeat(int bpm, double temperature) {
    if (_webSocketService.isConnected) {
      _webSocketService.sendHeartbeat(bpm, temperature);
    }
  }
  
  // 請求配對
  Future<void> requestPairing(String token, int? targetUserId) async {
    try {
      final response = await _deviceService.requestPairing(token, targetUserId);
      _isPaired = response.status == "active";
      _pairedUserId = response.targetUserId;
      notifyListeners();
    } catch (e) {
      print('配對請求失敗: $e');
      rethrow;
    }
  }
  
  // 隨機配對
  Future<void> randomPairing(String token) async {
    try {
      final response = await _deviceService.randomPairing(token);
      _isPaired = response.status == "active";
      _pairedUserId = response.targetUserId;
      notifyListeners();
    } catch (e) {
      print('隨機配對失敗: $e');
      rethrow;
    }
  }
  
  // 結束配對
  void endPairing() {
    _isPaired = false;
    _pairedUserId = null;
    _remotePressure = 0.0;
    notifyListeners();
  }
  
  // 關閉連接
  void dispose() {
    if (_webSocketService.isConnected) {
      _webSocketService.disconnect();
    }
    super.dispose();
  }
}
