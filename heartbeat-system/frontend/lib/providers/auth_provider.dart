"""
認證狀態提供者 (auth_provider.dart)
功能: 管理使用者認證狀態
相依: flutter, shared_preferences
"""
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  String? _token;
  bool _isLoading = false;
  
  // 判斷是否已認證
  bool get isAuthenticated => _token != null;
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get token => _token;
  
  // 初始化方法，從本地存儲讀取認證資訊
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token != null) {
      _token = token;
      try {
        _user = await _authService.getUserProfile(token);
        notifyListeners();
      } catch (e) {
        // 如果令牌無效，清除認證資訊
        await logout();
      }
    }
  }
  
  // 使用者註冊
  Future<void> register(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final user = await _authService.register(email, password);
      _user = user;
      
      // 註冊成功後自動登入
      final token = await _authService.login(email, password);
      _token = token;
      
      // 存儲令牌
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('auth_token', token);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // 使用者登入
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final token = await _authService.login(email, password);
      _token = token;
      
      // 獲取使用者資料
      _user = await _authService.getUserProfile(token);
      
      // 存儲令牌
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('auth_token', token);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // 使用者登出
  Future<void> logout() async {
    _user = null;
    _token = null;
    
    // 清除本地存儲的令牌
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('auth_token');
    
    notifyListeners();
  }
}
