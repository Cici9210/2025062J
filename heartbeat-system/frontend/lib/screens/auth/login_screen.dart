// 登入畫面 (login_screen.dart)
// 功能: 提供使用者登入介面
// 相依: flutter, provider

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/ui_constants.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.login(_emailController.text, _passwordController.text);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登入失敗: $e')),
        );      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: UIConstants.backgroundGradient,
          ),
        ),        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(UIConstants.spaceL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 應用標誌 (Figma設計)
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: UIConstants.primaryColor.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.favorite,
                        size: 90,
                        color: UIConstants.heartColor,
                      ),
                    ),
                  ),
                  SizedBox(height: UIConstants.spaceL),
                  Text(
                    '心臟壓感互動系統',
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
                    '連結心跳，感受彼此',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: UIConstants.spaceXXL),
                  
                  // 登入表單 (Figma設計)
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
                    ),                    child: Padding(
                      padding: EdgeInsets.all(UIConstants.spaceXL),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '歡迎回來',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: UIConstants.textDark,
                                letterSpacing: 1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              '請登入您的帳戶',
                              style: TextStyle(
                                fontSize: 16,
                                color: UIConstants.textMedium,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: UIConstants.spaceXL),
                            
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
                              ).copyWith(
                                suffixIcon: IconButton(
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
                              ),                              obscureText: !_isPasswordVisible,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '請輸入密碼';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: UIConstants.spaceS),
                            
                            // 忘記密碼
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  // 忘記密碼處理
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('忘記密碼功能尚未實現')),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  '忘記密碼？',
                                  style: TextStyle(
                                    color: UIConstants.textMedium,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: UIConstants.spaceXL),
                            
                            // 登入按鈕
                            Consumer<AuthProvider>(
                              builder: (context, authProvider, child) {
                                return ElevatedButton(
                                  onPressed: authProvider.isLoading ? null : _login,
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
                                  child: authProvider.isLoading
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        '登入',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                );
                              },
                            ),
                            SizedBox(height: UIConstants.spaceXL),
                            
                            // 註冊連結
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '還沒有帳號？', 
                                  style: TextStyle(color: UIConstants.textMedium)
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => RegisterScreen()),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  child: Text(
                                    '立即註冊',
                                    style: TextStyle(
                                      color: UIConstants.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),                                  ),
                                ),
                              ],
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
