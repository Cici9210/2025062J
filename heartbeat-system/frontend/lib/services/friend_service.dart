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
        'Accept': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      try {
        final String responseBody = utf8.decode(response.bodyBytes);
        List<dynamic> friendsJson = jsonDecode(responseBody);
        return friendsJson.map((json) => UserWithStatus.fromJson(json)).toList();
      } catch (e) {
        throw Exception('解析好友列表資料錯誤: $e');
      }
    } else {
      String errorMessage = '獲取好友列表失敗';
      
      try {
        final String responseBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> errorData = jsonDecode(responseBody);
        if (errorData.containsKey('detail')) {
          errorMessage = errorData['detail'].toString();
        }
      } catch (e) {
        errorMessage = '獲取好友列表失敗: 伺服器錯誤';
      }
      
      throw Exception(errorMessage);
    }
  }
  
  // 獲取待處理的好友請求
  Future<List<FriendRequest>> getPendingRequests(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/friends/requests/pending'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        try {
          final String responseBody = utf8.decode(response.bodyBytes);
          List<dynamic> requestsJson = jsonDecode(responseBody);
          return requestsJson.map((json) => FriendRequest.fromJson(json)).toList();
        } catch (e) {
          print('解析好友請求資料錯誤: $e');
          // 返回空列表而不是拋出異常
          return [];
        }
      } else {
        print('獲取好友請求失敗: ${response.statusCode}');
        // 返回空列表而不是拋出異常
        return [];
      }
    } catch (e) {
      print('獲取好友請求時發生網絡錯誤: $e');
      // 返回空列表而不是拋出異常
      return [];
    }
  }
  
  // 添加好友
  Future<void> addFriend(String token, String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/friends/request'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'email': email,
        }),
      );
        if (response.statusCode != 200 && response.statusCode != 201) {
        // 檢查常見錯誤情況，使用固定的中文錯誤訊息
        if (response.statusCode == 400) {
          throw Exception('此用戶已經是您的好友或您已發送好友請求');
        } else if (response.statusCode == 404) {
          throw Exception('找不到此電子郵件的用戶');
        } else {
          throw Exception('添加好友失敗: 請檢查電子郵件格式或網路連接');
        }
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;  // 如果已經是Exception類型，直接拋出
      }
      throw Exception('添加好友失敗: ${e.toString()}');
    }
  }
    // 接受好友請求
  Future<void> acceptFriendRequest(String token, int requestId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/friends/request/$requestId/accept'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    
    if (response.statusCode != 200) {
      String errorMessage = '接受好友請求失敗';
      
      try {
        final String responseBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> errorData = jsonDecode(responseBody);
        if (errorData.containsKey('detail')) {
          errorMessage = errorData['detail'].toString();
        }
      } catch (e) {
        errorMessage = '接受好友請求失敗: 伺服器錯誤';
      }
      
      throw Exception(errorMessage);
    }
  }
  
  // 拒絕好友請求
  Future<void> rejectFriendRequest(String token, int requestId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/friends/request/$requestId/reject'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    
    if (response.statusCode != 200) {
      String errorMessage = '拒絕好友請求失敗';
      
      try {
        final String responseBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> errorData = jsonDecode(responseBody);
        if (errorData.containsKey('detail')) {
          errorMessage = errorData['detail'].toString();
        }
      } catch (e) {
        errorMessage = '拒絕好友請求失敗: 伺服器錯誤';
      }
      
      throw Exception(errorMessage);
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
