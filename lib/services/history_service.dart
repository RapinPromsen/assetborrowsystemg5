import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class HistoryService {
  static final String baseUrl = ApiService.baseUrl;

  // ======================================================
  // 🧑‍🎓 STUDENT: ดึงประวัติการยืม/คืน
  // ======================================================
  static Future<List<Map<String, dynamic>>> fetchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception("Token not found");

    final url = Uri.parse('$baseUrl/borrow/history');
    print("📜 [GET] Student History → $url");

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print("🧾 [STATUS] ${response.statusCode}");

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      print("✅ [HISTORY] Loaded ${data.length} records");

      return data.map<Map<String, dynamic>>((item) {
        return {
          'id': item['id'],
          'asset_name': item['asset_name'] ?? 'Unknown',
          'status': item['status'] ?? 'unknown',
          'borrow_date': item['borrow_date'],
          'return_date': item['return_date'],
          'decision_note': item['decision_note'] ?? '',
          'approved_by': item['decided_by'] ?? '',
          'got_back_by': item['got_back_by'] ?? '',
        };
      }).toList();
    } else {
      print("❌ [HISTORY] Failed: ${response.body}");
      throw Exception("Failed to load student history");
    }
  }

  // ======================================================
  // 👨‍🏫 LECTURER: ดึงประวัติการอนุมัติ/ปฏิเสธ/คืน
  // ======================================================
  static Future<List<Map<String, dynamic>>> fetchLecturerHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception("Token not found");

    final url = Uri.parse('$baseUrl/borrow/history');
    print("📜 [GET] Lecturer History → $url");

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      print("✅ [HISTORY] Loaded ${data.length} total records");

      // ✅ เฉพาะ record ที่อาจารย์มีส่วนตัดสิน
      final filtered = data.where((item) {
        final status = (item['status'] ?? '').toString().toLowerCase();
        return ['approved', 'rejected', 'borrowed', 'returned'].contains(status);
      }).toList();

      print("✅ [LECTURER HISTORY] Filtered ${filtered.length} records");

      return filtered.map<Map<String, dynamic>>((item) {
        return {
          'id': item['id'],
          'asset_name': item['asset_name'] ?? 'Unknown',
          'student_name': item['student_name'] ?? '',
          'status': item['status'] ?? 'unknown',
          'borrow_date': item['borrow_date'],
          'return_date': item['return_date'],
          'decision_note': item['decision_note'] ?? '',
          'approved_by': item['decided_by'] ?? '',
          'got_back_by': item['got_back_by'] ?? '',
        };
      }).toList();
    } else {
      print("❌ [LECTURER HISTORY] Failed: ${response.body}");
      throw Exception("Failed to load lecturer history");
    }
  }

  // ======================================================
  // 🔍 ดึงประวัติของคำขอยืมเฉพาะรายการ
  // ======================================================
  static Future<Map<String, dynamic>> fetchHistoryById(int requestId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception("Token not found");

    final url = Uri.parse('$baseUrl/borrow/history/$requestId');
    print("🔍 [GET] $url");

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final item = jsonDecode(response.body);
      return {
        'id': item['id'],
        'asset_name': item['asset_name'] ?? 'Unknown',
        'status': item['status'] ?? 'unknown',
        'old_status': item['old_status'] ?? '-',
        'new_status': item['new_status'] ?? '-',
        'change_note': item['change_note'] ?? '',
        'changed_at': item['changed_at'],
        'borrow_date': item['borrow_date'],
        'return_date': item['return_date'],
        'changed_by': item['changed_by_name'] ?? '',
      };
    } else {
      throw Exception("Failed to fetch borrow history item");
    }
  }
}
