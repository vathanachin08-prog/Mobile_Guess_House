import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/app_colors.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/metric_card.dart';
import '../owner_main_controller.dart';
import 'owner_dashboard_controller.dart';

class OwnerDashboardView extends GetView<OwnerDashboardController> {
  const OwnerDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: "ផ្ទាំងគ្រប់គ្រង",
        propertyDropdownText: "My Home",
        onPropertyDropdownTap: () => _showPropertyPicker(context),
        actions: [
          GestureDetector(
            onTap: () {
              if (Get.isRegistered<OwnerMainController>()) {
                Get.find<OwnerMainController>().changeTab(5);
              }
            },
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primarySoft,
              child: const Icon(Icons.person, size: 18, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.loadDashboard,
        color: AppColors.primary,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner (Photo 9)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "សូមស្វាគមន៍ត្រឡប់មកវិញ 👋",
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Obx(() => Text(
                      controller.ownerNameRx.value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    )),
                    const SizedBox(height: 6),
                    const Text(
                      "នេះគឺជាព័ត៌មានទូទៅអំពីអចលនទ្រព្យរបស់អ្នកថ្ងៃនេះ។",
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 12),

                    // Quick 3-metric stats row
                    Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQuickStat("បន្ទប់សរុប", "${controller.totalRooms.value}"),
                        Container(width: 1, height: 28, color: AppColors.border),
                        _buildQuickStat("អ្នកជួល", "${controller.totalTenants.value}"),
                        Container(width: 1, height: 28, color: AppColors.border),
                        _buildQuickStat("បន្ទប់មានមនុស្ស", "${controller.occupancyRate.toStringAsFixed(0)}%"),
                      ],
                    )),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Unpaid Invoices Alert Card (Photo 9 - bright orange button)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentOrange.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.accentOrangeLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.receipt_long, color: AppColors.accentOrange, size: 18),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "វិក្កយបត្រដែលមិនទាន់បង់",
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentOrangeLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Obx(() => Text(
                            "${controller.unpaidInvoices.value} វិក្កយបត្រ",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentOrange),
                          )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Obx(() => Text(
                      "${controller.unpaidInvoices.value}",
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    )),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Switch to Tenants/Invoices tab
                          final mainCtrl = Get.find<OwnerMainController>();
                          mainCtrl.changeTab(3);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("មើលព័ត៌មានលម្អិត", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2x2 Metric Cards Grid (Photo 9)
              Obx(() => GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.15,
                children: [
                  MetricCard(
                    title: "ជាន់សរុប (Total Floors)",
                    value: "${controller.totalFloors.value}",
                    icon: Icons.layers_outlined,
                    iconColor: AppColors.accentBlue,
                    onTap: () {
                      final mainCtrl = Get.find<OwnerMainController>();
                      mainCtrl.changeTab(1);
                    },
                  ),
                  MetricCard(
                    title: "បន្ទប់ទំនេរ (Available)",
                    value: "${controller.availableRooms.value}",
                    icon: Icons.meeting_room_outlined,
                    iconColor: AppColors.accentOrange,
                    onTap: () {
                      final mainCtrl = Get.find<OwnerMainController>();
                      mainCtrl.changeTab(2);
                    },
                  ),
                  MetricCard(
                    title: "បន្ទប់មានមនុស្ស (Occupied)",
                    value: "${controller.occupiedRooms.value}",
                    icon: Icons.home_outlined,
                    iconColor: AppColors.primary,
                    onTap: () {
                      final mainCtrl = Get.find<OwnerMainController>();
                      mainCtrl.changeTab(2);
                    },
                  ),
                  MetricCard(
                    title: "អ្នកជួលសរុប (Tenants)",
                    value: "${controller.totalTenants.value}",
                    icon: Icons.people_outline,
                    iconColor: AppColors.accentPurple,
                    onTap: () {
                      final mainCtrl = Get.find<OwnerMainController>();
                      mainCtrl.changeTab(3);
                    },
                  ),
                ],
              )),

              const SizedBox(height: 16),

              // Revenue Report Card (Photo 9)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "របាយការណ៍ចំណូល (Revenue Report)",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "ខែនេះ (This Month)",
                            style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Obx(() => Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          "\$${controller.totalRevenue.value.toStringAsFixed(0)}",
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "~ 0.0% ចំណូលខែនេះ",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                      ],
                    )),
                    const SizedBox(height: 14),

                    // Legend: ប្រមូលបាន vs រំពឹងទុក
                    // Legend: ប្រមូលបាន vs រំពឹងទុក
                    Obx(() => Row(
                      children: [
                        _buildLegendItem("ប្រមូលបាន (Collected)", "\$${controller.totalRevenue.value.toStringAsFixed(0)}", AppColors.primary),
                        const SizedBox(width: 24),
                        _buildLegendItem("រំពឹងទុក (Expected)", "\$${controller.expectedRevenue.value.toStringAsFixed(2)}", AppColors.textMuted),
                      ],
                    )),

                    const SizedBox(height: 16),

                    // Simple mock visual chart line bar
                    Obx(() {
                      final collected = controller.totalRevenue.value.toInt().clamp(1, 9999);
                      final diff = (controller.expectedRevenue.value - controller.totalRevenue.value).toInt();
                      final remaining = diff > 0 ? diff : 1;
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          height: 10,
                          color: AppColors.border,
                          child: Row(
                            children: [
                              Expanded(
                                flex: collected,
                                child: Container(color: AppColors.primary),
                              ),
                              Expanded(
                                flex: remaining,
                                child: Container(color: AppColors.accentOrangeLight),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
        ),
      ],
    );
  }

  void _showPropertyPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "ជ្រើសរើសអចលនទ្រព្យ / Select Property",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.apartment_rounded, color: AppColors.primary),
              title: const Text("My Home (Phnom Penh)", style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.check, color: AppColors.primary),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.apartment_rounded, color: AppColors.textSecondary),
              title: const Text("Sunrise Student Dormitory"),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}
