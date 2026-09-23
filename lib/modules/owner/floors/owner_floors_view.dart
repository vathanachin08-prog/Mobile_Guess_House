import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/app_colors.dart';
import '../../../widgets/custom_app_bar.dart';

class FloorItem {
  final String name;
  final int totalRooms;
  final int occupiedRooms;

  FloorItem({required this.name, required this.totalRooms, required this.occupiedRooms});
}

class OwnerFloorsView extends StatefulWidget {
  const OwnerFloorsView({super.key});

  @override
  State<OwnerFloorsView> createState() => _OwnerFloorsViewState();
}

class _OwnerFloorsViewState extends State<OwnerFloorsView> {
  final searchController = TextEditingController();
  final List<FloorItem> floors = [
    FloorItem(name: "ជាន់ទី ៣", totalRooms: 0, occupiedRooms: 0),
    FloorItem(name: "ជាន់ទី ១", totalRooms: 2, occupiedRooms: 1),
    FloorItem(name: "ជាន់ទី ២", totalRooms: 3, occupiedRooms: 0),
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _addFloorDialog() {
    final floorNameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("បន្ថែមជាន់ថ្មី", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("បញ្ចូលឈ្មោះសម្រាប់ជាន់ថ្មី។", style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("ឈ្មោះជាន់", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: floorNameCtrl,
              decoration: InputDecoration(
                hintText: "ខ. ជាន់ទី១, ជាន់ផ្ទាល់ដី",
                hintStyle: const TextStyle(fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final text = floorNameCtrl.text.trim();
                  if (text.isNotEmpty) {
                    setState(() {
                      floors.add(FloorItem(name: text, totalRooms: 0, occupiedRooms: 0));
                    });
                    Navigator.pop(ctx);
                    Get.snackbar("Success", "បានបង្កើតជាន់ជោគជ័យ! Floor created.", backgroundColor: Colors.green.shade50);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("បង្កើតជាន់", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("បោះបង់", style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: "ជាន់",
        propertyDropdownText: "My Home",
      ),
      body: Column(
        children: [
          // Search input
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "ស្វែងរកជាន់...",
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Floors List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: floors.length,
              itemBuilder: (ctx, i) {
                final floor = floors[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.layers_outlined, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              floor.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${floor.totalRooms} បន្ទប់សរុប",
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (floor.occupiedRooms > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "${floor.occupiedRooms} មានមនុស្ស",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary, size: 20),
                        onPressed: () {},
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFloorDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white, size: 26),
      ),
    );
  }
}
