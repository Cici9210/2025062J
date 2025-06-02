
// 好友列表畫面 (friend_list_screen.dart)
// 功能: 顯示使用者的好友列表及其狀態
// 相依: flutter, provider

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friend_provider.dart';
import '../../widgets/friend_request_list.dart';
import 'friend_detail_screen.dart';

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({Key? key}) : super(key: key);

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadFriends();
  }
  
  Future<void> _loadFriends() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);
    
    if (authProvider.token != null) {
      try {
        await friendProvider.loadFriends(authProvider.token!);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('載入好友失敗: $e')),
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
        title: const Text('我的好友'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF9A8B), Color(0xFFFF6B6B)],
          ),
        ),
        child: Consumer<FriendProvider>(          builder: (context, friendProvider, _) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            
            // 使用CustomScrollView來支持多個滾動區域
            return RefreshIndicator(
              onRefresh: _loadFriends,
              child: CustomScrollView(
                slivers: [
                  // 待處理的好友請求區域
                  if (friendProvider.hasPendingRequests)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '待處理請求',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: FriendRequestList(),
                              ),
                            ),
                            const Divider(color: Colors.white30, height: 32),
                          ],
                        ),
                      ),
                    ),
                  
                  // 好友列表區域
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: const Text(
                        '我的好友',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  // 如果沒有好友，顯示空狀態
                  if (friendProvider.friends.isEmpty)
                    SliverFillRemaining(
                      child: _buildEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildFriendItem(friendProvider.friends[index]),
                          childCount: friendProvider.friends.length,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFriendDialog,
        child: const Icon(Icons.person_add),
        tooltip: '添加好友',
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            '還沒有好友',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '點擊右下角按鈕添加新好友',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFriendItem(UserWithStatus friend) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            // 在線狀態指示器
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: friend.online ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          friend.email,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          friend.online 
              ? '在線' 
              : friend.lastActive != null 
                  ? '最後活躍: ${_formatDateTime(friend.lastActive!)}'
                  : '離線',
          style: TextStyle(
            color: friend.online ? Colors.green : Colors.grey,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.favorite),
          color: Theme.of(context).primaryColor,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FriendDetailScreen(friend: friend),
              ),
            );
          },
          tooltip: '查看心臟狀態',
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FriendDetailScreen(friend: friend),
            ),
          );
        },
      ),
    );
  }
  
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} 天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} 小時前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} 分鐘前';
    } else {
      return '剛剛';
    }
  }
  
  void _showAddFriendDialog() {
    final TextEditingController emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加好友'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: '好友的電子郵件',
            hintText: '輸入好友的電子郵件地址',
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isNotEmpty) {
                Navigator.pop(context);
                await _addFriend(emailController.text);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _addFriend(String email) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);
    
    if (authProvider.token != null) {
      try {
        setState(() {
          _isLoading = true;
        });
        
        await friendProvider.addFriend(authProvider.token!, email);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('好友添加請求已發送')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加好友失敗: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          await _loadFriends();
        }
      }
    }
  }
}
