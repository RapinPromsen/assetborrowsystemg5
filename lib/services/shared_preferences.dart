// lib/services/shared_preferences.dart
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefService {
  // 🔐 เก็บ Token หลังจาก Login สำเร็จ
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // 🧭 ดึง Token มาใช้ (ตอนเรียก API)
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // 🧹 ลบ Token (ตอน Logout)
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // 💼 เก็บ Role เผื่อใช้ redirect ตามสิทธิ์
  static Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role);
  }

  // 🧭 ดึง Role
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  // 🧹 ลบ Role
  static Future<void> clearRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('role');
  }
}
