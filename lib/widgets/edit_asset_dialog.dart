import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/asset.dart';

class EditAssetDialog extends StatefulWidget {
  final Map<String, dynamic> asset;
  final void Function(Map<String, dynamic>) onSave;
  final void Function(Map<String, dynamic>)? onDelete;

  const EditAssetDialog({
    super.key,
    required this.asset,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<EditAssetDialog> createState() => _EditAssetDialogState();
}

class _EditAssetDialogState extends State<EditAssetDialog> {
  late TextEditingController nameController;
  late TextEditingController descController;

  late AssetStatus selectedStatus;

  File? newImageFile;              // ⭐ ไฟล์รูปที่เลือกใหม่
  String? previewImagePath;        // ⭐ Path สำหรับ preview

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.asset['name']);
    descController = TextEditingController(text: widget.asset['description']);

    selectedStatus = widget.asset['status']; // enum

    previewImagePath = null; // default ยังไม่เลือกภาพใหม่
  }

  // ⭐ ฟังก์ชันเลือกไฟล์จาก gallery
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        newImageFile = File(picked.path);
        previewImagePath = picked.path; // แสดงภาพที่เลือก
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // เลื่อนเฉพาะเนื้อหา
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Edit Asset",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ⭐ รูป (กดเลือกได้)
                    Center(
                      child: InkWell(
                        onTap: pickImage,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 140,
                            height: 140,
                            color: Colors.grey[200],
                            child: previewImagePath != null
                                ? Image.file(
                                    File(previewImagePath!),
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    widget.asset['image'],
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 🔹 ชื่อ
                    const Text("Asset name"),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Enter asset name",
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 🔹 Description
                    const Text("Description"),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Enter description",
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 🔹 Status dropdown
                   // 🔹 Status dropdown
const Text("Status"),
DropdownButtonFormField<AssetStatus>(
  value: selectedStatus,
  decoration: const InputDecoration(
    border: OutlineInputBorder(),
  ),

  // ⭐ แสดงเฉพาะ Available + Disable เท่านั้น
  items: [
    AssetStatus.available,
    AssetStatus.disabled,
  ].map((s) {
    return DropdownMenuItem(
      value: s,
      child: Text(s.label),
    );
  }).toList(),

  onChanged: (value) {
    if (value != null) {
      setState(() => selectedStatus = value);
    }
  },
),

                  ],
                ),
              ),
            ),

            // ⭐ ปุ่มไม่เลื่อน
            Padding(
              padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20, top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: const Text("Cancel"),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Save"),
                  onPressed: () {
  print("=== SAVE PRESSED ===");
  print("name: ${nameController.text}");
  print("description: ${descController.text}");
  print("status: $selectedStatus");
  print("newImageFile: $newImageFile");

 widget.onSave({
  ...widget.asset,
  "name": nameController.text,
  "description": descController.text,
  "status": selectedStatus,
  "newImageFile": newImageFile,
  "image_url": widget.asset['image_url'],  
});


  // ❌ ไม่ต้อง pop ที่นี่
},

                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
