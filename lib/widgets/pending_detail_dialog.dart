import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PendingDetailDialog extends StatefulWidget {
  final Map<String, dynamic> asset;

  const PendingDetailDialog({
    super.key,
    required this.asset,
  });

  @override
  State<PendingDetailDialog> createState() => _PendingDetailDialogState();
}


class _PendingDetailDialogState extends State<PendingDetailDialog> {
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
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  insetPadding: const EdgeInsets.all(24),
  child: ConstrainedBox(
    constraints: const BoxConstraints(
      maxWidth: 400,
      maxHeight: 420, // เพิ่มความสูงเล็กน้อย
    ),
    child: SingleChildScrollView( // ✅ ห่อด้วย ScrollView
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // ✅ ปรับให้ยืดเท่าที่จำเป็น
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🏷️ Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Borrow Asset',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 📷 Image
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  widget.asset['image'] ?? '',
                  height: 120,
                  width: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 120,
                      width: 120,
                      color: Colors.grey[300],
                      child: const Icon(Icons.camera_alt, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 📄 รายละเอียด
            Text(
              'Asset name: ${widget.asset['name']}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),

            Text('Borrow date: $borrowDate',
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 6),

            Text('Return date: $returnDate',
                style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    ),
  ),
);
  }
}