// 底部導航欄 (bottom_nav_bar.dart)
// 功能: 提供應用底部導航功能
// 相依: flutter

import 'package:flutter/material.dart';
import '../config/ui_constants.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool hasNewMessages;

  const BottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.hasNewMessages = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: UIConstants.spaceM,
            vertical: UIConstants.spaceS,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,          children: [
            _buildNavItem(0, Icons.home_outlined, Icons.home, '首頁'),
            _buildNavItem(1, Icons.message_outlined, Icons.message, '交流', hasNotification: hasNewMessages),
            _buildNavItem(2, Icons.favorite_outline, Icons.favorite, '收藏'),
            _buildNavItem(3, Icons.settings_outlined, Icons.settings, '設定'),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label, {bool hasNotification = false}) {
    final bool isSelected = selectedIndex == index;
    
    return InkWell(
      onTap: () => onItemSelected(index),
      borderRadius: BorderRadius.circular(UIConstants.radiusM),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: UIConstants.spaceM,
          vertical: UIConstants.spaceS,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? filledIcon : outlineIcon,
                  color: isSelected ? UIConstants.primaryColor : Colors.grey,
                  size: 24,
                ),
                if (hasNotification && !isSelected)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: UIConstants.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? UIConstants.primaryColor : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
