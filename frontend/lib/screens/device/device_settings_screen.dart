// 裝置設定畫面 (device_settings_screen.dart)
// 功能: 管理單一裝置的設定
// 相依: flutter, provider

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/ui_constants.dart';
import '../../models/device.dart';
import '../../providers/auth_provider.dart';
import '../../services/device_service.dart';

class DeviceSettingsScreen extends StatefulWidget {
  final Device device;

  const DeviceSettingsScreen({Key? key, required this.device}) : super(key: key);

  @override
  State<DeviceSettingsScreen> createState() => _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends State<DeviceSettingsScreen> {
  final DeviceService _deviceService = DeviceService();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  String _deviceName = '';

  @override
  void initState() {
    super.initState();
    _deviceName = widget.device.deviceUid;
    _nameController.text = _deviceName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateDeviceName() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('裝置名稱不能為空')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // TODO: 實現後端更新裝置名稱的 API
      await Future.delayed(const Duration(seconds: 1)); // 模擬API調用
      
      setState(() {
        _deviceName = _nameController.text.trim();
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('裝置名稱已更新')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新失敗: $e')),
      );
    }
  }

  Future<void> _unbindDevice() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認解綁'),
        content: Text('確定要解綁裝置「$_deviceName」嗎？此操作無法撤銷。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: UIConstants.errorColor,
            ),
            child: const Text('確認解綁'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        // TODO: 實現後端解綁裝置的 API
        await Future.delayed(const Duration(seconds: 1)); // 模擬API調用
        
        if (mounted) {
          Navigator.pop(context, true); // 返回並刷新裝置列表
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('裝置已解綁')),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('解綁失敗: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('裝置設定'),
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
        child: ListView(
          padding: EdgeInsets.all(UIConstants.spaceL),
          children: [
            // 裝置資訊卡片
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(UIConstants.radiusL),
              ),
              child: Padding(
                padding: EdgeInsets.all(UIConstants.spaceL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [UIConstants.primaryColor, UIConstants.secondaryColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        SizedBox(width: UIConstants.spaceL),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _deviceName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: UIConstants.spaceXS),
                              Text(
                                'ID: ${widget.device.id}',
                                style: TextStyle(
                                  color: UIConstants.textMedium,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: UIConstants.spaceXS),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: widget.device.isConnected 
                                          ? UIConstants.successColor 
                                          : Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: UIConstants.spaceXS),
                                  Text(
                                    widget.device.isConnected ? '已連接' : '離線',
                                    style: TextStyle(
                                      color: widget.device.isConnected 
                                          ? UIConstants.successColor 
                                          : Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: UIConstants.spaceXL),

            // 裝置名稱設定
            Card(
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
                      '裝置名稱',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: UIConstants.textDark,
                      ),
                    ),
                    SizedBox(height: UIConstants.spaceM),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: '輸入裝置名稱',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(UIConstants.radiusM),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.all(UIConstants.spaceM),
                      ),
                      enabled: !_isLoading,
                    ),
                    SizedBox(height: UIConstants.spaceM),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateDeviceName,
                        style: UIConstants.primaryButtonStyle,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('儲存'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: UIConstants.spaceXL),

            // 危險區域
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(UIConstants.radiusL),
              ),
              color: UIConstants.errorColor.withOpacity(0.05),
              child: Padding(
                padding: EdgeInsets.all(UIConstants.spaceL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: UIConstants.errorColor,
                        ),
                        SizedBox(width: UIConstants.spaceM),
                        Text(
                          '危險區域',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: UIConstants.errorColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: UIConstants.spaceM),
                    Text(
                      '解綁裝置後，您將無法再使用此裝置進行互動。此操作無法撤銷。',
                      style: TextStyle(
                        color: UIConstants.textMedium,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: UIConstants.spaceM),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _unbindDevice,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('解綁裝置'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: UIConstants.errorColor,
                          side: BorderSide(color: UIConstants.errorColor),
                          padding: EdgeInsets.all(UIConstants.spaceM),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(UIConstants.radiusM),
                          ),
                        ),
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
