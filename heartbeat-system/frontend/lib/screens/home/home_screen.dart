// 首頁畫面 (home_screen.dart)
// 功能: 系統主畫面，顯示已綁定裝置並允許導航到其他功能
// 相依: flutter, provider

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/ui_constants.dart';
import '../../models/device.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friend_provider.dart';
import '../../services/device_service.dart';
import '../device/bind_device_screen.dart';
import '../interaction/heart_interaction_screen.dart';
import '../friend/friend_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DeviceService _deviceService = DeviceService();
  List<Device> _devices = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadDevices();
  }
  
  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.token != null) {
        final devices = await _deviceService.getUserDevices(authProvider.token!);
        setState(() {
          _devices = devices;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('載入裝置失敗: $e')),
      );
    }
  }
  
  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
  }  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '我的心臟',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: UIConstants.textLight,
        elevation: 0,
        actions: [
          // 好友按鈕
          IconButton(
            icon: Consumer<FriendProvider>(
              builder: (context, friendProvider, child) {
                return Stack(
                  children: [
                    const Icon(Icons.people, size: 26),
                    if (friendProvider.hasPendingRequests)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: UIConstants.heartColor,
                            borderRadius: BorderRadius.circular(UIConstants.radiusS),
                            border: Border.all(color: Colors.white, width: 1),
                            boxShadow: UIConstants.shadowSmall,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${friendProvider.pendingRequests.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FriendListScreen()),
              );
            },
            tooltip: '查看好友',
          ),
          // 登出按鈕
          IconButton(
            icon: const Icon(Icons.exit_to_app, size: 26),
            onPressed: _logout,
            tooltip: '登出',
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
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: UIConstants.spaceM),
                    const Text(
                      '載入裝置中...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : _devices.isEmpty
                ? _buildEmptyState()
                : _buildDeviceList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BindDeviceScreen()),
          ).then((_) => _loadDevices());
        },
        backgroundColor: UIConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusL),
        ),
        child: const Icon(Icons.add, size: 28),
        tooltip: '綁定新裝置',
      ),
    );
  }
    Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _loadDevices,
      color: UIConstants.primaryColor,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Container(
            height: MediaQuery.of(context).size.height - AppBar().preferredSize.height - 100,
            child: Center(
              child: Container(
                margin: EdgeInsets.all(UIConstants.spaceXL),
                padding: EdgeInsets.all(UIConstants.spaceXL),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(UIConstants.radiusXL),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(UIConstants.spaceXL),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: UIConstants.heartColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.heart_broken,
                        size: 80,
                        color: UIConstants.heartColor,
                      ),
                    ),
                    SizedBox(height: UIConstants.spaceL),
                    Text(
                      '還沒有綁定裝置',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: UIConstants.spaceM),
                    Text(
                      '點擊右下角按鈕綁定您的壓感互動裝置',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: UIConstants.spaceXL),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => BindDeviceScreen()),
                        ).then((_) => _loadDevices());
                      },
                      icon: Icon(Icons.add),
                      label: Text(
                        '綁定裝置',
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
            ),
          ),
        ],
      ),
    );
  }
    Widget _buildDeviceList() {
    return RefreshIndicator(
      onRefresh: _loadDevices,
      color: UIConstants.primaryColor,
      child: ListView(
        padding: EdgeInsets.only(
          left: UIConstants.spaceL,
          right: UIConstants.spaceL,
          top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 16,
          bottom: UIConstants.spaceL,
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // 裝置列表標題
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: UIConstants.spaceM,
              vertical: UIConstants.spaceM,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '我的裝置',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
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
                    '${_devices.length}個',
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
          SizedBox(height: UIConstants.spaceM),
          ..._devices.map((device) => _buildDeviceCard(device)).toList(),
        ],
      ),
    );
  }
  
  Widget _buildDeviceCard(Device device) {
    return Container(
      margin: EdgeInsets.only(bottom: UIConstants.spaceL),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(UIConstants.radiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusXL),
        ),
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(UIConstants.spaceL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [UIConstants.primaryColor, UIConstants.secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: UIConstants.primaryColor.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  SizedBox(width: UIConstants.spaceL),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '裝置 ${device.deviceUid}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: UIConstants.textDark,
                          ),
                        ),
                        SizedBox(height: UIConstants.spaceS),
                        Text(
                          'ID: ${device.id}',
                          style: TextStyle(
                            color: UIConstants.textMedium,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: UIConstants.spaceS),
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: UIConstants.successColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: UIConstants.spaceXS),
                            Text(
                              '已連接',
                              style: TextStyle(
                                color: UIConstants.successColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: UIConstants.spaceM),
              // 操作按鈕
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HeartInteractionScreen(device: device),
                          ),
                        );
                      },
                      icon: Icon(Icons.favorite_border),
                      label: Text('開始互動'),
                      style: UIConstants.primaryButtonStyle,
                    ),
                  ),
                  SizedBox(width: UIConstants.spaceM),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(UIConstants.radiusM),
                    ),
                    child: IconButton(
                      onPressed: () {
                        // 未來可以添加裝置詳情或設定功能
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('裝置設定功能即將推出')),
                        );
                      },
                      icon: Icon(Icons.settings, color: UIConstants.textMedium),
                      tooltip: '裝置設定',
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
}
