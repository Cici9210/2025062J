//壓力視覺化元件 (pressure_visualizer.dart)
//功能: 提供使用者互動的壓力視覺化介面
//相依: flutter, ui_constants

import 'package:flutter/material.dart';
import 'dart:math' show sin, pi;
import '../config/ui_constants.dart';

class PressureVisualizer extends StatefulWidget {
  final Function(double) onPressureChanged;
  
  const PressureVisualizer({
    Key? key,
    required this.onPressureChanged,
  }) : super(key: key);

  @override
  State<PressureVisualizer> createState() => _PressureVisualizerState();
}

class _PressureVisualizerState extends State<PressureVisualizer> with SingleTickerProviderStateMixin {
  double _pressure = 0.0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    // 初始化脈動動畫
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
  
  void _updatePressure(double value) {
    setState(() {
      _pressure = value;
    });
    widget.onPressureChanged(value);
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 壓力指示條
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            // 根據脈動動畫調整發光效果
            double glowIntensity = _pressure > 0.3 ? 
                _pressure * (_pulseAnimation.value * 0.3 + 0.7) : _pressure;
            
            return Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(UIConstants.radiusL),
                gradient: LinearGradient(
                  colors: [
                    UIConstants.secondaryColor.withOpacity(0.5),
                    UIConstants.primaryColor.withOpacity(0.7),
                    UIConstants.heartColor.withOpacity(0.9),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: UIConstants.heartColor.withOpacity(glowIntensity * 0.5),
                    blurRadius: 12 * glowIntensity,
                    spreadRadius: 2 * glowIntensity,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(UIConstants.radiusL),
                child: Stack(
                  children: [
                    // 背景框
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    // 進度條
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: MediaQuery.of(context).size.width * _pressure * 0.7, // 考慮邊距
                        height: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.5),
                              Colors.white.withOpacity(0.2)
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    // 波紋效果
                    if (_pressure > 0.1)
                      Positioned.fill(
                        child: AnimatedOpacity(
                          opacity: glowIntensity,
                          duration: const Duration(milliseconds: 300),
                          child: CustomPaint(
                            painter: RipplePainter(
                              progress: _pulseAnimation.value,
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                        ),
                      ),
                    // 壓力百分比
                    Center(
                      child: Text(
                        '${(_pressure * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 2,
                              color: Colors.black26,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        SizedBox(height: UIConstants.spaceL),
        
        // 壓力滑桿
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: UIConstants.heartColor,
            inactiveTrackColor: Colors.grey.shade200,
            thumbColor: Colors.white,
            overlayColor: UIConstants.heartColor.withOpacity(0.3),
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: 12,
              elevation: 4,
              pressedElevation: 8,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
            trackHeight: 8,
          ),
          child: Slider(
            value: _pressure,
            onChanged: _updatePressure,
            min: 0.0,
            max: 1.0,
            divisions: 100,
          ),
        ),
      ],
    );
  }
}

// 波紋效果繪製器
class RipplePainter extends CustomPainter {
  final double progress;
  final Color color;
  
  RipplePainter({required this.progress, required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    // 繪製多層波紋
    for (int i = 0; i < 3; i++) {
      double phase = (progress + i * 0.3) % 1.0;
      double opacity = (1.0 - phase) * 0.3;
      
      Paint paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      double waveWidth = size.width * 0.1;
      double amplitude = size.height * 0.1;
      
      Path path = Path();
      path.moveTo(0, size.height / 2);
      
      for (double x = 0; x < size.width; x += 1) {
        double y = size.height / 2 + 
            sin((x / waveWidth) + (phase * 10) * pi) * amplitude;
        path.lineTo(x, y);
      }
      
      canvas.drawPath(path, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
