import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class HistoryService {
  static final String baseUrl = ApiService.baseUrl;

  // ======================================================
  // 📜 ดึงประวัติการยืม/คืนทั้งหมด (แยกตาม role อัตโนมัติ)
  // ======================================================
  static Future<List<Map<String, dynamic>>> fetchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception("Token not found");

    final url = Uri.parse('$baseUrl/history');
    print("📜 [GET] $url");

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print("🧾 [STATUS] ${response.statusCode}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("✅ [HISTORY] Loaded ${data.length} records");
      return List<Map<String, dynamic>>.from(data);
    } else {
      print("❌ [HISTORY] Failed: ${response.body}");
      throw Exception("Failed to load history");
    }
  }

  // ======================================================
  // 🔍 ดึงประวัติของรายการเดียว (optional)
  // ======================================================
  static Future<Map<String, dynamic>> fetchHistoryById(int requestId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception("Token not found");

    final url = Uri.parse('$baseUrl/history/$requestId');
    print("🔍 [GET] $url");

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch history item");
    }
  }
}
