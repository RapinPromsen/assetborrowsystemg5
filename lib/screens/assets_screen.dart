import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../widgets/asset_card.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  final List<Asset> assets = [
    Asset(id: 1, name: 'Fundamental\nElectrical', status: AssetStatus.available),
    Asset(id: 2, name: 'Artificial\nintelligence', status: AssetStatus.disabled),
    Asset(id: 3, name: 'Internet of thing', status: AssetStatus.pending),
    Asset(id: 4, name: 'Book', status: AssetStatus.borrowed),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Assets',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black, size: 28),
            onPressed: () {
              // Handle add action
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5E5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(Icons.search, color: Colors.black54),
                  ),
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '',
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.black54),
                      onPressed: () {
                        // Handle filter action
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Assets list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: assets.length,
              itemBuilder: (context, index) {
                return AssetCard(
                  asset: assets[index],
                  onEdit: () {
                    // Handle edit action
                    print('Edit asset ${assets[index].id}');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
