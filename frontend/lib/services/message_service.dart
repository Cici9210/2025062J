// 消息服務 (message_service.dart)
// 功能: 提供與後端API通信的消息相關功能
// 相依: http, app_config

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/message.dart';

class MessageService {
  final String baseUrl = AppConfig.apiBaseUrl;
  
  // 獲取與特定用戶的消息歷史
  Future<List<Message>> getMessages(String token, int otherUserId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/messages/user/$otherUserId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Message.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load messages: ${response.body}');
      }
    } catch (e) {
      print('Error getting messages: $e');
      throw Exception('Failed to load messages: $e');
    }
  }
  
  // 發送消息
  Future<Message> sendMessage(String token, int receiverId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/messages/send'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'receiver_id': receiverId,
          'content': content,
        }),
      );
      
      if (response.statusCode == 200) {
        return Message.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to send message: ${response.body}');
      }
    } catch (e) {
      print('Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }
  
  // 獲取最近的對話列表
  Future<List<MessageConversation>> getConversations(String token) async {
    try {
      // 使用更安全的錯誤處理方式
      print('開始獲取對話列表，嘗試新的 API 路徑');
      // 先嘗試新的 API 路徑
      final uri = Uri.parse('$baseUrl/api/message-conversations');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        print('對話列表獲取成功');
        try {
          final List<dynamic> data = jsonDecode(response.body);
          return data.map((item) => MessageConversation.fromJson(item)).toList();
        } catch (parseError) {
          print('解析對話列表資料失敗: $parseError');
          return []; // 返回空列表，而不是拋出異常
        }
      } else {
        print('對話列表請求失敗，使用後備機制');
        // 如果失敗，返回空列表而不是拋出異常
        return [];
      }
    } catch (e) {
      print('獲取對話列表發生異常: $e');
      return []; // 返回空列表，而不是拋出異常
    }
  }
}
