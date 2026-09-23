import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/rental/room_model.dart';
import '../../../widgets/app_colors.dart';
import '../../../widgets/facility_chip.dart';
import '../visit_requests/request_visit_dialog.dart';

class RoomDetailView extends StatelessWidget {
  const RoomDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final RoomModel room = Get.arguments as RoomModel;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "បន្ទប់ ${room.roomNumber ?? ''}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Icon / Image Box
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.meeting_room_rounded, size: 64, color: AppColors.primary.withValues(alpha: 0.7)),
                    const SizedBox(height: 8),
                    Text(
                      room.title ?? "Rental Room",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Price & Availability Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("តម្លៃឈ្នួល / Monthly Rent", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(
                        "\$${(room.price ?? 0).toStringAsFixed(0)} / mo",
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (room.available ?? true) ? AppColors.primarySoft : AppColors.dangerSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      (room.available ?? true) ? "បន្ទប់ទំនេរ (Available)" : "មានមនុស្ស (Occupied)",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: (room.available ?? true) ? AppColors.primary : AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Room Specifications Grid
            const Text("លក្ខណៈពិសេសនៃបន្ទប់ / Specifications", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildSpecItem("ជាន់ទី / Floor", "ជាន់ទី ${room.floor ?? 1}", Icons.layers_outlined)),
                const SizedBox(width: 10),
                Expanded(child: _buildSpecItem("ទំហំ / Area", "${room.area ?? 18} m²", Icons.aspect_ratio_outlined)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildSpecItem("ប្រភេទបន្ទប់ / Type", room.roomType ?? "SINGLE", Icons.king_bed_outlined)),
                const SizedBox(width: 10),
                Expanded(child: _buildSpecItem("ភេទ / Gender", room.genderPreference ?? "ANY", Icons.people_outline)),
              ],
            ),
            const SizedBox(height: 20),

            // Description
            if (room.description != null && room.description!.isNotEmpty) ...[
              const Text("ព័ត៌មានបន្ថែម / Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              Text(
                room.description!,
                style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
            ],

            // Facilities
            const Text("ឧបករណ៍ប្រើប្រាស់ក្នុងបន្ទប់ / Room Facilities", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            if (room.facilities != null && room.facilities!.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: room.facilities!.map((f) => FacilityChip(name: f.name ?? '')).toList(),
              )
            else
              const Text("WIFI, AIR_CONDITIONER, PRIVATE_BATHROOM", style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),

            const SizedBox(height: 32),

            // Action Button
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => RequestVisitDialog(
                    propertyId: room.propertyId ?? 1,
                    roomId: room.id,
                    roomNumber: room.roomNumber,
                    propertyName: room.propertyName ?? "Property",
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month_outlined, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "ស្នើសុំមើលបន្ទប់នេះ / Request Visit for this Room",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
