import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class AssetService {
  // ฟังก์ชันดึงรายการครุภัณฑ์จาก Backend
  static Future<List<Asset>> getAssets() async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/assets');
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((item) => Asset.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load assets');
      }
    } catch (e) {
      print('Error loading assets: $e');
      throw Exception('Failed to load assets');
    }
  }
}

class Asset {
  final int id;
  final String name;
  final String status;
  final String imageUrl;

  Asset({
    required this.id,
    required this.name,
    required this.status,
    required this.imageUrl,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'],
      name: json['name'],
      status: json['status'],
      imageUrl: json['image_url'],
    );
  }
}
