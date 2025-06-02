"""
ESP32 主程式 (main.ino)
功能: ESP32裝置的主程式，管理WiFi連接、WebSocket通訊、感測器讀取
相依: WiFi, WebSocketsClient, ArduinoJson
"""
#include <Arduino.h>
#include <WiFi.h>
#include <WebSocketsClient.h>
#include <ArduinoJson.h>
#include "config.h"
#include "pressure_sensor.h"
#include "led_controller.h"
#include "heat_controller.h"

// 裝置識別碼
const char* DEVICE_UID = "ESP32_HEART_001";

// WiFi設置
const char* ssid = WIFI_SSID;
const char* password = WIFI_PASSWORD;

// WebSocket設置
const char* websocket_server = WEBSOCKET_SERVER;
const int websocket_port = WEBSOCKET_PORT;
const char* websocket_url = WEBSOCKET_URL;

// 全域變數
WebSocketsClient webSocket;
PressureSensor pressureSensor;
LEDController ledController;
HeatController heatController;

// 上次發送資料的時間戳
unsigned long lastSendTime = 0;
// 發送資料的間隔 (毫秒)
const unsigned long sendInterval = 200;

// 心跳模擬參數
int currentBPM = 70;
float currentTemperature = 36.5;

void setup() {
  // 初始化序列埠
  Serial.begin(115200);
  Serial.println("Heart Interaction Device - Starting up...");

  // 初始化感測器與控制器
  pressureSensor.begin(PRESSURE_SENSOR_PIN);
  ledController.begin(LED_PIN_R, LED_PIN_G, LED_PIN_B);
  heatController.begin(HEAT_PIN);

  // 連接WiFi
  connectWiFi();
  
  // 設定WebSocket
  setupWebSocket();
}

void loop() {
  // 保持WebSocket連接
  webSocket.loop();

  // 讀取感測器資料
  float pressure = pressureSensor.readPressure();
  
  // 更新LED和加熱元件
  updateActuators(pressure);
  
  // 發送資料到伺服器
  if (millis() - lastSendTime > sendInterval) {
    sendSensorData(pressure);
    lastSendTime = millis();
  }
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

void setupWebSocket() {
  // 伺服器設定
  webSocket.begin(websocket_server, websocket_port, websocket_url);
  
  // 事件處理
  webSocket.onEvent(webSocketEvent);
  
  // 嘗試每5秒重新連接
  webSocket.setReconnectInterval(5000);
  
  Serial.println("WebSocket client started");
}

void webSocketEvent(WStype_t type, uint8_t * payload, size_t length) {
  switch(type) {
    case WStype_DISCONNECTED:
      Serial.println("WebSocket disconnected");
      break;
    case WStype_CONNECTED:
      Serial.println("WebSocket connected");
      // 發送設備識別訊息
      sendDeviceIdentification();
      break;
    case WStype_TEXT:
      handleWebSocketMessage(payload, length);
      break;
    case WStype_ERROR:
      Serial.println("WebSocket error");
      break;
  }
}

void sendDeviceIdentification() {
  // 建立JSON物件
  StaticJsonDocument<200> doc;
  doc["type"] = "identification";
  doc["device_uid"] = DEVICE_UID;
  
  // 序列化成字串
  String jsonString;
  serializeJson(doc, jsonString);
  
  // 發送到伺服器
  webSocket.sendTXT(jsonString);
  
  Serial.println("Device identification sent");
}

void sendSensorData(float pressure) {
  // 建立JSON物件
  StaticJsonDocument<200> doc;
  doc["type"] = "pressure";
  doc["device_uid"] = DEVICE_UID;
  doc["pressure_level"] = pressure;
  doc["bpm"] = currentBPM;
  doc["temperature"] = currentTemperature;
  
  // 序列化成字串
  String jsonString;
  serializeJson(doc, jsonString);
  
  // 發送到伺服器
  webSocket.sendTXT(jsonString);
  
  // 輸出到序列埠 (僅用於除錯)
  Serial.print("Sent: ");
  Serial.println(jsonString);
}

void handleWebSocketMessage(uint8_t * payload, size_t length) {
  // 解析JSON訊息
  StaticJsonDocument<512> doc;
  DeserializationError error = deserializeJson(doc, payload, length);
  
  // 檢查是否解析錯誤
  if (error) {
    Serial.print("deserializeJson() failed: ");
    Serial.println(error.c_str());
    return;
  }
  
  // 檢查訊息類型
  String messageType = doc["type"];
  
  if (messageType == "paired_pressure") {
    // 處理配對裝置的壓力數據
    float pressureLevel = doc["pressure_level"];
    Serial.print("Received paired pressure: ");
    Serial.println(pressureLevel);
    
    // 根據接收到的壓力更新裝置輸出
    updateActuators(pressureLevel);
  }
  else if (messageType == "paired_heartbeat") {
    // 處理配對裝置的心跳數據
    int bpm = doc["bpm"];
    float temperature = doc["temperature"];
    
    Serial.print("Received paired heartbeat - BPM: ");
    Serial.print(bpm);
    Serial.print(", Temperature: ");
    Serial.println(temperature);
    
    // 更新本地心跳參數
    currentBPM = bpm;
    currentTemperature = temperature;
  }
}

void updateActuators(float pressure) {
  // 根據壓力設置LED亮度
  // 壓力越大，顏色越鮮豔
  int brightness = map(pressure * 100, 0, 100, 20, 255);
  
  // 根據當前BPM設置LED閃爍模式
  int blinkRate = map(currentBPM, 60, 120, 1000, 500);  // 60-120 BPM 對應 1000-500 毫秒
  
  // 設置LED顏色 (紅色調，表示心臟)
  ledController.setColor(brightness, 0, 0);
  ledController.setPulseRate(blinkRate);
  ledController.update();
  
  // 根據溫度設置加熱元件
  float heatLevel = map(currentTemperature, 36.0, 38.0, 0.0, 1.0);
  heatController.setLevel(heatLevel);
  heatController.update();
}
