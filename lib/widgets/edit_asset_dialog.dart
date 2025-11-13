import 'package:flutter/material.dart';
import '../models/asset.dart';

class EditAssetDialog extends StatefulWidget {
  final Map<String, dynamic> asset;
  final void Function(Map<String, dynamic> updatedAsset) onSave;
  final void Function(Map<String, dynamic> deletedAsset)? onDelete;

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

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.asset['name']);
    descController = TextEditingController(text: widget.asset['description']);
    selectedStatus = widget.asset['status'];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.all(20),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      content: SizedBox(
        width: 320,
        height: 460,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 หัวข้อ + ปุ่ม Delete ด้านขวา
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit assets',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    tooltip: "Delete this asset",
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Confirm Delete"),
                          content: const Text("Are you sure you want to delete this asset?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Delete"),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && widget.onDelete != null) {
                        Navigator.of(context).pop();
                        widget.onDelete!(widget.asset);
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // 🔹 ภาพตัวอย่าง
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
              const SizedBox(height: 20),

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
            ],
          ),
        ),
      ),

      // 🔹 ปุ่ม Cancel / Save
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedAsset = {
              ...widget.asset,
              'name': nameController.text,
              'description': descController.text,
              'status': selectedStatus,
            };
            widget.onSave(updatedAsset);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
          ),
          child: const Text("Save changes"),
        ),
      ],
    );
  }
}
