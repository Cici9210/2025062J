// 認證服務 (auth_service.dart)
// 功能: 提供使用者認證、註冊相關API調用
// 相依: http

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/user.dart';

class AuthService {
  final String baseUrl = AppConfig.apiBaseUrl;
  
  // 註冊新使用者
  Future<User> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('註冊失敗: ${response.body}');
    }
  }
  
  // 使用者登入
  Future<String> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': email,
        'password': password,
      },
    );
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data['access_token'];
    } else {
      throw Exception('登入失敗: ${response.body}');
    }
  }
  
  // 獲取使用者資料
  Future<User> getUserProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/me'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('無法獲取使用者資料');
    }
  }
}
