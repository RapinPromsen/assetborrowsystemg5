import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../widgets/profile_menu.dart';

class Dashboard extends StatefulWidget {
  final String role;
  final String fullName;

  const Dashboard({
    super.key,
    required this.role,
    required this.fullName,
  });

  @override
  State<Dashboard> createState() => _DashboardState();
}


class _DashboardState extends State<Dashboard> {
  int available = 0;
  int pending = 0;
  int borrowed = 0;
  int disabled = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

 Future<void> _loadCounts() async {
  try {
    print("🔄 [DASHBOARD] Loading summary data..."); // เพิ่มตรงนี้

    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      print("⚠️ [DASHBOARD] Missing token in SharedPreferences"); // เพิ่ม log เตือน
      throw Exception("Token not found");
    }

    // ✅ เรียก API จริง
    final url = Uri.parse("${ApiService.baseUrl}/dashboard/summary");
    print("📡 [DASHBOARD REQUEST] Sending GET → $url");

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print("📥 [DASHBOARD RESPONSE] Code=${response.statusCode}"); // เพิ่ม log

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("✅ [DASHBOARD DATA] $data"); // มีอยู่แล้ว

      setState(() {
        available = data['available'] ?? 0;
        pending = data['pending'] ?? 0;
        borrowed = data['borrowed'] ?? 0;
        disabled = data['disabled'] ?? 0;
        isLoading = false;
      });

      // ✅ เพิ่ม log สรุปค่า
      print("📊 [SUMMARY RESULT] Available=$available | Borrowed=$borrowed | Pending=$pending | Disabled=$disabled");
    } else {
      print("❌ [DASHBOARD ERROR BODY] ${response.body}");
      throw Exception("Failed to load dashboard data");
    }
  } catch (e) {
    print("💥 [DASHBOARD EXCEPTION] $e"); // เพิ่ม log ขณะเกิด error
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error loading dashboard: $e")),
    );
  }
}


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
              icon: const Icon(Icons.account_circle,
                  color: Colors.black, size: 32),
              onPressed: () async {
                final RenderBox button =
                    context.findRenderObject() as RenderBox;
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
          'Dashboard',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : RefreshIndicator(
              onRefresh: _loadCounts,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _statCard('Available', available, Colors.green,
                      Icons.check_circle_outline),
                  const SizedBox(height: 12),
                  _statCard('Borrowed', borrowed, Colors.blue, Icons.handshake),
                  const SizedBox(height: 12),
                  _statCard('Pending', pending, Colors.orange,
                      Icons.hourglass_bottom),
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
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
