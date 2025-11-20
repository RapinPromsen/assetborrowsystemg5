import 'package:flutter/material.dart';
import '../../widgets/profile_menu.dart';
import '../../services/history_service.dart';

class StaffHistory extends StatefulWidget {
  final String fullName;
  const StaffHistory({super.key, required this.fullName});

  @override
  State<StaffHistory> createState() => _StaffHistoryState();
}

class _StaffHistoryState extends State<StaffHistory> {
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
      print('📜 [STAFF HISTORY] Fetching from API...');
      final data = await HistoryService.fetchStaffHistory();

      setState(() {
        historyData = data.map((item) {
          final status = (item['status'] ?? 'unknown').toString().toLowerCase();
          final color = _statusColor(status);

          String safe(v) => (v ?? '').toString();

          return {
            'name': safe(item['asset_name']),
            'borrowBy': safe(item['student_name']),
            'borrowDate': safe(item['borrow_date']),
            'returnDate': safe(item['return_date']),
            'approvedBy': safe(item['approved_by']),
            'gotBackBy': safe(item['got_back_by']),
            'decision_note': safe(item['decision_note']),
            'status': status[0].toUpperCase() + status.substring(1),
            'color': color['bg'],
            'textColor': color['text'],
          };
        }).toList();

        print('✅ [STAFF HISTORY] Loaded ${historyData.length}');
        isLoading = false;
      });
    } catch (e) {
      print('❌ [STAFF HISTORY] Error: $e');
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
          'History',
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
                  child: Text('Error: $errorMessage',
                      style: const TextStyle(color: Colors.red)),
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
    final status = item['status'].toLowerCase();

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
                Text(item['name'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                _buildRow('Borrow by:', item['borrowBy']),
                _buildRow('Borrow date:', item['borrowDate']),
                _buildRow('Return date:', item['returnDate']),
                const SizedBox(height: 6),

                Divider(color: Colors.grey.shade200, height: 10),
                const SizedBox(height: 6),

                _buildRow('Approved by:', item['approvedBy']),
                if ((item['gotBackBy'] ?? '').isNotEmpty)
                  _buildRow('Got back by:', item['gotBackBy']),

                if ((item['decision_note'] ?? '').isNotEmpty)
                  _buildRow('Note:', item['decision_note']),
              ],
            ),
          ),

          // Status badge
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: item['color'],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item['status'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: item['textColor'],
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String title, String value) {
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
              text: "$title ",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
