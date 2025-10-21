// 好友狀態提供者 (friend_provider.dart)
// 功能: 管理好友列表和狀態
// 相依: flutter

import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/friend_request.dart';
import '../services/friend_service.dart';

class FriendProvider with ChangeNotifier {
  final FriendService _friendService = FriendService();
  
  List<UserWithStatus> _friends = [];
  List<FriendRequest> _pendingRequests = [];
  bool _isLoading = false;
  
  // Getters
  List<UserWithStatus> get friends => _friends;
  List<FriendRequest> get pendingRequests => _pendingRequests;
  bool get isLoading => _isLoading;
  bool get hasPendingRequests => _pendingRequests.isNotEmpty;
    // 載入好友列表
  Future<void> loadFriends(String token) async {
    if (!_isLoading) {
      _isLoading = true;
      // 確保不是在構建期間調用 notifyListeners
      Future.microtask(() => notifyListeners());
      
      try {
        final friends = await _friendService.getFriends(token);
        final requests = await _friendService.getPendingRequests(token);
        
        _friends = friends;
        _pendingRequests = requests;
        _isLoading = false;
        notifyListeners();
      } catch (e) {
        _isLoading = false;
        notifyListeners();
        rethrow;
      }
    }
  }
  
  // 添加好友
  Future<void> addFriend(String token, String email) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _friendService.addFriend(token, email);
      await loadFriends(token);  // 重新載入好友列表
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // 接受好友請求
  Future<void> acceptFriendRequest(String token, int requestId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _friendService.acceptFriendRequest(token, requestId);
      await loadFriends(token);  // 重新載入好友列表
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // 拒絕好友請求
  Future<void> rejectFriendRequest(String token, int requestId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _friendService.rejectFriendRequest(token, requestId);
      await loadFriends(token);  // 重新載入好友列表
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // 移除好友
  Future<void> removeFriend(String token, int friendId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _friendService.removeFriend(token, friendId);
      
      // 從本地列表中移除
      _friends.removeWhere((friend) => friend.id == friendId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
