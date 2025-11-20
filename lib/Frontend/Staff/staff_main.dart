import 'package:flutter/material.dart';
import 'staff_asset_list.dart';
import '../../shared/dashboard.dart';
import 'staff_history.dart';

class StaffMain extends StatefulWidget {  // ✅ เพิ่มคลาสนี้
  final String fullName;
  final String role;

  const StaffMain({super.key, required this.fullName, required this.role});

  @override
  State<StaffMain> createState() => _StaffMainState();
}
class _StaffMainState extends State<StaffMain> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // ส่งชื่อและ role ให้ Dashboard
    final List<Widget> pages = [
      StaffAssetList(fullName: widget.fullName), // ส่ง fullName และ role
      Dashboard(fullName: widget.fullName, role: widget.role), // ส่ง fullName และ role
      StaffHistory(fullName: widget.fullName)
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
        selectedItemColor: Colors.green[700],
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
