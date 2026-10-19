class AppConfig {
  static const int serverPort = 3000;
  static String get apiBaseUrl => 'http://localhost:$serverPort';
  static String get healthUrl => '$apiBaseUrl/health';
}