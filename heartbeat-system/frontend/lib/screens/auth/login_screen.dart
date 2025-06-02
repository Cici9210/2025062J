// 登入畫面 (login_screen.dart)
// 功能: 提供使用者登入介面
// 相依: flutter, provider

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    '心臟壓感互動系統',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 40),
                  
                  // 登入表單
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
                            Text(
                              '登入',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 24),
                            
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
                                return null;
                              },
                            ),
                            SizedBox(height: 24),
                            
                            // 登入按鈕
                            Consumer<AuthProvider>(
                              builder: (context, authProvider, child) {
                                return ElevatedButton(
                                  onPressed: authProvider.isLoading ? null : _login,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                                    child: authProvider.isLoading
                                        ? CircularProgressIndicator(color: Colors.white)
                                        : Text('登入', style: TextStyle(fontSize: 16)),
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
                            
                            // 註冊連結
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => RegisterScreen()),
                                );
                              },
                              child: Text('還沒有帳號？點擊註冊'),
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
