import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/rental/room_model.dart';
import '../../../widgets/app_colors.dart';
import '../../../widgets/custom_app_bar.dart';
import 'owner_rooms_controller.dart';

class OwnerRoomsView extends GetView<OwnerRoomsController> {
  const OwnerRoomsView({super.key});

  void _showAddRoomDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: "50");
    final descCtrl = TextEditingController();
    int selectedFloor = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("បន្ថែមបន្ទប់ថ្មី", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("បង្កើតបន្ទប់ថ្មីនៅលើជាន់។", style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("ឈ្មោះបន្ទប់ / Room Number", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    hintText: "ខ. បន្ទប់ ១០១ ឬ 00006",
                    hintStyle: const TextStyle(fontSize: 12),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),

                const Text("ជាន់ / Floor", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  initialValue: selectedFloor,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text("ជាន់ទី ១")),
                    DropdownMenuItem(value: 2, child: Text("ជាន់ទី ២")),
                    DropdownMenuItem(value: 3, child: Text("ជាន់ទី ៣")),
                  ],
                  onChanged: (val) => setState(() => selectedFloor = val ?? 1),
                ),
                const SizedBox(height: 14),

                const Text("តម្លៃ (\$ / ខែ) / Rent Price", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "50",
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),

                const Text("ការពិពណ៌នា (ស្រេចចិត្ត) / Description", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: "ពិពណ៌នាអំពីបន្ទប់...",
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
                      final number = nameCtrl.text.trim();
                      final price = double.tryParse(priceCtrl.text.trim()) ?? 50.0;
                      if (number.isNotEmpty) {
                        controller.addRoom(
                          number: number,
                          floor: selectedFloor,
                          price: price,
                          desc: descCtrl.text.trim(),
                        );
                        Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("បង្កើត", style: TextStyle(fontWeight: FontWeight.bold)),
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
        ),
      ),
    );
  }

  void _showRoomActionSheet(BuildContext context, RoomModel room) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("បន្ទប់ ${room.roomNumber}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(
                room.available == true ? Icons.check_circle_outline : Icons.remove_circle_outline,
                color: AppColors.primary,
              ),
              title: Text(room.available == true ? "ដាក់ជាមានមនុស្ស (Mark Occupied)" : "ដាក់ជាទំនេរ (Mark Available)"),
              onTap: () {
                Navigator.pop(ctx);
                controller.toggleAvailability(room);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.danger),
              title: const Text("លុបបន្ទប់នេះ / Delete Room", style: TextStyle(color: AppColors.danger)),
              onTap: () {
                Navigator.pop(ctx);
                controller.deleteRoom(room);
              },
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
        title: "បន្ទប់",
        propertyDropdownText: "My Home",
      ),
      body: Column(
        children: [
          // Search & Filter header (Photo 7)
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => controller.searchQuery.value = v,
                  decoration: InputDecoration(
                    hintText: "ស្វែងរកបន្ទប់...",
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                  ),
                ),
                const SizedBox(height: 12),
                Obx(() => Row(
                  children: [
                    _buildChip("ALL", "ទាំងអស់ (All)"),
                    const SizedBox(width: 8),
                    _buildChip("AVAILABLE", "ទំនេរ (Vacant)"),
                    const SizedBox(width: 8),
                    _buildChip("OCCUPIED", "មានមនុស្ស (Occupied)"),
                  ],
                )),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Room List
          Expanded(
            child: Obx(() {
              final list = controller.filteredRooms;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (ctx, i) {
                  final room = list[i];
                  final isAvail = room.available ?? true;
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
                            color: isAvail ? AppColors.primarySoft : AppColors.primarySoft.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.meeting_room_outlined, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                room.roomNumber ?? "Room",
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "ជាន់ទី ${room.floor ?? 1} • \$${room.price?.toStringAsFixed(0) ?? 50}/mo",
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isAvail ? AppColors.primarySoft : AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isAvail ? "ទំនេរ" : "មានមនុស្ស",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isAvail ? AppColors.primary : AppColors.primary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary, size: 20),
                          onPressed: () => _showRoomActionSheet(context, room),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRoomDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white, size: 26),
      ),
    );
  }

  Widget _buildChip(String code, String label) {
    final isSelected = controller.selectedFilter.value == code;
    return InkWell(
      onTap: () => controller.selectedFilter.value = code,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
