import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/asset.dart';


class AssetService {
  // --------------------------
  // 1) GET assets
  // --------------------------
  static Future<List<Asset>> getAssets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final url = Uri.parse('${ApiService.baseUrl}/assets');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
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

// --------------------------
// ADD ASSET (POST + multipart)
// --------------------------
static Future<Map<String, dynamic>?> addAsset(Map<String, dynamic> asset) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) throw Exception("Token not found");

    final uri = Uri.parse("${ApiService.baseUrl}/assets");
    final request = http.MultipartRequest("POST", uri);

    request.headers['Authorization'] = "Bearer $token";

    request.fields["name"] = asset["name"] ?? "";
    request.fields["status"] = asset["status"] ?? "available";

    // ถ้ามีไฟล์รูป
    if (asset["imageFile"] != null && asset["imageFile"] is File) {
      request.files.add(await http.MultipartFile.fromPath(
        "image",
        (asset["imageFile"] as File).path,
      ));
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 201) {
      return jsonDecode(response.body)["asset"];
    }

    print("❌ Add failed: ${response.body}");
    return null;

  } catch (e) {
    print("❌ Add Error: $e");
    return null;
  }
}

 // --------------------------
// 2) UPDATE asset (PUT + multipart)
// --------------------------
static Future<bool> updateAsset(Map<String, dynamic> asset) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) throw Exception("Token not found");

    final uri = Uri.parse("${ApiService.baseUrl}/assets/${asset['id']}");
    final request = http.MultipartRequest("PATCH", uri);


    request.headers['Authorization'] = "Bearer $token";

    request.fields["name"] = asset["name"] ?? "";
    request.fields["description"] = asset["description"] ?? "";

    // ⭐ รองรับทั้ง String และ AssetStatus
    dynamic status = asset["status"];
    if (status is AssetStatus) {
      request.fields["status"] = status.name.toLowerCase();
    } else if (status is String) {
      request.fields["status"] = status.toLowerCase();
    } else {
      request.fields["status"] = "available";
    }

    // ถ้ามีไฟล์แนบ
  // ถ้ามีไฟล์แนบ
if (asset["newImageFile"] != null && asset["newImageFile"] is File) {
  request.files.add(
    await http.MultipartFile.fromPath(
      "image",
      (asset["newImageFile"] as File).path,
    ),
  );
}



    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    return response.statusCode == 200;
  } catch (e) {
    throw Exception("Update failed: $e");
  }
}


  // --------------------------
  // 3) DELETE asset
  // --------------------------
  static Future<bool> deleteAsset(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final url = Uri.parse("${ApiService.baseUrl}/assets/$id");

      final res = await http.delete(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      return res.statusCode == 200;
    } catch (e) {
      throw Exception("Delete failed: $e");
    }
  }
}

// -------------------------
// Asset model
// -------------------------

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
    id: json['id'] ?? json['asset_id'],
    name: json['name'] ?? json['asset_name'],
    status: json['status'] ?? json['asset_status'],
    imageUrl: json['image_url'] ?? json['image'] ?? "",
  );
}

}
