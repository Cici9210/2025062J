// 設定畫面 (settings_screen.dart)
// 功能: 提供用戶個人設定和應用設定
// 相依: flutter, provider

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/ui_constants.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: UIConstants.primaryColor,
      ),
      body: ListView(
        children: [
          // 用戶資料區塊
          if (user != null)
            Container(
              padding: const EdgeInsets.all(UIConstants.spaceL),
              color: UIConstants.primaryColor.withOpacity(0.05),
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: UIConstants.primaryColor,
                    radius: 40,
                    child: Text(
                      user.email.isNotEmpty ? user.email[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: UIConstants.spaceM),
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: UIConstants.spaceS),
                  Text(
                    'ID: ${user.id}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          
          // 設定選項
          const SizedBox(height: UIConstants.spaceM),
          _buildSettingSection('帳號設定'),
          _buildSettingItem(Icons.person_outline, '個人資料', () {
            // 導航到個人資料頁面
          }),
          _buildSettingItem(Icons.notifications_outlined, '通知設定', () {
            // 導航到通知設定頁面
          }),
          _buildSettingItem(Icons.lock_outline, '隱私與安全', () {
            // 導航到隱私設定頁面
          }),
          
          const SizedBox(height: UIConstants.spaceM),
          _buildSettingSection('裝置設定'),
          _buildSettingItem(Icons.devices_outlined, '管理已綁定裝置', () {
            // 導航到裝置管理頁面
          }),
          _buildSettingItem(Icons.bluetooth_outlined, '藍牙設定', () {
            // 導航到藍牙設定頁面
          }),
          
          const SizedBox(height: UIConstants.spaceM),
          _buildSettingSection('應用設定'),
          _buildSettingItem(Icons.language_outlined, '語言', () {
            // 導航到語言設定頁面
          }),
          _buildSettingItem(Icons.color_lens_outlined, '主題', () {
            // 導航到主題設定頁面
          }),
          
          const SizedBox(height: UIConstants.spaceM),
          _buildSettingSection('關於'),
          _buildSettingItem(Icons.info_outline, '關於應用', () {
            // 顯示關於對話框
          }),
          _buildSettingItem(Icons.help_outline, '幫助與支援', () {
            // 導航到幫助頁面
          }),
          _buildSettingItem(Icons.policy_outlined, '隱私政策', () {
            // 導航到隱私政策頁面
          }),
          
          // 登出按鈕
          const SizedBox(height: UIConstants.spaceXL),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: UIConstants.spaceL),
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('登出'),
                    content: const Text('確定要登出嗎？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          authProvider.logout();
                        },
                        child: const Text('確定'),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(vertical: UIConstants.spaceM),
              ),
              child: const Text(
                '登出',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: UIConstants.spaceXL),
        ],
      ),
    );
  }

  Widget _buildSettingSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spaceL,
        vertical: UIConstants.spaceS,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: UIConstants.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: UIConstants.spaceL,
          vertical: UIConstants.spaceM,
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade700),
            const SizedBox(width: UIConstants.spaceL),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
