import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/asset.dart';
import '../../services/borrow_service.dart';

class BorrowAssetDialog extends StatefulWidget {
  final Map<String, dynamic> asset;
  final Function(Map<String, dynamic>) onConfirm;

  const BorrowAssetDialog({
    super.key,
    required this.asset,
    required this.onConfirm,
  });

  @override
  State<BorrowAssetDialog> createState() => _BorrowAssetDialogState();
}

class _BorrowAssetDialogState extends State<BorrowAssetDialog> {
  late String borrowDate;
  late String returnDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    borrowDate = DateFormat('dd/MM/yy').format(now);
    returnDate = DateFormat('dd/MM/yy').format(tomorrow);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🏷️ Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Borrow Asset',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.black87),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 📷 Image
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.asset['image'] ?? '',
                        height: 140,
                        width: 140,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 140,
                            width: 140,
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.grey,
                              size: 50,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Divider(color: Colors.grey.shade300, height: 1),
                const SizedBox(height: 16),

                // 📄 Details
                _buildInfoRow('Asset name:', widget.asset['name']),
                const SizedBox(height: 12),

                const Text(
                  'Description:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.asset['description'] ?? 'No description available.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF334155),
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
                const SizedBox(height: 16),

                _buildInfoRow('Borrow date:', borrowDate),
                const SizedBox(height: 8),
                _buildInfoRow('Return date:', returnDate),
                const SizedBox(height: 24),

                // 🔘 Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          final result = await BorrowService.createBorrowRequest(
                            widget.asset['id'],
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Borrow request for "${widget.asset['name']}" sent successfully!',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                          widget.onConfirm(result);
                          Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Send Request',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Helper widget for uniform info rows
  Widget _buildInfoRow(String title, String? value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF334155),
          height: 1.5,
        ),
        children: [
          TextSpan(
            text: '$title ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          TextSpan(text: value ?? '-'),
        ],
      ),
    );
  }
}
