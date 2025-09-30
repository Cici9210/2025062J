// 應用程式配置 (app_config.dart)
// 功能: 提供應用程式配置常數
// 相依: 無

class AppConfig {
  // API 基礎 URL - 使用 localhost 以避免在某些瀏覽器中的跨域問題
  static const String apiBaseUrl = 'http://localhost:8000';
  
  // WebSocket 基礎 URL
  static const String wsBaseUrl = 'ws://localhost:8000';
  
  // 心跳更新間隔 (毫秒)
  static const int heartbeatInterval = 1000;
  
  // 超時時間 (毫秒)
  static const int timeout = 10000;
}
