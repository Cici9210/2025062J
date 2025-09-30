// 主畫面 (main_screen.dart)
// 功能: 管理底部導航和不同頁面的切換
// 相依: flutter, bottom_nav_bar, provider

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../providers/auth_provider.dart';
import '../providers/message_provider.dart';
import 'home/home_screen.dart';
import 'message/message_list_screen.dart';
import 'friend/friend_list_screen.dart';
import 'auth/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _hasNewMessages = false;
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const MessageListScreen(),
    const FriendListScreen(),
    const SettingsScreen(),
  ];
  
  @override
  void initState() {
    super.initState();
    _initWebSocket();
  }
    Future<void> _initWebSocket() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    
    if (authProvider.user != null && authProvider.token != null) {
      // 設置當前用戶ID
      messageProvider.setCurrentUserId(authProvider.user!.id);
      
      // 使用用戶ID初始化WebSocket
      messageProvider.initWebSocket(authProvider.user!.id.toString());
    }
  }
    void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
      
      // 如果切換到訊息頁面，清除新訊息標記
      if (index == 1 && _hasNewMessages) {
        _hasNewMessages = false;
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<MessageProvider>(
      builder: (context, messageProvider, _) {
        // 檢查是否有未讀訊息
        _hasNewMessages = messageProvider.conversations.any((conv) => conv.unread);
        
        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          bottomNavigationBar: BottomNavBar(
            selectedIndex: _selectedIndex,
            onItemSelected: _onItemSelected,
            hasNewMessages: _hasNewMessages,
          ),
        );
      },
    );
  }
}
