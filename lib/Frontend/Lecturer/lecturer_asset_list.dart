import 'dart:convert';
import 'package:assetborrowsystemg5/widgets/lecture_asset_detail.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/asset.dart';
import '../../widgets/profile_menu.dart';
import '../../services/api_service.dart';
import '../../widgets/lecture_asset_action.dart';
import '../../widgets/borrowed_detail_dialog.dart';

class LecturerAssetList extends StatefulWidget {
  final String fullName;
  const LecturerAssetList({super.key, required this.fullName});

  @override
  State<LecturerAssetList> createState() => _LecturerAssetListState();
}

class _LecturerAssetListState extends State<LecturerAssetList> {
  List<Map<String, dynamic>> assets = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAssets();
  }

  Future<void> _fetchAssets() async {
  print('🟢 [LECTURER FETCH] Start fetching assets...');
  setState(() => isLoading = true);

  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception("Token not found");

    final url = '${ApiService.baseUrl}/assets';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      print('✅ [LECTURER FETCH] Received ${data.length} assets');

      setState(() {
        assets = data.map((item) {
  final imagePath = item['image_url'] != null
      ? '${ApiService.baseImageUrl}${item['image_url']}'
      : '${ApiService.baseImageUrl}/uploads/no_image.png';

  return {
    'id': item['asset_id'] ?? item['id'],
    'request_id': item['request_id'],
    'name': item['asset_name'] ?? item['name'],
    'student': item['student_name'] ?? '',
    'status': _parseStatus(item['asset_status'] ?? item['status']),
    'image': imagePath,
    'description': item['description'] ?? '',
  };
}).toList();


        // ✅ เรียงตามลำดับสถานะเหมือน student
        // ✅ เรียงตามลำดับสถานะ (ป้องกัน null)
assets.sort((a, b) {
  const order = {
    'pending': 0,
    'borrowed': 1,
    'available': 2,
    'disabled': 3,
  };

  final aStatus = (a['status'] is AssetStatus)
      ? (a['status'] as AssetStatus).name.toLowerCase()
      : (a['status']?.toString().toLowerCase() ?? 'available');

  final bStatus = (b['status'] is AssetStatus)
      ? (b['status'] as AssetStatus).name.toLowerCase()
      : (b['status']?.toString().toLowerCase() ?? 'available');

  final aRank = order[aStatus] ?? 99;
  final bRank = order[bStatus] ?? 99;

  return aRank.compareTo(bRank);
});


        isLoading = false;
      });
    } else {
      print('❌ [LECTURER FETCH] ${response.statusCode} ${response.body}');
      setState(() => isLoading = false);
    }
  } catch (e) {
    print('🔥 [LECTURER FETCH] Exception: $e');
    setState(() => isLoading = false);
  }
}


  AssetStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'available':
        return AssetStatus.available;
      case 'pending':
        return AssetStatus.pending;
      case 'borrowed':
        return AssetStatus.borrowed;
      case 'disabled':
        return AssetStatus.disabled;
      default:
        return AssetStatus.available;
    }
  }

  List<Map<String, dynamic>> get filteredAssets {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return assets;
    return assets.where((asset) {
      final name = (asset['name'] ?? '').toLowerCase();
      return name.startsWith(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.account_circle,
                  color: Colors.black, size: 32),
              onPressed: () async {
                final RenderBox button =
                    context.findRenderObject() as RenderBox;
                final RenderBox overlay =
                    Overlay.of(context).context.findRenderObject() as RenderBox;
                final Offset position =
                    button.localToGlobal(Offset.zero, ancestor: overlay);

                await ProfileMenu.show(context, position,
                    fullName: widget.fullName);
              },
            );
          },
        ),
        title: const Text(
          'Assets List',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ✅ แค่โชว์รายการ (ไม่มี onTap)
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 3, color: Colors.blueAccent),
            )
          : RefreshIndicator(
              onRefresh: _fetchAssets,
              color: Colors.blueAccent,
              child: Column(
                children: [
                  // 🔍 Search bar
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E5E5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Icon(Icons.search, color: Colors.black54),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Search assets...',
                              ),
                              onChanged: (value) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 📋 Asset list (ดูอย่างเดียว)
                  Expanded(
                    child: filteredAssets.isEmpty
                        ? const Center(child: Text('No assets found'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredAssets.length,
                         itemBuilder: (context, index) {
  final asset = filteredAssets[index];

  return InkWell(
    borderRadius: BorderRadius.circular(16),
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
   onTap: () {
  final status = (asset['status'] as AssetStatus).name;

  if (status == 'pending') {
    // ✅ เปิดหน้าสำหรับอนุมัติ/ปฏิเสธ
    showDialog(
      context: context,
      builder: (context) => LectuerActionDialog(asset: asset),
    ).then((_) => Future.microtask(() => _fetchAssets()));
  } else if (status == 'borrowed') {
    // 🛠️ เปิดหน้าดูรายละเอียดการยืม
    showDialog(
      context: context,
      builder: (context) => BorrowedDetailDialog(asset: asset),
    );
  }  
  else {
    // 🧩 แค่ดูรายละเอียด
    showDialog(
      context: context,
      builder: (context) => LectuerDetailDialog(asset: asset),
    );
  }
},

    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 80,
              height: 80,
              child: Image.network(
                asset['image'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.camera_alt, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  asset['description'] ?? 'No description available.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (asset['status'] as AssetStatus).color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              (asset['status'] as AssetStatus).label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
