// lib/services/api_service.dart
import 'dart:io';

class ApiService {
  static String get baseUrl {
    if (Platform.isAndroid) return 'http://192.168.10.212:5000/api';
    if (Platform.isIOS) return 'http://192.168.10.212:5000/api';
    return 'http://localhost:5000/api';
  }
}
