"""
LED控制器模組 (led_controller.h)
功能: 控制RGB LED的顏色和脈動效果
相依: Arduino
"""
#ifndef LED_CONTROLLER_H
#define LED_CONTROLLER_H

#include <Arduino.h>

class LEDController {
private:
  int _pinR;
  int _pinG;
  int _pinB;
  
  int _r, _g, _b;  // 當前RGB值
  
  unsigned long _lastPulseTime;
  int _pulseRate;  // 脈動間隔 (毫秒)
  bool _pulseState;  // 脈動狀態
  
  // PWM頻率和解析度
  static const int PWM_FREQ = 5000;
  static const int PWM_RESOLUTION = 8;  // 8位元，0-255
  
  // 用於每個顏色通道的PWM通道
  static const int PWM_CHANNEL_R = 0;
  static const int PWM_CHANNEL_G = 1;
  static const int PWM_CHANNEL_B = 2;
  
public:
  LEDController() : 
    _pinR(-1), _pinG(-1), _pinB(-1), 
    _r(0), _g(0), _b(0),
    _lastPulseTime(0), _pulseRate(1000), _pulseState(false) {}
  
  void begin(int pinR, int pinG, int pinB) {
    _pinR = pinR;
    _pinG = pinG;
    _pinB = pinB;
    
    // 配置PWM通道
    ledcSetup(PWM_CHANNEL_R, PWM_FREQ, PWM_RESOLUTION);
    ledcSetup(PWM_CHANNEL_G, PWM_FREQ, PWM_RESOLUTION);
    ledcSetup(PWM_CHANNEL_B, PWM_FREQ, PWM_RESOLUTION);
    
    // 將引腳附加到PWM通道
    ledcAttachPin(_pinR, PWM_CHANNEL_R);
    ledcAttachPin(_pinG, PWM_CHANNEL_G);
    ledcAttachPin(_pinB, PWM_CHANNEL_B);
    
    // 初始化為關閉狀態
    setColor(0, 0, 0);
  }
  
  void setColor(int r, int g, int b) {
    _r = constrain(r, 0, 255);
    _g = constrain(g, 0, 255);
    _b = constrain(b, 0, 255);
  }
  
  void setPulseRate(int rate) {
    _pulseRate = rate;
  }
  
  void update() {
    // 更新脈動狀態
    unsigned long currentTime = millis();
    if (currentTime - _lastPulseTime > _pulseRate) {
      _pulseState = !_pulseState;
      _lastPulseTime = currentTime;
    }
    
    // 根據脈動狀態設置亮度
    int brightness = _pulseState ? 100 : 30;  // 30% - 100% 亮度範圍
    
    // 計算實際RGB值
    int r = map(brightness, 0, 100, 0, _r);
    int g = map(brightness, 0, 100, 0, _g);
    int b = map(brightness, 0, 100, 0, _b);
    
    // 寫入PWM值
    ledcWrite(PWM_CHANNEL_R, r);
    ledcWrite(PWM_CHANNEL_G, g);
    ledcWrite(PWM_CHANNEL_B, b);
  }
};

#endif // LED_CONTROLLER_H
