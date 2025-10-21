// 應用程式配置 (app_config.dart)
// 功能: 提供應用程式配置常數
// 相依: 無

class AppConfig {
  // API 基礎 URL - 優先使用環境變數，否則使用本地開發地址
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.114:8000',
  );
  
  // WebSocket 基礎 URL - 優先使用環境變數
  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'ws://192.168.1.114:8000',
  );
  
  // 心跳更新間隔 (毫秒)
  static const int heartbeatInterval = 1000;
  
  // 超時時間 (毫秒)
  static const int timeout = 10000;
}
