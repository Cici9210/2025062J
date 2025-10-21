/*
ESP32 主程式 (main.ino)
功能: ESP32裝置的主程式，管理WiFi連接、HTTP數據上傳、感測器讀取
相依: WiFi, HTTPClient, ArduinoJson
*/
#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include "config.h"
#include "pressure_sensor.h"
#include "led_controller.h"
#include "heat_controller.h"

// 裝置識別碼 (每個ESP32應該有唯一ID)
String DEVICE_UID = "ESP32_";

// WiFi設置
const char* ssid = WIFI_SSID;
const char* password = WIFI_PASSWORD;

// API設置
const char* api_server = API_SERVER;
const int api_port = API_PORT;

// 全域變數
PressureSensor pressureSensor;
LEDController ledController;
HeatController heatController;

// 上次發送資料的時間戳
unsigned long lastSendTime = 0;
// 發送資料的間隔 (毫秒)
const unsigned long sendInterval = 500;

// 設備是否已註冊
bool deviceRegistered = false;

void setup() {
  // 初始化序列埠
  Serial.begin(115200);
  Serial.println("Heart Interaction Device - Starting up...");
  
  // 生成唯一裝置ID (使用MAC地址)
  uint8_t mac[6];
  WiFi.macAddress(mac);
  char macStr[18];
  sprintf(macStr, "%02X%02X%02X%02X%02X%02X", mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
  DEVICE_UID += String(macStr);
  Serial.println("Device UID: " + DEVICE_UID);

  // 初始化感測器與控制器
  pressureSensor.begin(PRESSURE_SENSOR_PIN);
  ledController.begin(LED_PIN_R, LED_PIN_G, LED_PIN_B);
  heatController.begin(HEAT_PIN);

  // 連接WiFi
  connectWiFi();
  
  // 註冊裝置
  registerDevice();
}

void loop() {
  // 讀取感測器資料
  int pressure = pressureSensor.readPressure();
  
  // 更新LED和加熱元件
  updateActuators(pressure);
  
  // 發送資料到伺服器
  if (millis() - lastSendTime > sendInterval) {
    sendPressureData(pressure);
    lastSendTime = millis();
  }
  
  delay(10);
}

void connectWiFi() {
  Serial.print("Connecting to WiFi");
  WiFi.begin(ssid, password);
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  
  Serial.println();
  Serial.print("Connected to WiFi, IP address: ");
  Serial.println(WiFi.localIP());
}

void registerDevice() {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    
    String url = String("http://") + api_server + ":" + api_port + "/api/devices/register?device_uid=" + DEVICE_UID;
    
    Serial.println("Registering device: " + url);
    http.begin(url);
    http.addHeader("Content-Type", "application/json");
    
    int httpResponseCode = http.POST("");
    
    if (httpResponseCode > 0) {
      String response = http.getString();
      Serial.println("Device registered: " + response);
      deviceRegistered = true;
    } else {
      Serial.print("Error registering device: ");
      Serial.println(httpResponseCode);
    }
    
    http.end();
  }
}

void sendPressureData(int pressure) {
  if (WiFi.status() == WL_CONNECTED && deviceRegistered) {
    HTTPClient http;
    
    String url = String("http://") + api_server + ":" + api_port + "/api/devices/pressure?device_uid=" + DEVICE_UID + "&pressure=" + String(pressure);
    
    http.begin(url);
    http.addHeader("Content-Type", "application/json");
    
    int httpResponseCode = http.POST("");
    
    if (httpResponseCode > 0) {
      // 數據發送成功
      Serial.print("Pressure sent: ");
      Serial.print(pressure);
      Serial.print(" - Response: ");
      Serial.println(httpResponseCode);
    } else {
      Serial.print("Error sending pressure: ");
      Serial.println(httpResponseCode);
    }
    
    http.end();
  }
}

void updateActuators(int pressure) {
  // 根據壓力設置LED亮度
  // 壓力越大，顏色越鮮豔
  int brightness = map(pressure, 0, 100, 20, 255);
  
  // 設置LED顏色 (紅色調，表示心臟)
  ledController.setColor(brightness, 0, 0);
  ledController.update();
  
  // 可選：設置加熱元件（如果需要）
  // heatController.setLevel(brightness / 255.0);
  // heatController.update();
}

