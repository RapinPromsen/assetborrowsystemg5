import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class BorrowService {
  static final String baseUrl = ApiService.baseUrl;

  // ======================================================
  // 🧑‍🎓 Student: Create borrow request
  // ======================================================
  static Future<Map<String, dynamic>> createBorrowRequest(int assetId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) throw Exception("Token not found");

    final url = Uri.parse('$baseUrl/borrow');
    print("📦 [POST] $url");

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'asset_id': assetId}),
    );

    final data = jsonDecode(response.body);
    print('📩 [RESPONSE] $data');

    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Borrow request failed');
  }


  // ======================================================
  // 👨‍🏫 Lecturer: Approve Request
  // ======================================================
  static Future<Map<String, dynamic>> approveRequest(int requestId, String note) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception("Token not found");

    final url = Uri.parse('$baseUrl/borrow/approve/$requestId');
    print("🟢 [PUT] $url");

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'note': note}),
    );

    final data = jsonDecode(response.body);
    print('📩 [APPROVE RESPONSE] $data');

    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Approve failed');
  }

  // ======================================================
  // 🔴 Lecturer: Reject Request
  // ======================================================
  static Future<Map<String, dynamic>> rejectRequest(int requestId, String note) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception("Token not found");

    final url = Uri.parse('$baseUrl/borrow/reject/$requestId');
    print("🔴 [PUT] $url");

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'note': note}),
    );

    final data = jsonDecode(response.body);
    print('📩 [REJECT RESPONSE] $data');

    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Reject failed');
  }

  // ======================================================
  // 🧑‍🔧 Staff: Return Borrowed Asset
  // ======================================================
  static Future<Map<String, dynamic>> returnAsset(int requestId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception("Token not found");

    final url = Uri.parse('$baseUrl/return/$requestId');
    print("♻️ [PUT] $url");

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);
    print('📩 [RETURN RESPONSE] $data');

    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Return failed');
  }
}
