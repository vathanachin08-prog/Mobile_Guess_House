import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/language_service.dart';
import '../../../routes/app_route_name.dart';
import '../../../widgets/app_colors.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/metric_card.dart';
import '../../../widgets/owner_app_bar_helper.dart';
import '../owner_main_controller.dart';
import 'owner_dashboard_controller.dart';

class OwnerDashboardView extends GetView<OwnerDashboardController> {
  const OwnerDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      LanguageService.currentLocale.value;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(
          title: 'dashboard'.tr,
          propertyDropdownText: "My Home",
          onPropertyDropdownTap: () => OwnerAppBarHelper.showPropertyPicker(context),
          actions: OwnerAppBarHelper.buildStandardActions(context),
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
                      Text(
                        'welcome_back'.tr,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
                      Text(
                        'property_overview_desc'.tr,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 12),

                      // Quick 3-metric stats row
                      Obx(() => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildQuickStat('total_rooms'.tr, "${controller.totalRooms.value}"),
                          Container(width: 1, height: 28, color: AppColors.border),
                          _buildQuickStat('tenants'.tr, "${controller.totalTenants.value}"),
                          Container(width: 1, height: 28, color: AppColors.border),
                          _buildQuickStat('occupancy_rate'.tr, "${controller.occupancyRate.toStringAsFixed(0)}%"),
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
                            Text(
                              'unpaid_invoices'.tr,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                            "${controller.unpaidInvoices.value} ${'invoices_count'.tr}",
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('view_details'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Visit Requests Alert Card
              Obx(() {
                final pendingCount = controller.pendingVisitRequestsCount.value;
                final latest = controller.latestVisitRequest.value;

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: pendingCount > 0
                          ? AppColors.primary.withValues(alpha: 0.35)
                          : AppColors.border,
                      width: pendingCount > 0 ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: pendingCount > 0
                            ? AppColors.primary.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.02),
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
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 18),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'appointment_visit'.tr,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: pendingCount > 0 ? AppColors.accentOrangeLight : AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              pendingCount > 0 ? "$pendingCount ${'pending_count_label'.tr}" : 'no_new_appointments'.tr,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: pendingCount > 0 ? AppColors.accentOrange : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (latest != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person_pin, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "${'student_tenant'.tr}: ${latest.studentName ?? 'not_specified'.tr}",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                    ),
                                  ),
                                  if (latest.propertyName != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primarySoft,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        latest.propertyName!,
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${latest.requestedDate ?? ''}  ${latest.requestedTime ?? ''}",
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                  if (latest.studentPhone != null && latest.studentPhone!.isNotEmpty) ...[
                                    const SizedBox(width: 12),
                                    const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      latest.studentPhone!,
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ],
                              ),
                              if (latest.message != null && latest.message!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '"${latest.message}"',
                                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  if (latest.id != null) {
                                    controller.quickRejectVisitRequest(latest.id!);
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                  side: const BorderSide(color: AppColors.danger),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                child: Text('reject_visit'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (latest.id != null) {
                                    controller.quickAcceptVisitRequest(latest.id!);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  elevation: 0,
                                ),
                                child: Text('accept_visit'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Get.toNamed(AppRouteName.ownerVisitRequests),
                          icon: const Icon(Icons.list_alt_rounded, size: 16),
                          label: Text('view_all_appointments'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

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
                    title: 'total_floors'.tr,
                    value: "${controller.totalFloors.value}",
                    icon: Icons.layers_outlined,
                    iconColor: AppColors.accentBlue,
                    onTap: () {
                      final mainCtrl = Get.find<OwnerMainController>();
                      mainCtrl.changeTab(1);
                    },
                  ),
                  MetricCard(
                    title: 'available_rooms'.tr,
                    value: "${controller.availableRooms.value}",
                    icon: Icons.meeting_room_outlined,
                    iconColor: AppColors.accentOrange,
                    onTap: () {
                      final mainCtrl = Get.find<OwnerMainController>();
                      mainCtrl.changeTab(2);
                    },
                  ),
                  MetricCard(
                    title: 'occupied_rooms'.tr,
                    value: "${controller.occupiedRooms.value}",
                    icon: Icons.home_outlined,
                    iconColor: AppColors.primary,
                    onTap: () {
                      final mainCtrl = Get.find<OwnerMainController>();
                      mainCtrl.changeTab(2);
                    },
                  ),
                  MetricCard(
                    title: 'total_tenants'.tr,
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
                        Text(
                          'revenue_report'.tr,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'this_month'.tr,
                            style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
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
                          child: Text(
                            "~ 0.0% ${'revenue_this_month'.tr}",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                      ],
                    )),
                    const SizedBox(height: 14),

                    // Legend
                    Obx(() => Row(
                      children: [
                        _buildLegendItem('collected'.tr, "\$${controller.totalRevenue.value.toStringAsFixed(0)}", AppColors.primary),
                        const SizedBox(width: 24),
                        _buildLegendItem('expected'.tr, "\$${controller.expectedRevenue.value.toStringAsFixed(2)}", AppColors.textMuted),
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
  });
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
}
