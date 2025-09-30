//好友詳情畫面 (friend_detail_screen.dart)
//功能: 顯示好友心臟狀態及互動資訊
//相依: flutter, provider

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/interaction_provider.dart';
import '../../widgets/heart_animation.dart';
import '../../config/ui_constants.dart';

class FriendDetailScreen extends StatefulWidget {
  final UserWithStatus friend;
  
  const FriendDetailScreen({Key? key, required this.friend}) : super(key: key);

  @override
  State<FriendDetailScreen> createState() => _FriendDetailScreenState();
}

class _FriendDetailScreenState extends State<FriendDetailScreen> {
  bool _isRequestingPairing = false;
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.friend.email,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: UIConstants.textLight,
        elevation: 0,
        actions: [
          // 在線狀態指示
          Padding(
            padding: const EdgeInsets.all(UIConstants.spaceS),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: UIConstants.spaceM,
                vertical: UIConstants.spaceXS,
              ),
              decoration: BoxDecoration(
                color: widget.friend.online ? UIConstants.successColor : Colors.grey,
                borderRadius: BorderRadius.circular(UIConstants.radiusM),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: UIConstants.spaceXS),
                  Text(
                    widget.friend.online ? '在線' : '離線',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: UIConstants.backgroundGradient,
          ),
        ),
        child: Consumer<InteractionProvider>(
          builder: (context, interactionProvider, _) {
            return ListView(
              padding: EdgeInsets.only(
                top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 16,
                bottom: UIConstants.spaceL,
              ),
              children: [
                // 好友資訊卡片
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: UIConstants.spaceL),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(UIConstants.radiusXL),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(UIConstants.spaceL),
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  widget.friend.online 
                                      ? UIConstants.successColor.withOpacity(0.8)
                                      : UIConstants.secondaryColor,
                                  widget.friend.online 
                                      ? UIConstants.successColor
                                      : UIConstants.primaryColor,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (widget.friend.online ? UIConstants.successColor : UIConstants.primaryColor).withOpacity(0.4),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: UIConstants.spaceL),
                          Text(
                            widget.friend.email,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: UIConstants.textDark,
                            ),
                          ),
                          SizedBox(height: UIConstants.spaceS),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: UIConstants.spaceM,
                              vertical: UIConstants.spaceXS,
                            ),
                            decoration: BoxDecoration(
                              color: widget.friend.online 
                                  ? UIConstants.successColor.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(UIConstants.radiusL),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: widget.friend.online ? UIConstants.successColor : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: UIConstants.spaceXS),
                                Text(
                                  widget.friend.online 
                                      ? '目前在線' 
                                      : widget.friend.lastActive != null 
                                          ? '最後活躍: ${_formatDateTime(widget.friend.lastActive!)}'
                                          : '從未上線',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: widget.friend.online ? UIConstants.successColor : Colors.grey,
                                    fontWeight: widget.friend.online ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: UIConstants.spaceXL),
                          // 配對請求按鈕
                          if (!interactionProvider.isPaired)
                            ElevatedButton.icon(
                              onPressed: _isRequestingPairing 
                                  ? null 
                                  : () => _requestPairing(widget.friend.id),
                              icon: const Icon(Icons.favorite, size: 22),
                              label: _isRequestingPairing 
                                  ? const SizedBox(
                                      width: 20, 
                                      height: 20, 
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      )
                                    )
                                  : const Text(
                                      '請求心臟配對',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: UIConstants.primaryColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: UIConstants.spaceXL,
                                  vertical: UIConstants.spaceM,
                                ),
                                elevation: 8,
                                shadowColor: UIConstants.primaryColor.withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(UIConstants.radiusL),
                                ),
                              ),
                            )
                          else if (interactionProvider.pairedUserId == widget.friend.id)
                            ElevatedButton.icon(
                              onPressed: () => _endPairing(),
                              icon: const Icon(Icons.heart_broken, size: 22),
                              label: const Text(
                                '結束配對',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: UIConstants.errorColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: UIConstants.spaceXL, 
                                  vertical: UIConstants.spaceM,
                                ),
                                elevation: 8,
                                shadowColor: UIConstants.errorColor.withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(UIConstants.radiusL),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: UIConstants.spaceXL),
                
                // 心臟視覺化區域
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: UIConstants.spaceL),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(UIConstants.spaceM),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(UIConstants.radiusL),
                        ),
                        child: Text(
                          '好友的心臟',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      SizedBox(height: UIConstants.spaceL),
                      // 心臟動畫
                      Container(
                        padding: EdgeInsets.all(UIConstants.spaceXXL),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                          boxShadow: [
                            BoxShadow(
                              color: UIConstants.heartColor.withOpacity(0.2),
                              blurRadius: 30,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: HeartAnimation(
                          size: 180,
                          color: UIConstants.heartColor,
                          pulseRate: widget.friend.online ? 0.8 : 0.2,
                          isActive: widget.friend.online,
                        ),
                      ),
                      SizedBox(height: UIConstants.spaceXL),
                      // 心臟狀態文字
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: UIConstants.spaceXL,
                          vertical: UIConstants.spaceM,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(UIConstants.radiusXL),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.friend.online ? Icons.favorite : Icons.favorite_border,
                              color: widget.friend.online ? UIConstants.heartColor : Colors.white.withOpacity(0.7),
                              size: 28,
                            ),
                            SizedBox(width: UIConstants.spaceM),
                            Text(
                              widget.friend.online 
                                  ? '心臟跳動中...' 
                                  : '心臟休息中',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: widget.friend.online ? Colors.white : Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (interactionProvider.isPaired && 
                          interactionProvider.pairedUserId == widget.friend.id)
                        Padding(
                          padding: EdgeInsets.only(top: UIConstants.spaceXL),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: UIConstants.spaceL,
                              vertical: UIConstants.spaceM,
                            ),
                            decoration: BoxDecoration(
                              color: UIConstants.successColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(UIConstants.radiusL),
                              border: Border.all(
                                color: UIConstants.successColor.withOpacity(0.5),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: UIConstants.successColor.withOpacity(0.1),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: UIConstants.successColor,
                                  size: 22,
                                ),
                                SizedBox(width: UIConstants.spaceS),
                                Text(
                                  '已配對 - 您可以感受對方的心跳',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
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
  
  Future<void> _requestPairing(int friendId) async {
    setState(() {
      _isRequestingPairing = true;
    });
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final interactionProvider = Provider.of<InteractionProvider>(context, listen: false);
    
    try {
      if (authProvider.token != null) {
        await interactionProvider.requestPairing(authProvider.token!, friendId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('配對請求已發送')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('配對請求失敗: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingPairing = false;
        });
      }
    }
  }
  
  void _endPairing() {
    final interactionProvider = Provider.of<InteractionProvider>(context, listen: false);
    interactionProvider.endPairing();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已結束配對')),
    );
  }
}
