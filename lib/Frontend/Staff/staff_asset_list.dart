import 'package:flutter/material.dart';
import '../../models/asset.dart';
import '../../widgets/profile_menu.dart'; // นำเข้า ProfileMenu widget
import '../../widgets/edit_asset_dialog.dart'; // ✅ เพิ่มไฟล์ dialog แยก
import '../../widgets/add_asset_dialog.dart';




class StaffAssetList extends StatefulWidget {
  final String fullName;
  const StaffAssetList({super.key, required this.fullName});

  @override
  State<StaffAssetList> createState() => _StaffAssetListState();
}

class _StaffAssetListState extends State<StaffAssetList> {
  final List<Map<String, dynamic>> assets = [
    {
      'id': 1,
      'name': 'Camera',
      'status': AssetStatus.available,
      'image': 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=400',
      'description': 'High quality DSLR camera for events.',
    },
    {
      'id': 2,
      'name': 'Camera',
      'status': AssetStatus.disable,
      'image': 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=400',
      'description': 'Broken lens — needs repair.',
    },
    {
      'id': 3,
      'name': 'Camera',
      'status': AssetStatus.pending,
      'image': 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=400',
      'description': 'Waiting for admin approval.',
    },
    {
      'id': 4,
      'name': 'Camera',
      'status': AssetStatus.borrowed,
      'image': 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=400',
      'description': 'Borrowed by student for project.',
    },
  ];

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
                final Offset position = button.localToGlobal(Offset.zero, ancestor: overlay);

                await ProfileMenu.show(context, position, fullName: widget.fullName);
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
      // เปิด Dialog สำหรับเพิ่มครุภัณฑ์
      await showDialog(
        context: context,
        builder: (context) => AddAssetDialog(
          onAdd: (newAsset) {
            setState(() {
              assets.add(newAsset); // ✅ เพิ่ม asset ลงใน list
            });

            // ✅ แจ้งเตือนผู้ใช้หลังเพิ่มสำเร็จ
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added "${newAsset['name']}" successfully'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      );
    },
  ),
],

      ),
      body: Column(
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
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search assets...',
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.black54),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 📦 Asset list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: assets.length,
              itemBuilder: (context, index) {
                final asset = assets[index];
                return Container(
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
                      // 🖼️ รูปภาพ
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          asset['image'] ?? '',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[300],
                              child: const Icon(Icons.camera_alt, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),

                      // 📄 รายละเอียดทางซ้าย
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
                            ),
                          ],
                        ),
                      ),

                      // 🧩 Status อยู่บน | Edit อยู่ล่าง (แนวตั้ง)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // ✅ Status ด้านบน
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
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
                          const SizedBox(height: 8),
                          // ✏️ ปุ่ม Edit ด้านล่าง
                          SizedBox(
                            width: 80,
                            child: ElevatedButton(
                              onPressed: () => showEditDialog(asset, index),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B5CF6),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Edit',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ เพิ่มท้ายไฟล์ staff_asset_list.dart (อย่าแก้ของเดิม)
extension StaffAssetDialogExtension on _StaffAssetListState {
  void showEditDialog(Map<String, dynamic> asset, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return EditAssetDialog(
          asset: asset,
          onSave: (updatedAsset) {
          },
        );
      },
    );
  }
}
