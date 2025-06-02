"""
壓力感測器模組 (pressure_sensor.h)
功能: 處理壓力感測器讀取和數據平滑化
相依: Arduino
"""
#ifndef PRESSURE_SENSOR_H
#define PRESSURE_SENSOR_H

#include <Arduino.h>

class PressureSensor {
private:
  int _pin;
  float _minPressure;
  float _maxPressure;
  float _lastReading;
  
  // 用於平滑化讀數的移動平均值緩衝區
  static const int BUFFER_SIZE = 10;
  float _readings[BUFFER_SIZE];
  int _readIndex = 0;
  
public:
  PressureSensor() : _pin(-1), _minPressure(0.0), _maxPressure(4095.0), _lastReading(0.0) {
    // 初始化讀數緩衝區
    for (int i = 0; i < BUFFER_SIZE; i++) {
      _readings[i] = 0.0;
    }
  }
  
  void begin(int pin, float minPressure = 0.0, float maxPressure = 4095.0) {
    _pin = pin;
    _minPressure = minPressure;
    _maxPressure = maxPressure;
    
    // 設置ADC讀取解析度（ESP32支援12位元ADC，0-4095）
    analogReadResolution(12);
    
    // 設置引腳為輸入模式
    pinMode(_pin, INPUT);
  }
  
  float readRawPressure() {
    if (_pin < 0) {
      return 0.0;
    }
    
    // 讀取原始ADC值
    int rawValue = analogRead(_pin);
    
    // 將讀數添加到緩衝區
    _readings[_readIndex] = rawValue;
    _readIndex = (_readIndex + 1) % BUFFER_SIZE;
    
    // 計算平均值
    float sum = 0.0;
    for (int i = 0; i < BUFFER_SIZE; i++) {
      sum += _readings[i];
    }
    float average = sum / BUFFER_SIZE;
    
    return average;
  }
  
  float readPressure() {
    // 讀取原始壓力值
    float rawPressure = readRawPressure();
    
    // 將ADC讀數轉換為0.0-1.0範圍
    float normalizedPressure = (rawPressure - _minPressure) / (_maxPressure - _minPressure);
    
    // 約束到0.0-1.0範圍
    normalizedPressure = constrain(normalizedPressure, 0.0, 1.0);
    
    // 存儲最後讀數
    _lastReading = normalizedPressure;
    
    return normalizedPressure;
  }
  
  float getLastReading() {
    return _lastReading;
  }
};

#endif // PRESSURE_SENSOR_H
