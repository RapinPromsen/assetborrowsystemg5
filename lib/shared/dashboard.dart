import 'package:flutter/material.dart';
import '../../widgets/profile_menu.dart'; // ✅ อย่าลืม import ถ้ามีไฟล์นี้

class Dashboard extends StatefulWidget {
  final String role;
  final String fullName; // ✅ เพิ่มบรรทัดนี้

  const Dashboard({
    super.key,
    required this.role,
    required this.fullName, // ✅ เพิ่มใน constructor ด้วย
  });

  @override
  State<Dashboard> createState() => _DashboardState();
}


class _DashboardState extends State<Dashboard> {
  int available = 0;
  int pending = 0;
  int borrowed = 0;
  int disabled = 0;

  int currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    setState(() {
      available = 10;
      pending = 3;
      borrowed = 2;
      disabled = 5;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true, // ✅ ทำให้ title อยู่ตรงกลาง
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.account_circle,
                  color: Colors.black, size: 32),
              onPressed: () async {
                final RenderBox button =
                    context.findRenderObject() as RenderBox;
                final RenderBox overlay =
                    Overlay.of(context).context.findRenderObject() as RenderBox;
                final Offset position =
                    button.localToGlobal(Offset.zero, ancestor: overlay);

                await ProfileMenu.show(context, position, fullName: widget.fullName); // ✅ ส่งชื่อจริงไปที่เมนู
              },
            );
          },
        ),
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
       actions: [
  IconButton(
    icon: const Icon(Icons.refresh, color: Colors.black, size: 26),
    tooltip: 'Reload Dashboard',
    onPressed: () async {
      await _loadCounts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dashboard data refreshed!'),
          duration: Duration(seconds: 1),
        ),
      );
    },
  ),
],

      ),
      body: RefreshIndicator(
        onRefresh: _loadCounts,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _statCard('Borrowed', borrowed, Colors.blue, Icons.handshake),
            const SizedBox(height: 12),
            _statCard('Available', available, Colors.green,
                Icons.check_circle_outline),
            const SizedBox(height: 12),
            _statCard('Pending', pending, Colors.orange, Icons.hourglass_bottom),
            const SizedBox(height: 12),
            _statCard('Disabled', disabled, Colors.red, Icons.block),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, int count, Color color, IconData icon) {
    return Container(
      height: 100,
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, size: 36, color: Colors.white),
            const SizedBox(width: 14),
            Text(
              title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600),
            ),
          ]),
          Text(
            '$count',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
