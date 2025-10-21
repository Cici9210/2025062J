import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../services/pairing_service.dart';
import '../../providers/auth_provider.dart';

class FriendDevicesScreen extends StatefulWidget {
  const FriendDevicesScreen({Key? key}) : super(key: key);

  @override
  State<FriendDevicesScreen> createState() => _FriendDevicesScreenState();
}

class _FriendDevicesScreenState extends State<FriendDevicesScreen> {
  final PairingService _pairingService = PairingService();
  
  List<Map<String, dynamic>> _devices = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadDevices();
    // 每 10 秒自動刷新一次
    _refreshTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _loadDevices();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    
    if (token == null) {
      setState(() {
        _errorMessage = '請先登入';
        _isLoading = false;
      });
      return;
    }

    try {
      final devices = await _pairingService.getFriendDevices(token);
      setState(() {
        _devices = devices;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '載入失敗: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _formatLastActive(String? lastActive) {
    if (lastActive == null) return '從未活躍';
    
    try {
      final DateTime lastActiveTime = DateTime.parse(lastActive);
      final Duration diff = DateTime.now().difference(lastActiveTime);
      
      if (diff.inMinutes < 1) {
        return '剛剛';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes} 分鐘前';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} 小時前';
      } else {
        return '${diff.inDays} 天前';
      }
    } catch (e) {
      return '未知';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('好友裝置狀態'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadDevices();
            },
            tooltip: '刷新',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('載入中...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadDevices();
              },
              child: Text('重試'),
            ),
          ],
        ),
      );
    }

    if (_devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.devices_other, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '目前沒有好友裝置',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '請先添加好友並讓他們綁定裝置',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDevices,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _devices.length,
        itemBuilder: (context, index) {
          final device = _devices[index];
          return _buildDeviceCard(device);
        },
      ),
    );
  }

  Widget _buildDeviceCard(Map<String, dynamic> device) {
    final isOnline = device['is_online'] ?? false;
    final deviceName = device['name'] ?? '未命名裝置';
    final friendName = device['friend_username'] ?? '未知用戶';
    final lastActive = device['last_active'];

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 裝置名稱和狀態
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green.shade100 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.watch,
                    color: isOnline ? Colors.green : Colors.grey,
                    size: 28,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deviceName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 4),
                          Text(
                            friendName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 在線狀態指示器
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(20),
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
                      SizedBox(width: 6),
                      Text(
                        isOnline ? '在線' : '離線',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 8),

            // 最後活躍時間
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  '最後活躍: ${_formatLastActive(lastActive)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),

            // 如果在線，顯示額外信息
            if (isOnline) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '裝置目前在線，正在傳送數據',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
