// 好友服務 (friend_service.dart)
// 功能: 提供好友相關的API服務
// 相依: http

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/user.dart';
import '../models/friend_request.dart';

class FriendService {
  final String baseUrl = AppConfig.apiBaseUrl;
  
  // 獲取好友列表
  Future<List<UserWithStatus>> getFriends(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/friends'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      List<dynamic> friendsJson = jsonDecode(response.body);
      return friendsJson.map((json) => UserWithStatus.fromJson(json)).toList();
    } else {
      throw Exception('獲取好友列表失敗: ${response.body}');
    }
  }
  
  // 獲取待處理的好友請求
  Future<List<FriendRequest>> getPendingRequests(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/friends/requests/pending'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      List<dynamic> requestsJson = jsonDecode(response.body);
      return requestsJson.map((json) => FriendRequest.fromJson(json)).toList();
    } else {
      throw Exception('獲取好友請求失敗: ${response.body}');
    }
  }
  
  // 添加好友
  Future<void> addFriend(String token, String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/friends/request'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'email': email,
      }),
    );
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('添加好友失敗: ${response.body}');
    }
  }
  
  // 接受好友請求
  Future<void> acceptFriendRequest(String token, int requestId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/friends/request/$requestId/accept'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode != 200) {
      throw Exception('接受好友請求失敗: ${response.body}');
    }
  }
  
  // 拒絕好友請求
  Future<void> rejectFriendRequest(String token, int requestId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/friends/request/$requestId/reject'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode != 200) {
      throw Exception('拒絕好友請求失敗: ${response.body}');
    }
  }
  
  // 移除好友
  Future<void> removeFriend(String token, int friendId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/friends/$friendId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('移除好友失敗: ${response.body}');
    }
  }
}
