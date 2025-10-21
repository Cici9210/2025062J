// 裝置綁定畫面 (bind_device_screen.dart)
// 功能: 允許使用者輸入裝置ID並綁定到帳號
// 相依: flutter, provider

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/device.dart';
import '../../providers/auth_provider.dart';
import '../../services/device_service.dart';
import '../../config/ui_constants.dart';

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
            SnackBar(
              content: Text('裝置綁定成功'),
              backgroundColor: UIConstants.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          // 回到前一頁
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('裝置綁定失敗: $e'),
            backgroundColor: UIConstants.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          '綁定裝置',
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
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: UIConstants.spaceL),
            children: [
              SizedBox(height: UIConstants.spaceXL),
              // 標題文字
              Text(
                '將您的心臟裝置綁定至帳號',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: UIConstants.spaceM),
              Text(
                '綁定裝置後，您可以開始使用心臟互動功能',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: UIConstants.spaceXXL),
              
              // 說明卡片
              Container(
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
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [UIConstants.secondaryColor, UIConstants.primaryColor],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: UIConstants.primaryColor.withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.info_outline,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: UIConstants.spaceL),
                      Text(
                        '如何綁定裝置？',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: UIConstants.textDark,
                        ),
                      ),
                      SizedBox(height: UIConstants.spaceM),
                      Text(
                        '請輸入您的裝置ID，裝置ID通常印在裝置背面或包裝上。'
                        '您也可以在裝置開機時，通過序列埠監視器查看輸出的裝置ID。',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: UIConstants.textMedium,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: UIConstants.spaceL),
                      Container(
                        padding: EdgeInsets.all(UIConstants.spaceM),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(UIConstants.radiusM),
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb,
                              color: Colors.blue.shade700,
                              size: 24,
                            ),
                            SizedBox(width: UIConstants.spaceM),
                            Expanded(
                              child: Text(
                                '裝置ID格式為: ESP32_HEART_XXX，其中XXX為3位數字，例如ESP32_HEART_001',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: UIConstants.spaceXL),
                // 綁定表單
              Container(
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '輸入裝置ID',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: UIConstants.textDark,
                          ),
                        ),
                        SizedBox(height: UIConstants.spaceM),
                        TextFormField(
                          controller: _deviceUidController,
                          decoration: UIConstants.inputDecoration(
                            '裝置ID',
                            prefixIcon: Icons.devices,
                          ).copyWith(
                            hintText: '例如: ESP32_HEART_001',
                            prefixIcon: Container(
                              padding: EdgeInsets.all(UIConstants.spaceS),
                              child: Icon(
                                Icons.devices,
                                color: UIConstants.primaryColor,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(UIConstants.radiusL),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(UIConstants.radiusL),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(UIConstants.radiusL),
                              borderSide: BorderSide(
                                color: UIConstants.primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '請輸入裝置ID';
                            }
                            final regex = RegExp(r'^ESP32_HEART_\d{3}$');
                            if (!regex.hasMatch(value)) {
                              return '請輸入有效的裝置ID格式 (ESP32_HEART_XXX)';
                            }
                            return null;
                          },
                          style: TextStyle(
                            fontSize: 16,
                            color: UIConstants.textDark,
                          ),
                        ),
                        SizedBox(height: UIConstants.spaceXL),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _bindDevice,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: UIConstants.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: UIConstants.primaryColor.withOpacity(0.4),
                            padding: EdgeInsets.symmetric(
                              vertical: UIConstants.spaceL,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(UIConstants.radiusL),
                            ),
                            textStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          child: _isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.0,
                                      ),
                                    ),
                                    SizedBox(width: UIConstants.spaceM),
                                    Text('處理中...'),
                                  ],
                                )
                              : Text('綁定裝置'),
                        ),
                        SizedBox(height: UIConstants.spaceM),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: UIConstants.textMedium,
                          ),
                          child: Text(
                            '取消',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: UIConstants.spaceXL),
            ],
          ),
        ),
      ),
    );
  }
}
