"""
裝置服務 (device_service.dart)
功能: 提供裝置相關API調用
相依: http
"""
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/device.dart';
import '../models/interaction.dart';

class DeviceService {
  final String baseUrl = AppConfig.apiBaseUrl;
  
  // 綁定裝置
  Future<Device> bindDevice(String token, String deviceUid) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/devices/bind'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'device_uid': deviceUid,
      }),
    );
    
    if (response.statusCode == 200) {
      return Device.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('裝置綁定失敗: ${response.body}');
    }
  }
  
  // 獲取裝置狀態
  Future<DeviceStatus> getDeviceStatus(String token, int deviceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/devices/status/$deviceId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return DeviceStatus.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('獲取裝置狀態失敗: ${response.body}');
    }
  }
  
  // 記錄互動
  Future<Interaction> recordInteraction(String token, double pressureLevel) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/interactions/record'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'pressure_level': pressureLevel,
      }),
    );
    
    if (response.statusCode == 200) {
      return Interaction.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('記錄互動失敗: ${response.body}');
    }
  }
  
  // 發送配對請求
  Future<PairingResponse> requestPairing(String token, int? targetUserId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/pairing/request'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'target_user_id': targetUserId,
      }),
    );
    
    if (response.statusCode == 200) {
      return PairingResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('配對請求失敗: ${response.body}');
    }
  }
  
  // 隨機配對
  Future<PairingResponse> randomPairing(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/pairing/random'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return PairingResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('隨機配對失敗: ${response.body}');
    }
  }
}
