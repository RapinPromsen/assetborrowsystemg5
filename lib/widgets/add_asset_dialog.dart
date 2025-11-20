import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/asset.dart';
import '../services/asset_service.dart';
import '../services/api_service.dart';

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

  File? pickedImage;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      setState(() => pickedImage = File(file.path));
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
            // ==========================
            // Scrollable content
            // ==========================
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      "Add New Asset",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Image Picker
                    Center(
                      child: InkWell(
                        onTap: pickImage,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 140,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: pickedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    pickedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(Icons.add_photo_alternate,
                                  size: 50, color: Colors.grey),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Name
                    const Text("Asset name"),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Enter asset name",
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Description
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

                    // Status dropdown
                    const Text("Status"),
                    DropdownButtonFormField<AssetStatus>(
                      value: selectedStatus,
                      items: const [
                        DropdownMenuItem(
                          value: AssetStatus.available,
                          child: Text("Available"),
                        ),
                        DropdownMenuItem(
                          value: AssetStatus.disabled,
                          child: Text("Disabled"),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => selectedStatus = value!),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==========================
            // Bottom Buttons (fixed)
            // ==========================
            Padding(
              padding: const EdgeInsets.only(
                  bottom: 20, left: 20, right: 20, top: 12),
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
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Add"),
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Please enter asset name")),
                        );
                        return;
                      }

                      // Call backend
                      final saved = await AssetService.addAsset({
                        "name": nameController.text.trim(),
                        "description": descController.text.trim(),
                        "status": selectedStatus.name.toLowerCase(),
                        "imageFile": pickedImage,
                      });

                      if (saved == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Failed to add asset"),
                              backgroundColor: Colors.red),
                        );
                        return;
                      }

                      widget.onAdd({
                        "id": saved["id"],
                        "name": nameController.text.trim(),
                        "description": descController.text.trim(),
                        "status": selectedStatus,
                        "image":
                            "${ApiService.baseImageUrl}${saved['image_url']}",
                      });

                      Navigator.pop(context);
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
