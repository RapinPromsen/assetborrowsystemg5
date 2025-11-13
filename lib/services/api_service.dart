import 'dart:io';

class ApiService {
  // 🧩 ตั้งค่า IP แค่จุดเดียว
  static const String _ip = '192.168.10.212';
  static const String _port = '5000';

  // 🌐 Base สำหรับเรียก API
  static String get baseUrl {
    final host = 'http://$_ip:$_port';
    if (Platform.isAndroid || Platform.isIOS) return '$host/api';
    return 'http://localhost:5000/api';
  }

  // 🖼️ Base สำหรับโหลดรูปภาพ (ไม่ผ่าน /api)
  static String get baseImageUrl {
    final host = 'http://$_ip:$_port';
    if (Platform.isAndroid || Platform.isIOS) return host;
    return 'http://localhost:5000';
  }
}
