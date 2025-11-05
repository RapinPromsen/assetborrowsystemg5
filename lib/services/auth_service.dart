import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static Future<http.Response> register({
    required String fullName,
    required String username,
    required String password,
    required String role,
  }) async {
    final url = Uri.parse('${ApiService.baseUrl}/register');
    print('🟢 [REGISTER] Sending POST to $url');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'username': username,
          'password': password,
          'role': role,
        }),
      );
      print('📦 [REGISTER] Status: ${response.statusCode}');
      print('📜 [REGISTER] Body: ${response.body}');
      return response;
    } catch (e) {
      print('🔥 [REGISTER] Error: $e');
      rethrow;
    }
  }

  static Future<http.Response> login({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse('${ApiService.baseUrl}/login');
    print('🟡 [LOGIN] Sending POST to $url');
    print('🔐 [LOGIN] Username: $username');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      print('📦 [LOGIN] Response status: ${response.statusCode}');
      print('📜 [LOGIN] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final role = data['role'];
        final fullName = data['full_name'];

        // ✅ เก็บข้อมูลไว้ใน SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('role', role);
        await prefs.setString('full_name', fullName);

        print('✅ [LOGIN] Token saved to SharedPreferences');
        print('👤 [LOGIN] Role: $role | Name: $fullName');
      } else {
        print('❌ [LOGIN] Failed with status: ${response.statusCode}');
      }

      return response;
    } catch (e) {
      print('🔥 [LOGIN] Exception: $e');
      rethrow;
    }
  }
}
