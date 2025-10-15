// 應用程式配置 (app_config.dart)
// 功能: 提供應用程式配置常數
// 相依: 無

class AppConfig {
  // API 基礎 URL - 使用相對路徑避免跨域問題
  static const String apiBaseUrl = 'http://192.168.1.114:8000';
  
  // WebSocket 基礎 URL
  static const String wsBaseUrl = 'ws://192.168.1.114:8000';
  
  // 心跳更新間隔 (毫秒)
  static const int heartbeatInterval = 1000;
  
  // 超時時間 (毫秒)
  static const int timeout = 10000;
}
