// 統計畫面 (statistics_screen.dart)
// 功能: 顯示用戶的互動統計數據
// 相依: flutter, provider, fl_chart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/ui_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/device_service.dart';
import '../../models/device.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final DeviceService _deviceService = DeviceService();
  bool _isLoading = true;
  int _totalInteractions = 0;
  int _totalDevices = 0;
  int _activeFriends = 0;
  List<Device> _devices = [];

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.token != null) {
        // 獲取設備資訊
        final devices = await _deviceService.getUserDevices(authProvider.token!);
        
        setState(() {
          _devices = devices;
          _totalDevices = devices.length;
          _totalInteractions = 0; // TODO: 從後端獲取實際互動次數
          _activeFriends = 0; // TODO: 從後端獲取實際好友數
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('載入統計數據失敗: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '統計',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadStatistics,
                child: ListView(
                  padding: EdgeInsets.all(UIConstants.spaceL),
                  children: [
                    // 統計卡片網格
                    _buildStatisticsGrid(),
                    
                    SizedBox(height: UIConstants.spaceXL),
                    
                    // 裝置狀態
                    _buildDeviceStatusCard(),
                    
                    SizedBox(height: UIConstants.spaceXL),
                    
                    // 最近活動（暫時顯示佔位符）
                    _buildRecentActivityCard(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: UIConstants.spaceM,
      mainAxisSpacing: UIConstants.spaceM,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          '互動次數',
          _totalInteractions.toString(),
          Icons.favorite,
          UIConstants.heartColor,
        ),
        _buildStatCard(
          '已綁定裝置',
          _totalDevices.toString(),
          Icons.devices,
          UIConstants.primaryColor,
        ),
        _buildStatCard(
          '活躍好友',
          _activeFriends.toString(),
          Icons.people,
          UIConstants.secondaryColor,
        ),
        _buildStatCard(
          '在線裝置',
          _devices.where((d) => d.isConnected).length.toString(),
          Icons.wifi,
          UIConstants.successColor,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.radiusL),
      ),
      child: Container(
        padding: EdgeInsets.all(UIConstants.spaceM),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(UIConstants.radiusL),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            SizedBox(height: UIConstants.spaceS),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: UIConstants.spaceXS),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: UIConstants.textMedium,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.radiusL),
      ),
      child: Padding(
        padding: EdgeInsets.all(UIConstants.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '裝置狀態',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: UIConstants.textDark,
              ),
            ),
            SizedBox(height: UIConstants.spaceM),
            if (_devices.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(UIConstants.spaceXL),
                  child: Column(
                    children: [
                      Icon(
                        Icons.devices_other,
                        size: 48,
                        color: Colors.grey.shade300,
                      ),
                      SizedBox(height: UIConstants.spaceM),
                      Text(
                        '尚未綁定任何裝置',
                        style: TextStyle(
                          color: UIConstants.textMedium,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._devices.map((device) => Padding(
                padding: EdgeInsets.only(bottom: UIConstants.spaceM),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: device.isConnected 
                            ? UIConstants.successColor.withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(UIConstants.radiusM),
                      ),
                      child: Icon(
                        Icons.favorite,
                        color: device.isConnected 
                            ? UIConstants.successColor
                            : Colors.grey,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: UIConstants.spaceM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.deviceUid,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'ID: ${device.id}',
                            style: TextStyle(
                              color: UIConstants.textMedium,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: UIConstants.spaceM,
                        vertical: UIConstants.spaceXS,
                      ),
                      decoration: BoxDecoration(
                        color: device.isConnected 
                            ? UIConstants.successColor.withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(UIConstants.radiusL),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: device.isConnected 
                                  ? UIConstants.successColor
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: UIConstants.spaceXS),
                          Text(
                            device.isConnected ? '在線' : '離線',
                            style: TextStyle(
                              color: device.isConnected 
                                  ? UIConstants.successColor
                                  : Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.radiusL),
      ),
      child: Padding(
        padding: EdgeInsets.all(UIConstants.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '最近活動',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: UIConstants.textDark,
              ),
            ),
            SizedBox(height: UIConstants.spaceM),
            Center(
              child: Padding(
                padding: EdgeInsets.all(UIConstants.spaceXL),
                child: Column(
                  children: [
                    Icon(
                      Icons.history,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    SizedBox(height: UIConstants.spaceM),
                    Text(
                      '暫無互動記錄',
                      style: TextStyle(
                        color: UIConstants.textMedium,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: UIConstants.spaceS),
                    Text(
                      '開始使用裝置與好友互動吧！',
                      style: TextStyle(
                        color: UIConstants.textMedium,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
