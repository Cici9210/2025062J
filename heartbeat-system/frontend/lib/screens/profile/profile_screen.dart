// 個人資料畫面 (profile_screen.dart)
// 功能: 顯示和編輯用戶個人資料
// 相依: flutter, provider

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/ui_constants.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isChangingPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('新密碼與確認密碼不符')),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('密碼長度至少需要6個字元')),
      );
      return;
    }

    setState(() {
      _isChangingPassword = true;
    });

    try {
      // TODO: 實現修改密碼 API
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _isChangingPassword = false;
      });

      _passwordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('密碼已更新')),
      );
    } catch (e) {
      setState(() {
        _isChangingPassword = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('修改密碼失敗: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '個人資料',
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
        child: ListView(
          padding: EdgeInsets.all(UIConstants.spaceL),
          children: [
            // 用戶頭像和基本信息
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(UIConstants.radiusL),
              ),
              child: Padding(
                padding: EdgeInsets.all(UIConstants.spaceXL),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
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
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 5),
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
                      authProvider.user?.email ?? '未知用戶',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: UIConstants.spaceS),
                    Text(
                      'ID: ${authProvider.user?.id ?? '---'}',
                      style: TextStyle(
                        color: UIConstants.textMedium,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: UIConstants.spaceXL),

            // 修改密碼區域
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
                      '修改密碼',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: UIConstants.textDark,
                      ),
                    ),
                    SizedBox(height: UIConstants.spaceL),
                    
                    // 當前密碼
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscureCurrentPassword,
                      decoration: InputDecoration(
                        labelText: '當前密碼',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrentPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureCurrentPassword = !_obscureCurrentPassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(UIConstants.radiusM),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      enabled: !_isChangingPassword,
                    ),
                    
                    SizedBox(height: UIConstants.spaceM),
                    
                    // 新密碼
                    TextField(
                      controller: _newPasswordController,
                      obscureText: _obscureNewPassword,
                      decoration: InputDecoration(
                        labelText: '新密碼',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNewPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureNewPassword = !_obscureNewPassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(UIConstants.radiusM),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      enabled: !_isChangingPassword,
                    ),
                    
                    SizedBox(height: UIConstants.spaceM),
                    
                    // 確認新密碼
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: '確認新密碼',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(UIConstants.radiusM),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      enabled: !_isChangingPassword,
                    ),
                    
                    SizedBox(height: UIConstants.spaceL),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isChangingPassword ? null : _changePassword,
                        style: UIConstants.primaryButtonStyle,
                        child: _isChangingPassword
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('更新密碼'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: UIConstants.spaceXL),

            // 帳戶信息
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
                      '帳戶信息',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: UIConstants.textDark,
                      ),
                    ),
                    SizedBox(height: UIConstants.spaceL),
                    _buildInfoRow('Email', authProvider.user?.email ?? '---'),
                    Divider(height: UIConstants.spaceL * 2),
                    _buildInfoRow(
                      '註冊時間',
                      authProvider.user?.createdAt != null
                          ? '${authProvider.user!.createdAt.year}/${authProvider.user!.createdAt.month}/${authProvider.user!.createdAt.day}'
                          : '---',
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: UIConstants.spaceXL),

            // 登出按鈕
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('確認登出'),
                      content: const Text('確定要登出嗎？'),
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
                          child: const Text('確認登出'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && mounted) {
                    await authProvider.logout();
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('登出'),
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

            SizedBox(height: UIConstants.spaceL),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: UIConstants.spaceXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: UIConstants.textMedium,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
