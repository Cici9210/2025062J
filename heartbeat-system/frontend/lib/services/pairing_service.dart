// 配對聊天服務 (pairing_service.dart)
// 功能: 提供新的配對、臨時聊天室、好友邀請相關的API服務
// 相依: http

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class PairingService {
  final String baseUrl = AppConfig.apiBaseUrl;

  // 創建配對
  Future<Map<String, dynamic>> createPairing(String token, int targetUserId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/pairing/match'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'target_user_id': targetUserId,
      }),
    );

    if (response.statusCode == 200) {
      final String responseBody = utf8.decode(response.bodyBytes);
      return jsonDecode(responseBody);
    } else {
      throw Exception('配對失敗: ${response.statusCode}');
    }
  }

  // 獲取聊天室列表
  Future<List<Map<String, dynamic>>> getChatRooms(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/pairing/chat-rooms'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final String responseBody = utf8.decode(response.bodyBytes);
      final dynamic parsed = jsonDecode(responseBody);
      
      // 處理可能是單個對象或數組的情況
      if (parsed is List) {
        return List<Map<String, dynamic>>.from(parsed);
      } else if (parsed is Map) {
        return [Map<String, dynamic>.from(parsed)];
      }
      return [];
    } else {
      throw Exception('獲取聊天室失敗: ${response.statusCode}');
    }
  }

  // 檢查聊天室過期並觸發好友邀請
  Future<Map<String, dynamic>> checkChatRoomExpiry(String token, int chatRoomId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/pairing/chat-room/$chatRoomId/check-expiry'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final String responseBody = utf8.decode(response.bodyBytes);
      return jsonDecode(responseBody);
    } else {
      throw Exception('檢查過期失敗: ${response.statusCode}');
    }
  }

  // 獲取好友邀請列表
  Future<List<Map<String, dynamic>>> getInvitations(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/pairing/invitations'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final String responseBody = utf8.decode(response.bodyBytes);
      final dynamic parsed = jsonDecode(responseBody);
      
      // 處理可能是單個對象或數組的情況
      if (parsed is List) {
        return List<Map<String, dynamic>>.from(parsed);
      } else if (parsed is Map) {
        return [Map<String, dynamic>.from(parsed)];
      }
      return [];
    } else {
      throw Exception('獲取邀請失敗: ${response.statusCode}');
    }
  }

  // 回應好友邀請
  Future<Map<String, dynamic>> respondToInvitation(
    String token, 
    int invitationId, 
    String response  // "accept" 或 "reject"
  ) async {
    final httpResponse = await http.post(
      Uri.parse('$baseUrl/api/pairing/invitations/$invitationId/respond'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'response': response,
      }),
    );

    if (httpResponse.statusCode == 200) {
      final String responseBody = utf8.decode(httpResponse.bodyBytes);
      return jsonDecode(responseBody);
    } else {
      throw Exception('回應邀請失敗: ${httpResponse.statusCode}');
    }
  }

  // 獲取好友列表 (新 API)
  Future<List<Map<String, dynamic>>> getFriends(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/pairing/friends'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final String responseBody = utf8.decode(response.bodyBytes);
      final dynamic parsed = jsonDecode(responseBody);
      
      // 處理可能是單個對象或數組的情況
      if (parsed is List) {
        return List<Map<String, dynamic>>.from(parsed);
      } else if (parsed is Map) {
        return [Map<String, dynamic>.from(parsed)];
      }
      return [];
    } else {
      throw Exception('獲取好友列表失敗: ${response.statusCode}');
    }
  }

  // 檢查是否為好友
  Future<bool> isFriend(String token, int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/pairing/is-friend/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final String responseBody = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> result = jsonDecode(responseBody);
      return result['is_friend'] ?? false;
    } else {
      return false;
    }
  }

  // 隨機配對 (新功能)
  Future<Map<String, dynamic>> randomMatch(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/pairing/random-match'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: jsonEncode({}),
    );

    if (response.statusCode == 200) {
      final String responseBody = utf8.decode(response.bodyBytes);
      return jsonDecode(responseBody);
    } else {
      throw Exception('隨機配對失敗: ${response.statusCode}');
    }
  }

  // 離開配對隊列
  Future<Map<String, dynamic>> leaveQueue(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/pairing/leave-queue'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: jsonEncode({}),
    );

    if (response.statusCode == 200) {
      final String responseBody = utf8.decode(response.bodyBytes);
      return jsonDecode(responseBody);
    } else {
      throw Exception('離開隊列失敗: ${response.statusCode}');
    }
  }

  // 獲取好友裝置狀態 (新功能)
  Future<List<Map<String, dynamic>>> getFriendDevices(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/devices/friends/devices'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final String responseBody = utf8.decode(response.bodyBytes);
      final dynamic parsed = jsonDecode(responseBody);
      
      if (parsed is List) {
        return List<Map<String, dynamic>>.from(parsed);
      } else if (parsed is Map) {
        return [Map<String, dynamic>.from(parsed)];
      }
      return [];
    } else {
      throw Exception('獲取好友裝置失敗: ${response.statusCode}');
    }
  }
}
