
//好友請求列表 (friend_request_list.dart)
//功能: 顯示待處理的好友請求
//相依: flutter, provider

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/friend_request.dart';
import '../providers/auth_provider.dart';
import '../providers/friend_provider.dart';

class FriendRequestList extends StatelessWidget {
  const FriendRequestList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final friendProvider = Provider.of<FriendProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final requests = friendProvider.pendingRequests;
    
    if (requests.isEmpty) {
      return const Center(
        child: Text('沒有待處理的好友請求', style: TextStyle(color: Colors.white70)),
      );
    }
    
    return ListView.builder(
      itemCount: requests.length,
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        final request = requests[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            title: Text(request.fromUserEmail ?? '未知用戶'),
            subtitle: Text('請求添加您為好友'),
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
      },
    );
  }
}
