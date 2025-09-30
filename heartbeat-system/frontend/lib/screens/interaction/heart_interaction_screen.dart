// 心臟互動畫面 (heart_interaction_screen.dart)
// 功能: 提供心臟互動主介面
// 相依: flutter, provider

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/ui_constants.dart';
import '../../models/device.dart';
import '../../providers/interaction_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/heart_animation.dart';
import '../../widgets/pressure_visualizer.dart';

class HeartInteractionScreen extends StatefulWidget {
  final Device device;
  
  const HeartInteractionScreen({Key? key, required this.device}) : super(key: key);

  @override
  State<HeartInteractionScreen> createState() => _HeartInteractionScreenState();
}

class _HeartInteractionScreenState extends State<HeartInteractionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // 初始化動畫控制器
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );
    
    // 啟動動畫
    _controller.forward();
    
    // 初始化WebSocket連接
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final interactionProvider = Provider.of<InteractionProvider>(context, listen: false);
      
      if (authProvider.token != null) {
        interactionProvider.initializeWebSocket(
          widget.device.deviceUid,
          authProvider.token!,
        );
      }
    });
  }
  
  void _onPressureChanged(double pressure) {
    final interactionProvider = Provider.of<InteractionProvider>(context, listen: false);
    interactionProvider.updatePressure(pressure);
  }
  
  void _requestRandomPairing() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final interactionProvider = Provider.of<InteractionProvider>(context, listen: false);
    
    if (authProvider.token != null) {
      try {
        await interactionProvider.randomPairing(authProvider.token!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('隨機配對成功'),
            backgroundColor: UIConstants.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('配對失敗: $e'),
            backgroundColor: UIConstants.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  void _endPairing() {
    final interactionProvider = Provider.of<InteractionProvider>(context, listen: false);
    interactionProvider.endPairing();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已結束配對'),
        backgroundColor: UIConstants.warningColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  @override
  void dispose() {
    // 關閉WebSocket連接
    final interactionProvider = Provider.of<InteractionProvider>(context, listen: false);
    interactionProvider.dispose();
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<InteractionProvider>(
      builder: (context, interactionProvider, _) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text(
              '心臟互動',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 0.5,
              ),
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: UIConstants.textLight,
            elevation: 0,
            actions: [
              // 配對狀態指示
              Padding(
                padding: EdgeInsets.all(UIConstants.spaceS),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: UIConstants.spaceM,
                    vertical: UIConstants.spaceXS,
                  ),
                  decoration: BoxDecoration(
                    color: interactionProvider.isPaired
                        ? UIConstants.successColor
                        : Colors.grey.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(UIConstants.radiusL),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: UIConstants.spaceXS),
                      Text(
                        interactionProvider.isPaired ? '已配對' : '未配對',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
                padding: EdgeInsets.only(
                  top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top,
                ),
                children: [
                  // 裝置資訊
                  Padding(
                    padding: EdgeInsets.all(UIConstants.spaceL),
                    child: Container(
                      padding: EdgeInsets.all(UIConstants.spaceM),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(UIConstants.radiusL),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.devices,
                            color: Colors.white,
                          ),
                          SizedBox(width: UIConstants.spaceM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '裝置: ${widget.device.deviceUid}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'ID: ${widget.device.id}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: UIConstants.spaceM,
                              vertical: UIConstants.spaceXS,
                            ),
                            decoration: BoxDecoration(
                              color: UIConstants.successColor,
                              borderRadius: BorderRadius.circular(UIConstants.radiusL),
                            ),
                            child: Text(
                              '已連接',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // 我的心臟視覺效果
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: EdgeInsets.all(UIConstants.spaceXL),
                      margin: EdgeInsets.symmetric(horizontal: UIConstants.spaceL),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(UIConstants.radiusXL),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: UIConstants.spaceL,
                              vertical: UIConstants.spaceS,
                            ),
                            decoration: BoxDecoration(
                              color: UIConstants.primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(UIConstants.radiusL),
                            ),
                            child: Text(
                              '我的心臟',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: UIConstants.spaceL),
                          Container(
                            padding: EdgeInsets.all(UIConstants.spaceL),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: UIConstants.heartColor.withOpacity(0.3),
                                  blurRadius: 25,
                                  spreadRadius: interactionProvider.localPressure * 20,
                                ),
                              ],
                            ),
                            child: HeartAnimation(
                              size: 180,
                              color: UIConstants.heartColor,
                              pulseRate: 0.5 + (interactionProvider.localPressure * 1.5),
                              isActive: true,
                            ),
                          ),
                          SizedBox(height: UIConstants.spaceM),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: UIConstants.spaceL,
                              vertical: UIConstants.spaceS,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(UIConstants.radiusL),
                            ),
                            child: Text(
                              interactionProvider.localPressure > 0.1 
                                  ? '心臟跳動中...' 
                                  : '輕按以表達心意',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                    
                  SizedBox(height: UIConstants.spaceL),
                  
                  // 配對的心臟視覺效果 (僅在配對狀態下顯示)
                  if (interactionProvider.isPaired)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: UIConstants.spaceL),
                      child: Container(
                        padding: EdgeInsets.all(UIConstants.spaceXL),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(UIConstants.radiusXL),
                          border: Border.all(
                            color: UIConstants.pairHeartColor.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: UIConstants.spaceL,
                                vertical: UIConstants.spaceS,
                              ),
                              decoration: BoxDecoration(
                                color: UIConstants.secondaryColor.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(UIConstants.radiusL),
                              ),
                              child: Text(
                                '配對的心臟',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: UIConstants.spaceL),
                            Container(
                              padding: EdgeInsets.all(UIConstants.spaceL),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: UIConstants.pairHeartColor.withOpacity(0.3),
                                    blurRadius: 25,
                                    spreadRadius: interactionProvider.remotePressure * 20,
                                  ),
                                ],
                              ),
                              child: HeartAnimation(
                                size: 180,
                                color: UIConstants.pairHeartColor,
                                pulseRate: 0.5 + (interactionProvider.remotePressure * 1.5),
                                isActive: interactionProvider.remotePressure > 0.1,
                              ),
                            ),
                            SizedBox(height: UIConstants.spaceM),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: UIConstants.spaceL,
                                vertical: UIConstants.spaceS,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(UIConstants.radiusL),
                              ),
                              child: Text(
                                interactionProvider.remotePressure > 0.1 
                                    ? '感受對方的心意...' 
                                    : '等待對方傳遞心意',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                  SizedBox(height: UIConstants.spaceL),
                  
                  // 配對按鈕
                  Padding(
                    padding: EdgeInsets.all(UIConstants.spaceL),
                    child: !interactionProvider.isPaired
                        ? ElevatedButton.icon(
                            onPressed: _requestRandomPairing,
                            icon: Icon(Icons.favorite_border, size: 24),
                            label: Text(
                              '隨機配對',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: UIConstants.primaryColor,
                              elevation: 8,
                              shadowColor: UIConstants.primaryColor.withOpacity(0.4),
                              padding: EdgeInsets.symmetric(vertical: UIConstants.spaceL),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(UIConstants.radiusL),
                              ),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: _endPairing,
                            icon: Icon(Icons.heart_broken, size: 24),
                            label: Text(
                              '結束配對',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: UIConstants.errorColor,
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shadowColor: UIConstants.errorColor.withOpacity(0.4),
                              padding: EdgeInsets.symmetric(vertical: UIConstants.spaceL),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(UIConstants.radiusL),
                              ),
                            ),
                          ),
                  ),
                  
                  // 壓力視覺化介面
                  Padding(
                    padding: EdgeInsets.all(UIConstants.spaceL),
                    child: Container(
                      padding: EdgeInsets.all(UIConstants.spaceL),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '調整心意強度',
                            style: TextStyle(
                              color: UIConstants.textDark,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: UIConstants.spaceS),
                          Text(
                            '輕按或長按以表達不同程度的心意',
                            style: TextStyle(
                              color: UIConstants.textMedium,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: UIConstants.spaceL),
                          PressureVisualizer(
                            onPressureChanged: _onPressureChanged,
                          ),
                          SizedBox(height: UIConstants.spaceM),
                          Center(
                            child: Text(
                              '目前強度: ${(interactionProvider.localPressure * 100).round()}%',
                              style: TextStyle(
                                color: UIConstants.primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
          ),
        );
      },
    );
  }
}
