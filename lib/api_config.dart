/// API configuration file for customizing the backend IP easily.
class ApiConfig {
  static String _baseUrl = 'http://192.168.1.166:8085';

  static String get baseUrl => _baseUrl;
  static set baseUrl(String url) => _baseUrl = url;
}
