"""
心臟動畫元件 (heart_animation.dart)
功能: 提供心臟脈動視覺效果
相依: flutter
"""
import 'package:flutter/material.dart';

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
          child: CustomPaint(
            painter: HeartPainter(
              color: widget.color,
              scale: 0.9 + (_controller.value * 0.2),
            ),
          ),
        );
      },
    );
  }
}

class HeartPainter extends CustomPainter {
  final Color color;
  final double scale;
  
  HeartPainter({
    required this.color,
    required this.scale,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final center = Offset(size.width / 2, size.height / 2);
    final scaledSize = size * scale;
    
    final path = Path();
    
    // 繪製心形
    path.moveTo(center.dx, center.dy + scaledSize.height / 4);
    
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
      center.dx, center.dy + scaledSize.height / 4
    );
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(HeartPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.scale != scale;
  }
}
