import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/asset_service.dart';
import '../../models/asset.dart';
import '../../widgets/profile_menu.dart';
import '../../widgets/edit_asset_dialog.dart';
import '../../widgets/add_asset_dialog.dart';
import '../../widgets/borrowed_detail_dialog.dart';
import '../../widgets/pending_detail_dialog.dart';   
import '../../services/api_service.dart';
import '../../widgets/return_asset_dialog.dart';   

class StaffAssetList extends StatefulWidget {
  final String fullName;
  const StaffAssetList({super.key, required this.fullName});

  @override
  State<StaffAssetList> createState() => _StaffAssetListState();
}

class _StaffAssetListState extends State<StaffAssetList> {
  List<Map<String, dynamic>> assets = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAssets();
  }

  Future<void> _fetchAssets() async {
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

        setState(() {
          assets = data.map((item) {
            final imagePath = item['image_url'] != null
                ? '${ApiService.baseImageUrl}${item['image_url']}'
                : '${ApiService.baseImageUrl}/uploads/no_image.png';

            return {
              'id': item['asset_id'] ?? item['id'],
              'name': item['asset_name'] ?? item['name'],
              'status': _parseStatus(item['asset_status'] ?? item['status']),
              'image': imagePath,
              'description': item['description'] ?? '',
               'request_id': item['request_id'],
            };
          }).toList();

          const order = {
            'pending': 0,
            'borrowed': 1,
            'available': 2,
            'disabled': 3,
          };

          assets.sort((a, b) {
            final aKey = (a['status'] as AssetStatus).name;
            final bKey = (b['status'] as AssetStatus).name;
            return (order[aKey] ?? 99).compareTo(order[bKey] ?? 99);
          });

          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
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
    final keyword = _searchController.text.toLowerCase().trim();
    if (keyword.isEmpty) return assets;
    return assets.where((a) {
      final name = (a['name'] ?? '').toLowerCase();
      return name.contains(keyword);
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
              icon: const Icon(Icons.account_circle, color: Colors.black, size: 32),
              onPressed: () async {
                final RenderBox button = context.findRenderObject() as RenderBox;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black, size: 28),
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (context) {
                  return AddAssetDialog(
                    onAdd: (newAsset) {
                      setState(() {
                        assets.add(newAsset);
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added "${newAsset['name']}" successfully'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAssets,
              child: Column(
                children: [
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
                              onChanged: (v) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredAssets.length,
                      itemBuilder: (context, index) {
                        final asset = filteredAssets[index];
                        final status = asset['status'] as AssetStatus;

                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
  final status = asset['status'] as AssetStatus;

  if (status == AssetStatus.pending) {
    // ไป pending detail
    showDialog(
      context: context,
      builder: (context) => PendingDetailDialog(asset: asset),
    );
  } 
  else if (status == AssetStatus.borrowed) {
  // ⭐ Staff เปิด ReturnAssetDialog ทันที
  showDialog(
    context: context,
    builder: (context) => ReturnAssetDialog(
      requestId: asset['request_id'],
      assetName: asset['name'],
      onReturned: () {
        // อัปเดต UI หลังคืนสำเร็จ
        setState(() {
          asset['status'] = AssetStatus.available;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Returned successfully"),
            backgroundColor: Colors.green,
          ),
        );
      },
    ),
  );
}

  else {
    // available / disabled → แก้ไขได้
    _openEditDialog(asset);
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    asset['image'],
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 16),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        asset['name'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        asset['description'] ?? 'No description',
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: status.color,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    status.label,
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

  void _openEditDialog(Map<String, dynamic> asset) {
  showDialog(
    context: context,
    builder: (context) {
      return EditAssetDialog(
        asset: asset,
        onSave: (updatedAsset) async {
          
          // 1) เรียก backend อัปเดต
          final success = await AssetService.updateAsset(updatedAsset);

          if (!success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Update failed"),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          // 2) อัปเดต UI ให้ตรงข้อมูลใหม่
          setState(() {
            final index = assets.indexWhere((a) => a['id'] == updatedAsset['id']);

            if (index != -1) {
              assets[index] = {
                ...assets[index],

                // ส่งเข้า UI ใหม่
                'name': updatedAsset['name'],
                'description': updatedAsset['description'],
                'status': updatedAsset['status'] is AssetStatus
    ? updatedAsset['status']
    : _parseStatus(updatedAsset['status'].toString()),


                // ถ้ามีไฟล์ใหม่ → แสดงรูปใหม่
                'image': updatedAsset['image_url'] != null
    ? '${ApiService.baseImageUrl}${updatedAsset['image_url']}'
    : assets[index]['image'],
              };
            }
          });

          // ปิด dialog
          Navigator.pop(context);

          // แจ้งเตือน
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Updated \"${updatedAsset['name']}\" successfully."),
              backgroundColor: Colors.green,
            ),
          );
        },
      );
    },
  );
}
}
