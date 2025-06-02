
// 壓力視覺化元件 (pressure_visualizer.dart)
// 功能: 提供使用者互動的壓力視覺化介面
// 相依: flutter

import 'package:flutter/material.dart';

class PressureVisualizer extends StatefulWidget {
  final Function(double) onPressureChanged;
  
  const PressureVisualizer({
    Key? key,
    required this.onPressureChanged,
  }) : super(key: key);

  @override
  State<PressureVisualizer> createState() => _PressureVisualizerState();
}

class _PressureVisualizerState extends State<PressureVisualizer> {
  double _pressure = 0.0;
  
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
        Container(
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.5),
                Colors.purple.withOpacity(0.7),
                Colors.red.withOpacity(0.9),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: _pressure,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        
        // 壓力滑桿
        Slider(
          value: _pressure,
          onChanged: _updatePressure,
          min: 0.0,
          max: 1.0,
          divisions: 100,
          label: '${(_pressure * 100).round()}%',
          activeColor: Theme.of(context).primaryColor,
        ),
        
        // 提示文字
        Text(
          '輕按或長按以表達心意',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
