import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/asset.dart';
import '../../widgets/profile_menu.dart';
import '../../widgets/borrow_asset_dialog.dart';
import '../../services/api_service.dart';
import '../../widgets/pending_detail_dialog.dart';

class StudentAssetList extends StatefulWidget {
  final String fullName;
  const StudentAssetList({super.key, required this.fullName});

  @override
  State<StudentAssetList> createState() => _StudentAssetListState();
}

class _StudentAssetListState extends State<StudentAssetList> {
  List<Map<String, dynamic>> assets = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController(); // ✅ ควบคุมช่อง search

  @override
  void initState() {
    super.initState();
    _fetchAssets();
  }

Future<void> _fetchAssets() async {
  print('🟢 [FETCH] Start fetching assets...');
  setState(() => isLoading = true);

  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      print('⚠️ [FETCH] Token not found in SharedPreferences.');
      setState(() => isLoading = false);
      return;
    }

    final url = '${ApiService.baseUrl}/assets';
    print('🌐 [FETCH] GET → $url');

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      print('✅ [FETCH] Received ${data.length} assets');

      setState(() {
        assets = data.map((item) {
          final imagePath = item['image_url'] != null
              ? 'http://192.168.10.212:5000${item['image_url']}'
              : 'http://192.168.10.212:5000/uploads/no_image.png';

          return {
            'id': item['id'],
            'name': item['name'],
            'status': _parseStatus(item['status']),
            'image': imagePath,
            'description': item['description'] ?? 'No description available.',
          };
        }).toList();

        // ✅ จัดลำดับสถานะให้อยู่ในลำดับ: Pending → Borrowed → Available → Disabled
        assets.sort((a, b) {
  const order = {
    'pending': 0,
    'borrowed': 1,
    'available': 2,
    'disabled': 3,
  };

  // แปลงจาก AssetStatus enum → ชื่อ (เช่น "pending")
  final aStatus = (a['status'] is AssetStatus)
      ? (a['status'] as AssetStatus).name.toLowerCase()
      : (a['status']?.toString().toLowerCase() ?? 'available');

  final bStatus = (b['status'] is AssetStatus)
      ? (b['status'] as AssetStatus).name.toLowerCase()
      : (b['status']?.toString().toLowerCase() ?? 'available');

  return order[aStatus]!.compareTo(order[bStatus]!);
});

        isLoading = false;
      });
    } else {
      print('❌ [FETCH] Unexpected status: ${response.statusCode}');
      print('🧾 Response: ${response.body}');
      setState(() => isLoading = false);
    }
  } catch (e) {
    print('🔥 [FETCH] Exception occurred: $e');
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
        return AssetStatus.disable;
      default:
        return AssetStatus.available;
    }
  }

  // ✅ ฟิลเตอร์ assets ตามข้อความในช่อง search
  // ✅ ฟิลเตอร์ assets ตามข้อความในช่อง search (แบบซ้ายไปขวา)
List<Map<String, dynamic>> get filteredAssets {
  final query = _searchController.text.toLowerCase().trim();
  if (query.isEmpty) return assets;

  return assets.where((asset) {
    final name = (asset['name'] ?? '').toLowerCase();
    // ค้นหาเฉพาะชื่อที่ขึ้นต้นด้วย query
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

      // ✅ ดึงลงรีเฟรชเฉพาะ assets
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.blueAccent,
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await _fetchAssets(); // ✅ โหลดใหม่แต่ไม่แตะช่อง search
              },
              color: Colors.blueAccent,
              child: Column(
                children: [
                  // 🔍 Search bar (คงอยู่เหมือนเดิม)
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
                              onChanged: (value) {
                                setState(() {}); // ✅ รีเฟรชเฉพาะ UI เมื่อพิมพ์
                              },
                            ),
                          ),
                          
                        ],
                      ),
                    ),
                  ),

                  // 🧱 Asset List
                  Expanded(
                    child: filteredAssets.isEmpty
                        ? const Center(child: Text('No assets found'))
                        : ListView.builder(
                            physics:
                                const AlwaysScrollableScrollPhysics(), // ✅ ให้ดึงลงได้ตลอด
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredAssets.length,
                            itemBuilder: (context, index) {
                              final asset = filteredAssets[index];

                              return InkWell(
                                borderRadius: BorderRadius.circular(16),
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () {
                                 if (asset['status'] == AssetStatus.available) {
  showDialog(
    context: context,
    builder: (context) => BorrowAssetDialog(
      asset: asset,
      onConfirm: (newRequest) {
        setState(() {
          final oldDesc = assets[index]['description']; // เก็บ description เดิมไว้
          assets[index] = {
            ...assets[index],          // คงข้อมูลเดิม
            ...newRequest,             // รวมข้อมูลใหม่
            'description': oldDesc,    // ทับ description เดิม
          };
        });
      },
    ),
  );
} else if (asset['status'] == AssetStatus.pending) {
  showDialog(
    context: context,
    builder: (context) => PendingDetailDialog(
      asset: asset,
    ),
  );
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('${asset['name']} is not available for borrowing.'),
      backgroundColor: Colors.grey[700],
    ),
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
                                        color:
                                            Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // 🖼️ รูปภาพ (fixed 80x80)
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        child: SizedBox(
                                          width: 80,
                                          height: 80,
                                          child: Image.network(
                                            asset['image'] ?? '',
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.camera_alt,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return Container(
                                                color: Colors.grey[200],
                                                child: const Center(
                                                  child: SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                      // 📄 รายละเอียด
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                              asset['description'] ??
                                                  'No description available.',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                              maxLines: 2,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),

                                      // 🏷️ Status
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: (asset['status']
                                                  as AssetStatus)
                                              .color,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          (asset['status'] as AssetStatus)
                                              .label,
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
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
