// 心臟互動畫面 (heart_interaction_screen.dart)
// 功能: 提供心臟互動主介面
// 相依: flutter, provider

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class _HeartInteractionScreenState extends State<HeartInteractionScreen> {
  @override
  void initState() {
    super.initState();
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
          SnackBar(content: Text('隨機配對成功')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('配對失敗: $e')),
        );
      }
    }
  }
  
  void _endPairing() {
    final interactionProvider = Provider.of<InteractionProvider>(context, listen: false);
    interactionProvider.endPairing();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已結束配對')),
    );
  }
  
  @override
  void dispose() {
    // 關閉WebSocket連接
    final interactionProvider = Provider.of<InteractionProvider>(context, listen: false);
    interactionProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InteractionProvider>(
      builder: (context, interactionProvider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('心臟互動'),
            actions: [
              // 配對狀態指示
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Chip(
                  label: Text(
                    interactionProvider.isPaired ? '已配對' : '未配對',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: interactionProvider.isPaired
                      ? Colors.green
                      : Colors.grey,
                ),
              ),
            ],
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
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 我的心臟視覺效果
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                const Text(
                                  '我的心臟',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                HeartAnimation(
                                  size: 150,
                                  color: Colors.red.shade800,
                                  pulseRate: 0.5 + (interactionProvider.localPressure * 1.5),
                                  isActive: true,
                                ),
                              ],
                            ),
                          ),
                          
                          // 配對的心臟視覺效果 (僅在配對狀態下顯示)
                          if (interactionProvider.isPaired)
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  const Text(
                                    '配對的心臟',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  HeartAnimation(
                                    size: 150,
                                    color: Colors.pink.shade400,
                                    pulseRate: 0.5 + (interactionProvider.remotePressure * 1.5),
                                    isActive: interactionProvider.remotePressure > 0.1,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // 配對按鈕
                  if (!interactionProvider.isPaired)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: ElevatedButton(
                        onPressed: _requestRandomPairing,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.favorite),
                              SizedBox(width: 8),
                              Text('隨機配對'),
                            ],
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Theme.of(context).primaryColor,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: ElevatedButton(
                        onPressed: _endPairing,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.heart_broken),
                              SizedBox(width: 8),
                              Text('結束配對'),
                            ],
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                  
                  // 壓力視覺化介面
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: PressureVisualizer(
                      onPressureChanged: _onPressureChanged,
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
