import 'package:flutter/material.dart';
import '../../widgets/profile_menu.dart';
import '../../services/history_service.dart';

class StudentHistory extends StatefulWidget {
  final String fullName;
  const StudentHistory({super.key, required this.fullName});

  @override
  State<StudentHistory> createState() => _StudentHistoryState();
}

class _StudentHistoryState extends State<StudentHistory> {
  List<Map<String, dynamic>> historyData = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
  setState(() {
    isLoading = true;
    errorMessage = null;
  });

  try {
    print('📜 [HISTORY] Fetching from API...');
    final data = await HistoryService.fetchHistory();

    setState(() {
  historyData = data.map((item) {
    final status = (item['status'] ?? 'unknown').toString().toLowerCase();
    final color = _statusColor(status);

    // ✅ บังคับให้ทุกฟิลด์เป็น String ปลอดภัยจาก null
    String safe(Object? v) => (v ?? '').toString();

    return {
      'name': safe(item['asset_name']),
      'borrowDate': safe(item['borrow_date']),
      'returnDate': safe(item['return_date']),
      'approvedBy': safe(item['approved_by']),
      'gotBackBy': safe(item['got_back_by']),
      'decision_note': safe(item['decision_note']),
      'status': status.isNotEmpty
          ? status[0].toUpperCase() + status.substring(1)
          : 'Unknown',
      'color': color['bg'],
      'textColor': color['text'],
    };
  }).toList();

  print('✅ [MAPPED HISTORY] ${historyData.length} item(s)');
  isLoading = false;
});



  } catch (e) {
    print('❌ [HISTORY] Error: $e');
    setState(() {
      errorMessage = e.toString();
      isLoading = false;
    });
  }
}


  Map<String, Color> _statusColor(String status) {
    switch (status) {
      case 'pending':
        return {'bg': Colors.amber.shade400, 'text': Colors.black};
      case 'approved':
      case 'borrowed':
        return {'bg': Colors.blueAccent, 'text': Colors.white};
      case 'returned':
        return {'bg': Colors.grey.shade600, 'text': Colors.white};
      case 'rejected':
        return {'bg': Colors.red.shade400, 'text': Colors.white};
      default:
        return {'bg': Colors.grey.shade300, 'text': Colors.black};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black12,
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
          'Borrow History',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : errorMessage != null
              ? Center(
                  child: Text(
                    'Error: $errorMessage',
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchHistory,
                  color: Colors.blueAccent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: historyData.length,
                    itemBuilder: (context, index) =>
                        HistoryCard(item: historyData[index]),
                  ),
                ),
    );
  }
}

class HistoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const HistoryCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final status = item['status'].toString().toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 100, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🧾 ชื่อ
                Text(
                  item['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),

                // 📅 วันที่
                _buildInfoRow('Borrow date:', item['borrowDate']),
                _buildInfoRow('Return date:', item['returnDate']),

                const SizedBox(height: 6),
                Divider(color: Colors.grey.shade200, height: 10),
                const SizedBox(height: 6),

                // 👨‍🏫 ผู้อนุมัติ / ปฏิเสธ
                if (status == 'rejected' && (item['approvedBy'] ?? '').isNotEmpty)
                  _buildInfoRow('Rejected by:', item['approvedBy']),
                if (status == 'rejected' && (item['decision_note'] ?? '').isNotEmpty)
                  _buildInfoRow('Reason:', item['decision_note']),
                if (status != 'rejected' && (item['approvedBy'] ?? '').isNotEmpty)
                  _buildInfoRow('Approved by:', item['approvedBy']),
                if ((item['gotBackBy'] ?? '').isNotEmpty)
                  _buildInfoRow('Got back by:', item['gotBackBy']),
                if (status != 'rejected' && (item['decision_note'] ?? '').isNotEmpty)
                  _buildInfoRow('Note:', item['decision_note']),
              ],
            ),
          ),

          // 🔖 Badge ด้านขวา
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: item['color'],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                item['status'],
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: item['textColor'],
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Color(0xFF475569),
            fontSize: 14,
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            TextSpan(text: value ?? '-'),
          ],
        ),
      ),
    );
  }
}
