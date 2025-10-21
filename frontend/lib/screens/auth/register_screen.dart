// 註冊畫面 (register_screen.dart)
// 功能: 提供使用者註冊介面
// 相依: flutter, provider

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/ui_constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  
  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() {});  // 密碼改變時重新渲染以更新密碼強度指示器
    });
  }
  
  // 獲取密碼強度顏色
  Color _getPasswordStrengthColor() {
    if (_passwordController.text.isEmpty) {
      return Colors.grey;
    } else if (_passwordController.text.length < 6) {
      return UIConstants.errorColor;
    } else if (_passwordController.text.length < 8) {
      return UIConstants.warningColor;
    } else {
      return UIConstants.successColor;
    }
  }
  
  // 獲取密碼強度文字
  String _getPasswordStrengthText() {
    if (_passwordController.text.isEmpty) {
      return '請輸入密碼';
    } else if (_passwordController.text.length < 6) {
      return '密碼強度: 弱';
    } else if (_passwordController.text.length < 8) {
      return '密碼強度: 中';
    } else {
      return '密碼強度: 強';
    }
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.register(_emailController.text, _passwordController.text);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('註冊失敗: $e')),
        );
      }
    }
  }  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.transparent,
        foregroundColor: UIConstants.textLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: UIConstants.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(UIConstants.spaceL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 應用標誌 (Figma設計)
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: UIConstants.primaryColor.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.favorite,
                      size: 70,
                      color: UIConstants.heartColor,                    ),
                  ),
                  SizedBox(height: UIConstants.spaceM),
                  Text(
                    '建立新帳號',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '開始您的心跳互動之旅',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: UIConstants.spaceXL),
                  
                  // 註冊表單 (Figma設計)
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(UIConstants.radiusL),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          spreadRadius: 0,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(UIConstants.spaceXL),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 電子郵件
                            TextFormField(
                              controller: _emailController,
                              decoration: UIConstants.inputDecoration(
                                '電子郵件', 
                                prefixIcon: Icons.email,
                                hintText: '請輸入您的電子郵件'
                              ),
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(fontSize: 16),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '請輸入電子郵件';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return '請輸入有效的電子郵件地址';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: UIConstants.spaceM),
                            
                            // 密碼
                            TextFormField(
                              controller: _passwordController,
                              style: TextStyle(fontSize: 16),
                              decoration: UIConstants.inputDecoration(
                                '密碼', 
                                prefixIcon: Icons.lock,
                                hintText: '請輸入您的密碼'
                              ).copyWith(                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                    color: UIConstants.textMedium,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              obscureText: !_isPasswordVisible,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '請輸入密碼';
                                }
                                if (value.length < 6) {
                                  return '密碼至少需要6個字符';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: UIConstants.spaceM),
                            
                            // 密碼強度指示器
                            LinearProgressIndicator(
                              value: _passwordController.text.isEmpty 
                                  ? 0 
                                  : (_passwordController.text.length > 10 ? 1 : _passwordController.text.length / 10),
                              backgroundColor: Colors.grey.shade200,
                              color: _getPasswordStrengthColor(),
                              minHeight: 4,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                _getPasswordStrengthText(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getPasswordStrengthColor(),
                                ),
                              ),
                            ),
                            SizedBox(height: UIConstants.spaceM),
                              // 確認密碼
                            TextFormField(
                              controller: _confirmPasswordController,
                              style: TextStyle(fontSize: 16),
                              decoration: UIConstants.inputDecoration(
                                '確認密碼',
                                prefixIcon: Icons.lock_outline,
                                hintText: '請再次輸入密碼'
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                    color: UIConstants.textMedium,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                    });
                                  },
                                ),
                              ),                              
                              obscureText: !_isConfirmPasswordVisible,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '請確認密碼';
                                }
                                if (value != _passwordController.text) {
                                  return '密碼不匹配';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: UIConstants.spaceXL),
                            
                            // 同意條款
                            Row(
                              children: [
                                Checkbox(
                                  value: true,
                                  activeColor: UIConstants.primaryColor,
                                  onChanged: (value) {
                                    // 可以添加實際的同意條款功能
                                  },
                                ),
                                Expanded(
                                  child: Text(
                                    '我同意使用條款和隱私政策',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: UIConstants.textMedium,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            SizedBox(height: UIConstants.spaceL),
                            
                            // 註冊按鈕
                            Consumer<AuthProvider>(
                              builder: (context, authProvider, child) {
                                return ElevatedButton(
                                  onPressed: authProvider.isLoading ? null : _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: UIConstants.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(UIConstants.radiusL),
                                    ),
                                    elevation: 4,
                                    shadowColor: UIConstants.primaryColor.withOpacity(0.4),
                                  ),
                                  child: authProvider.isLoading                                      ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                              strokeWidth: 2.0,
                                            ),
                                          )
                                        : Text(
                                            '建立帳號',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 1,
                                            ),                            ),
                                );
                              },
                            ),
                            
                            SizedBox(height: UIConstants.spaceL),
                            
                            // 返回登入
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '已有帳號？', 
                                  style: TextStyle(color: UIConstants.textMedium)
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  child: Text(
                                    '立即登入',
                                    style: TextStyle(
                                      color: UIConstants.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            // 登入連結
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: UIConstants.textButtonStyle,
                              child: Text(
                                '已有帳號？點擊登入',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
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
      ),
    );
  }
}
