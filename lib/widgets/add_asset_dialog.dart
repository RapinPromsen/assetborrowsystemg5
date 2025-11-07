import 'package:flutter/material.dart';
import '../models/asset.dart';

class AddAssetDialog extends StatefulWidget {
  final void Function(Map<String, dynamic> newAsset) onAdd;

  const AddAssetDialog({super.key, required this.onAdd});

  @override
  State<AddAssetDialog> createState() => _AddAssetDialogState();
}

class _AddAssetDialogState extends State<AddAssetDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  AssetStatus selectedStatus = AssetStatus.available;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 340,
        ),
        child: IntrinsicHeight( // ✅ ให้ความสูงพอดีกับเนื้อหา
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 หัวข้อ + ปุ่มปิด
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add new asset',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black54),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 🔹 รูปภาพ
                Center(
                  child: Container(
                    width: 120,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 🔹 Asset name
                const Text("Asset name"),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter asset name',
                  ),
                ),
                const SizedBox(height: 12),

                // 🔹 Description
                const Text("Description"),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter description',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),

                // 🔹 Status dropdown
                const Text("Status"),
                DropdownButtonFormField<AssetStatus>(
                  initialValue: selectedStatus,
                  items: AssetStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedStatus = value;
                      });
                    }
                  },
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),

                // 🔹 ปุ่ม Action
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (nameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please enter asset name")),
                            );
                            return;
                          }

                          final newAsset = {
                            'id': DateTime.now().millisecondsSinceEpoch,
                            'name': nameController.text.trim(),
                            'description': descController.text.trim(),
                            'status': selectedStatus,
                            'image':
                                'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=400',
                          };
                          widget.onAdd(newAsset);
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Add asset"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
