import 'package:flutter/material.dart';
import 'lecturer_asset_list.dart';
import '../../shared/dashboard.dart'; // ✅ ใช้ Dashboard ตัวเดียวกับ Staff
import 'lecturer_history.dart';

class LecturerMain extends StatefulWidget {
  final String fullName; // ✅ รับชื่อจริงจาก Login
  final String role;     // ✅ รับ role จาก Login

  const LecturerMain({
    super.key,
    required this.fullName,
    required this.role,
  });

  @override
  State<LecturerMain> createState() => _LecturerMainState();
}

class _LecturerMainState extends State<LecturerMain> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // ✅ ส่งชื่อและ role ให้ Dashboard (shared)
    final List<Widget> pages = [
      LecturerAssetList(fullName: widget.fullName),
      Dashboard(fullName: widget.fullName, role: widget.role),
      LecturerHistory(fullName: widget.fullName),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.blue[700],
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Assets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),

        ],
      ),
    );
  }
}
