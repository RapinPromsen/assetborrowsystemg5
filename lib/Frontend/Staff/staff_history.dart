import 'package:flutter/material.dart';
import '../../widgets/profile_menu.dart';

class StaffHistory extends StatefulWidget {
  final String fullName;
  const StaffHistory({super.key, required this.fullName});

  @override
  State<StaffHistory> createState() => _StaffHistoryState();
}

class _StaffHistoryState extends State<StaffHistory> {
  final List<Map<String, dynamic>> historyData = [
    {
      'name': 'Camera',
      'borrowDate': '18/10/25',
      'returnDate': '19/10/25',
      'approvedBy': 'Robert Downey',
      'gotBackBy': 'Mr.Admin',
      'borrowBy': 'Somchai',
      'status': 'Returned',
      'color': Colors.grey,
      'textColor': Colors.white,
    },
    {
      'name': 'Camera',
      'borrowDate': '19/10/25',
      'returnDate': '20/10/25',
      'approvedBy': 'Robert Downey',
      'borrowBy': 'Somchai',
      'status': 'Borrowed',
      'color': Colors.blue,
      'textColor': Colors.white,
    },
    {
      'name': 'Camera',
      'borrowDate': '19/10/25',
      'returnDate': '29/10/25',
      'borrowBy': 'Somchai',
      'status': 'Pending',
      'color': Colors.amber.shade300,
      'textColor': Colors.white,
    },
    {
      'name': 'Camera',
      'borrowDate': '-',
      'returnDate': '-',
      'rejectedBy': 'Robert Downey',
      'borrowBy': 'Somchai',
      'status': 'Rejected',
      'color': Colors.red.shade300,
      'textColor': Colors.white,
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
                final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                final Offset position = button.localToGlobal(Offset.zero, ancestor: overlay);
                await ProfileMenu.show(context, position, fullName: widget.fullName);
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
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            const SizedBox(height: 16),
            ...historyData.map((item) => HistoryCard(item: item)),
          ],
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: ${item['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Borrow date: ${item['borrowDate']}'),
                  Text('Returned date: ${item['returnDate']}'),
                  if (item.containsKey('approvedBy')) Text('Approved by: ${item['approvedBy']}'),
                  if (item.containsKey('gotBackBy')) Text('Got back by: ${item['gotBackBy']}'),
                  if (item.containsKey('rejectedBy')) Text('Rejected by: ${item['rejectedBy']}'),
                  Text('Borrow by: ${item['borrowBy']}'),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: item['color'],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item['status'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: item['textColor'],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
