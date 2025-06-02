
// 待處理好友請求畫面 (friend_request_screen.dart)
// 功能: 顯示使用者的待處理好友請求
// 相依: flutter, provider

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/friend_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friend_provider.dart';

class FriendRequestScreen extends StatefulWidget {
  const FriendRequestScreen({Key? key}) : super(key: key);

  @override
  State<FriendRequestScreen> createState() => _FriendRequestScreenState();
}

class _FriendRequestScreenState extends State<FriendRequestScreen> {
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadFriendRequests();
  }
  
  Future<void> _loadFriendRequests() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);
    
    if (authProvider.token != null) {
      try {
        await friendProvider.loadFriends(authProvider.token!);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('載入好友請求失敗: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('好友請求'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF9A8B), Color(0xFFFF6B6B)],
          ),
        ),
        child: Consumer<FriendProvider>(
          builder: (context, friendProvider, _) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            
            if (friendProvider.pendingRequests.isEmpty) {
              return _buildEmptyState();
            }
            
            return RefreshIndicator(
              onRefresh: _loadFriendRequests,
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: friendProvider.pendingRequests.length,
                itemBuilder: (context, index) {
                  return _buildRequestItem(friendProvider.pendingRequests[index]);
                },
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.white,
          ),
          SizedBox(height: 16),
          Text(
            '沒有待處理的好友請求',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRequestItem(FriendRequest request) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          request.fromUserEmail ?? '未知用戶',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text('請求添加您為好友'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 接受按鈕
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              tooltip: '接受',
              onPressed: () async {
                try {
                  await friendProvider.acceptFriendRequest(
                    authProvider.token!,
                    request.id,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已接受好友請求')),
                  );
                  _loadFriendRequests();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('操作失敗: $e')),
                  );
                }
              },
            ),
            // 拒絕按鈕
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              tooltip: '拒絕',
              onPressed: () async {
                try {
                  await friendProvider.rejectFriendRequest(
                    authProvider.token!,
                    request.id,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已拒絕好友請求')),
                  );
                  _loadFriendRequests();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('操作失敗: $e')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
