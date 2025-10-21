/*
ESP32 配置檔案 (config.h)
功能: 提供ESP32裝置的配置參數
相依: 無
*/
#ifndef CONFIG_H
#define CONFIG_H

// WiFi 設定
#define WIFI_SSID "YourWiFiSSID"
#define WIFI_PASSWORD "YourWiFiPassword"

// API 設定
#define API_SERVER "192.168.1.114"  // 後端伺服器IP
#define API_PORT 8000

// 腳位定義
#define PRESSURE_SENSOR_PIN 34  // 壓力感測器ADC腳位 (GPIO 34)
#define LED_PIN_R 25  // RGB LED 紅色腳位
#define LED_PIN_G 26  // RGB LED 綠色腳位
#define LED_PIN_B 27  // RGB LED 藍色腳位
#define HEAT_PIN 13   // 加熱元件腳位（可選）

#endif // CONFIG_H

