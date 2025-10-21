// WebSocket服務 (websocket_service.dart)
// 功能: 管理與後端的WebSocket連接
// 相依: web_socket_channel

import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../config/app_config.dart';

// 定義訊息回調函數類型
typedef MessageCallback = void Function(Map<String, dynamic> message);

class WebSocketService {
  WebSocketChannel? _channel;
  String? _deviceId;
  bool _connected = false;
  
  // 回調函數
  MessageCallback? _onHeartbeatReceived;
  MessageCallback? _onPressureReceived;
  MessageCallback? _onMessageReceived;

  // 檢查連接狀態
  bool get isConnected => _connected;

  // 建立WebSocket連接
  void connect(String deviceId) {
    _deviceId = deviceId;
    final wsUrl = '${AppConfig.wsBaseUrl}/ws/$deviceId';
    
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    _connected = true;
    
    // 監聽訊息
    _channel!.stream.listen(
      (message) {
        final data = jsonDecode(message);
        final messageType = data['type'];
        
      // 根據訊息類型調用相應回調
        if (messageType == 'paired_heartbeat' && _onHeartbeatReceived != null) {
          _onHeartbeatReceived!(data);
        } else if (messageType == 'paired_pressure' && _onPressureReceived != null) {
          _onPressureReceived!(data);
        } else if (messageType == 'new_message' && _onMessageReceived != null) {
          _onMessageReceived!(data);
        }
      },
      onDone: () {
        _connected = false;
      },
      onError: (error) {
        print('WebSocket 錯誤: $error');
        _connected = false;
      },
    );
  }
  
  // 發送心跳數據
  void sendHeartbeat(int bpm, double temperature) {
    if (_channel != null && _connected) {
      _channel!.sink.add(jsonEncode({
        'type': 'heartbeat',
        'device_id': _deviceId,
        'bpm': bpm,
        'temperature': temperature
      }));
    }
  }
  
  // 發送壓力數據
  void sendPressure(double pressureLevel) {
    if (_channel != null && _connected) {
      _channel!.sink.add(jsonEncode({
        'type': 'pressure',
        'device_id': _deviceId,
        'pressure_level': pressureLevel
      }));
    }
  }
  
  // 設置心跳數據接收回調
  void onHeartbeatReceived(MessageCallback callback) {
    _onHeartbeatReceived = callback;
  }
    // 設置壓力數據接收回調
  void onPressureReceived(MessageCallback callback) {
    _onPressureReceived = callback;
  }
  
  // 設置新訊息接收回調
  void onMessageReceived(MessageCallback callback) {
    _onMessageReceived = callback;
  }
  
  // 關閉WebSocket連接
  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close(status.goingAway);
      _connected = false;
    }
  }
}
