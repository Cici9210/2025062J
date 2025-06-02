// 註冊畫面 (register_screen.dart)
// 功能: 提供使用者註冊介面
// 相依: flutter, provider

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('註冊'),
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 應用標誌
                  Icon(
                    Icons.favorite,
                    size: 80,
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '建立新帳號',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 40),
                  
                  // 註冊表單
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
                            // 電子郵件
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: '電子郵件',
                                prefixIcon: Icon(Icons.email),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.emailAddress,
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
                            SizedBox(height: 16),
                            
                            // 密碼
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: '密碼',
                                prefixIcon: Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(),
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
                            SizedBox(height: 16),
                            
                            // 確認密碼
                            TextFormField(
                              controller: _confirmPasswordController,
                              decoration: InputDecoration(
                                labelText: '確認密碼',
                                prefixIcon: Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(),
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
                            SizedBox(height: 24),
                            
                            // 註冊按鈕
                            Consumer<AuthProvider>(
                              builder: (context, authProvider, child) {
                                return ElevatedButton(
                                  onPressed: authProvider.isLoading ? null : _register,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                                    child: authProvider.isLoading
                                        ? CircularProgressIndicator(color: Colors.white)
                                        : Text('註冊', style: TextStyle(fontSize: 16)),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 16),
                            
                            // 登入連結
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text('已有帳號？點擊登入'),
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
