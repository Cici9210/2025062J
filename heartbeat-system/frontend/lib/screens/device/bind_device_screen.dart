"""
裝置綁定畫面 (bind_device_screen.dart)
功能: 允許使用者輸入裝置ID並綁定到帳號
相依: flutter, provider
"""
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/device.dart';
import '../../providers/auth_provider.dart';
import '../../services/device_service.dart';

class BindDeviceScreen extends StatefulWidget {
  const BindDeviceScreen({Key? key}) : super(key: key);

  @override
  State<BindDeviceScreen> createState() => _BindDeviceScreenState();
}

class _BindDeviceScreenState extends State<BindDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deviceUidController = TextEditingController();
  final DeviceService _deviceService = DeviceService();
  bool _isLoading = false;
  
  @override
  void dispose() {
    _deviceUidController.dispose();
    super.dispose();
  }
  
  Future<void> _bindDevice() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.token != null) {
          final device = await _deviceService.bindDevice(
            authProvider.token!,
            _deviceUidController.text,
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('裝置綁定成功')),
          );
          
          // 回到前一頁
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('裝置綁定失敗: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('綁定裝置'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF9A8B), Color(0xFFFF6B6B)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 說明卡片
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 40,
                          color: Theme.of(context).primaryColor,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '如何綁定裝置？',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '請輸入您的裝置ID，裝置ID通常印在裝置背面或包裝上。'
                          '您也可以在裝置開機時，通過序列埠監視器查看輸出的裝置ID。',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                
                // 綁定表單
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _deviceUidController,
                            decoration: InputDecoration(
                              labelText: '裝置ID',
                              hintText: '例如: ESP32_HEART_001',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.devices),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '請輸入裝置ID';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _bindDevice,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: _isLoading
                                  ? CircularProgressIndicator(color: Colors.white)
                                  : Text('綁定裝置', style: TextStyle(fontSize: 16)),
                            ),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
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
          ),
        ),
      ),
    );
  }
}
