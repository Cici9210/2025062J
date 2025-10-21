// 心臟動畫元件 (heart_animation.dart)
// 功能: 提供心臟脈動視覺效果
// 相依: flutter, ui_constants

import 'package:flutter/material.dart';
import '../config/ui_constants.dart';

class HeartAnimation extends StatefulWidget {
  final double size;
  final Color color;
  final double pulseRate; // 脈動速率 (0.0-2.0)
  final bool isActive;
  
  const HeartAnimation({
    Key? key,
    this.size = 200,
    this.color = Colors.red,
    this.pulseRate = 1.0,
    this.isActive = true,
  }) : super(key: key);

  @override
  State<HeartAnimation> createState() => _HeartAnimationState();
}

class _HeartAnimationState extends State<HeartAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (1000 / widget.pulseRate).round()),
    );
    
    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }
  
  @override
  void didUpdateWidget(HeartAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
    
    if (widget.pulseRate != oldWidget.pulseRate) {
      _controller.duration = Duration(milliseconds: (1000 / widget.pulseRate).round());
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: UIConstants.heartGlowColor.withOpacity(0.3 + (_controller.value * 0.2)),
                blurRadius: 25 * _controller.value,
                spreadRadius: 10 * _controller.value,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 輕微發光效果
              Container(
                width: widget.size * 0.9,
                height: widget.size * 0.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.color.withOpacity(0.1 + (_controller.value * 0.1)),
                      widget.color.withOpacity(0.01),
                    ],
                    stops: [0.4, 1.0],
                  ),
                ),
              ),
              // 心臟圖形
              CustomPaint(
                size: Size(widget.size * 0.8, widget.size * 0.8),
                painter: HeartPainter(
                  color: widget.color,
                  scale: 0.85 + (_controller.value * 0.15),
                  opacity: 0.9 + (_controller.value * 0.1),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class HeartPainter extends CustomPainter {
  final Color color;
  final double scale;
  final double opacity;
  
  HeartPainter({
    required this.color,
    required this.scale,
    required this.opacity,
  });  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scaledSize = size * scale;
    
    // 創建心形路徑
    final path = Path();
    
    // 繪製心形 (更平滑的心形曲線)
    path.moveTo(center.dx, center.dy + scaledSize.height / 3);
    
    // 左半部
    path.cubicTo(
      center.dx - scaledSize.width / 2, center.dy, 
      center.dx - scaledSize.width / 2, center.dy - scaledSize.height / 2, 
      center.dx, center.dy - scaledSize.height / 4
    );
    
    // 右半部
    path.cubicTo(
      center.dx + scaledSize.width / 2, center.dy - scaledSize.height / 2, 
      center.dx + scaledSize.width / 2, center.dy, 
      center.dx, center.dy + scaledSize.height / 3
    );
    
    // 繪製發光邊框
    final Paint glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5.0);
      
    canvas.drawPath(path, glowPaint);
    
    // 繪製實心心形
    final Paint fillPaint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0);
      
    canvas.drawPath(path, fillPaint);
  }
  
  @override
  bool shouldRepaint(HeartPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.scale != scale || oldDelegate.opacity != opacity;
  }
}
