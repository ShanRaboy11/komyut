// lib/config/api_config.dart

class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String uploadFile = '/upload';
  
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}