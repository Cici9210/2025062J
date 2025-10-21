"""
加熱控制器模組 (heat_controller.h)
功能: 控制加熱元件的強度
相依: Arduino
"""
#ifndef HEAT_CONTROLLER_H
#define HEAT_CONTROLLER_H

#include <Arduino.h>

class HeatController {
private:
  int _pin;
  float _level;  // 0.0 - 1.0
  
  // PWM頻率和解析度
  static const int PWM_FREQ = 5000;
  static const int PWM_RESOLUTION = 8;  // 8位元，0-255
  static const int PWM_CHANNEL = 3;  // 使用通道3 (通道0-2已由LED使用)
  
public:
  HeatController() : _pin(-1), _level(0.0) {}
  
  void begin(int pin) {
    _pin = pin;
    
    // 配置PWM通道
    ledcSetup(PWM_CHANNEL, PWM_FREQ, PWM_RESOLUTION);
    
    // 將引腳附加到PWM通道
    ledcAttachPin(_pin, PWM_CHANNEL);
    
    // 初始化為關閉狀態
    setLevel(0.0);
  }
  
  void setLevel(float level) {
    _level = constrain(level, 0.0, 1.0);
  }
  
  void update() {
    // 將0.0-1.0範圍轉換為0-255範圍的PWM值
    int pwmValue = _level * 255;
    
    // 寫入PWM值
    ledcWrite(PWM_CHANNEL, pwmValue);
  }
};

#endif // HEAT_CONTROLLER_H
