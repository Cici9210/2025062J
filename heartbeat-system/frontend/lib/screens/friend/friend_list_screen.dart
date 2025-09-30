//好友列表畫面 (friend_list_screen.dart)
//功能: 顯示使用者的好友列表及其狀態
//相依: flutter, provider

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friend_provider.dart';
import '../../widgets/friend_request_list.dart';
import '../../config/ui_constants.dart';
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          '我的好友',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: UIConstants.textLight,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: UIConstants.backgroundGradient,
          ),
        ),
        child: Consumer<FriendProvider>(          
          builder: (context, friendProvider, _) {
            if (_isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: UIConstants.spaceM),
                    const Text(
                      '載入好友中...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            // 使用CustomScrollView來支持多個滾動區域
            return RefreshIndicator(
              onRefresh: _loadFriends,
              color: UIConstants.primaryColor,
              displacement: 80,
              child: CustomScrollView(
                slivers: [
                  // 頂部間距
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 16,
                    ),
                  ),
                  
                  // 待處理的好友請求區域
                  if (friendProvider.hasPendingRequests)
                    SliverToBoxAdapter(
                      child: Padding(                        
                        padding: EdgeInsets.symmetric(
                          horizontal: UIConstants.spaceL,
                          vertical: UIConstants.spaceM,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  '待處理請求',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(width: UIConstants.spaceM),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: UIConstants.spaceM,
                                    vertical: UIConstants.spaceXS,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(UIConstants.radiusL),
                                  ),
                                  child: Text(
                                    '${friendProvider.pendingRequests.length}個',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: UIConstants.spaceM),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(UIConstants.radiusXL),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(UIConstants.spaceL),
                                child: FriendRequestList(),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: UIConstants.spaceL),
                              child: const Divider(color: Colors.white30, thickness: 1.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // 好友列表區域
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: UIConstants.spaceL,
                        vertical: UIConstants.spaceM,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '我的好友',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (friendProvider.friends.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: UIConstants.spaceM,
                                vertical: UIConstants.spaceXS,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(UIConstants.radiusL),
                              ),
                              child: Text(
                                '${friendProvider.friends.length}位',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
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
                      padding: EdgeInsets.symmetric(
                        horizontal: UIConstants.spaceL,
                        vertical: UIConstants.spaceM,
                      ),
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
        backgroundColor: UIConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusL),
        ),
        child: const Icon(Icons.person_add, size: 28),
        tooltip: '添加好友',
      ),
    );
  }
    Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(UIConstants.spaceXL),
        margin: EdgeInsets.all(UIConstants.spaceL),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(UIConstants.radiusXL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.people_outline,
                size: 60,
                color: Colors.white,
              ),
            ),
            SizedBox(height: UIConstants.spaceL),
            const Text(
              '還沒有好友',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: UIConstants.spaceM),
            const Text(
              '點擊右下角按鈕添加新好友',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: UIConstants.spaceXL),
            ElevatedButton.icon(
              onPressed: _showAddFriendDialog,
              icon: Icon(Icons.person_add),
              label: Text(
                '添加好友',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: UIConstants.primaryColor,
                elevation: 8,
                shadowColor: UIConstants.primaryColor.withOpacity(0.4),
                padding: EdgeInsets.symmetric(
                  horizontal: UIConstants.spaceXL, 
                  vertical: UIConstants.spaceM,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(UIConstants.radiusL),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
    Widget _buildFriendItem(UserWithStatus friend) {
    return Container(
      margin: EdgeInsets.only(bottom: UIConstants.spaceM),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(UIConstants.radiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusXL),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: UIConstants.spaceL,
            vertical: UIConstants.spaceM,
          ),
          leading: Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      friend.online 
                          ? UIConstants.successColor.withOpacity(0.8)
                          : UIConstants.secondaryColor,
                      friend.online 
                          ? UIConstants.successColor
                          : UIConstants.primaryColor,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (friend.online ? UIConstants.successColor : UIConstants.primaryColor).withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 30),
              ),
              // 在線狀態指示器
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: friend.online ? UIConstants.successColor : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: UIConstants.shadowSmall,
                  ),
                ),
              ),
            ],
          ),
          title: Text(
            friend.email,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              friend.online 
                  ? '在線' 
                  : friend.lastActive != null 
                      ? '最後活躍: ${_formatDateTime(friend.lastActive!)}'
                      : '離線',
              style: TextStyle(
                color: friend.online ? UIConstants.successColor : Colors.grey,
                fontSize: 14,
                fontWeight: friend.online ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          trailing: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: UIConstants.heartColor.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FriendDetailScreen(friend: friend),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.favorite,
                    color: UIConstants.heartColor,
                    size: 26,
                  ),
                ),
              ),
            ),
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusXL),
        ),
        elevation: 10,
        backgroundColor: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(UIConstants.spaceL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: UIConstants.primaryColor.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.person_add,
                  size: 28,
                  color: UIConstants.primaryColor,
                ),
              ),
              SizedBox(height: UIConstants.spaceM),
              Text(
                '添加好友',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: UIConstants.primaryColor,
                ),
              ),
              SizedBox(height: UIConstants.spaceL),
              TextField(
                controller: emailController,
                decoration: UIConstants.inputDecoration(
                  '好友的電子郵件',
                  prefixIcon: Icons.email,
                ).copyWith(
                  hintText: '輸入好友的電子郵件地址',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: UIConstants.spaceXL),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: UIConstants.textMedium,
                        padding: EdgeInsets.symmetric(vertical: UIConstants.spaceM),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(UIConstants.radiusL),
                        ),
                      ),
                      child: Text(
                        '取消',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(width: UIConstants.spaceM),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (emailController.text.isNotEmpty) {
                          Navigator.pop(context);
                          await _addFriend(emailController.text);
                        }
                      },
                      style: UIConstants.primaryButtonStyle,
                      child: Text(
                        '添加',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
        );      } catch (e) {
        // 簡化錯誤處理方式，無需複雜的條件判斷
        String errorMessage = e.toString();
        
        // 提取出具體的錯誤訊息部分
        final match = RegExp(r'Exception: (.+)').firstMatch(errorMessage);
        final message = match?.group(1) ?? '添加好友失敗';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
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
