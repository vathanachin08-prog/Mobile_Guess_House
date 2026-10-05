import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/language_service.dart';
import '../../../models/rental/visit_request_model.dart';
import '../../../widgets/app_colors.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/empty_state_widget.dart';
import '../owner_main_controller.dart';
import 'owner_visit_requests_controller.dart';

class OwnerVisitRequestsView extends GetView<OwnerVisitRequestsController> {
  const OwnerVisitRequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      LanguageService.currentLocale.value;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(
          title: 'appointment_visit'.tr,
          subtitle: 'visit_requests_schedule'.tr,
          showBack: true,
          onBack: () => Get.back(),
        ),
        body: Column(
          children: [
            // Property Filter Bar (if multiple properties exist)
            _buildPropertyFilterBar(),

            // Status Filter Tabs
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: 38,
                child: Obx(() => ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildStatusChip("ALL", 'all'.tr),
                    _buildStatusChip("PENDING", 'status_pending'.tr),
                    _buildStatusChip("ACCEPTED", 'status_accepted'.tr),
                    _buildStatusChip("REJECTED", 'status_rejected'.tr),
                    _buildStatusChip("COMPLETED", 'status_completed'.tr),
                  ],
                )),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Requests List
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                final list = controller.filteredRequests;
                if (list.isEmpty) {
                  return EmptyStateWidget(
                    title: 'no_visit_requests'.tr,
                    message: 'no_visit_requests_desc'.tr,
                    icon: Icons.calendar_month_outlined,
                  );
                }

                return RefreshIndicator(
                  onRefresh: controller.loadRequests,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) => _buildVisitCard(list[i]),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPropertyFilterBar() {
    if (!Get.isRegistered<OwnerMainController>()) return const SizedBox.shrink();
    final mainCtrl = Get.find<OwnerMainController>();

    return Obx(() {
      final properties = mainCtrl.propertiesList;
      if (properties.length <= 1) return const SizedBox.shrink();

      return Container(
        color: AppColors.surface,
        padding: const EdgeInsets.only(top: 8, bottom: 2),
        child: SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // All properties chip
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text('all_properties'.tr),
                  selected: controller.selectedPropertyFilter.value == null,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.background,
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: controller.selectedPropertyFilter.value == null ? FontWeight.bold : FontWeight.normal,
                    color: controller.selectedPropertyFilter.value == null ? Colors.white : AppColors.textPrimary,
                  ),
                  onSelected: (_) => controller.selectedPropertyFilter.value = null,
                ),
              ),
              ...properties.map((p) {
                final id = p['id'] as int?;
                final name = p['shortName'] ?? p['name'] ?? 'Property';
                final isSelected = controller.selectedPropertyFilter.value == id;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text("$name"),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.background,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                    onSelected: (_) => controller.selectedPropertyFilter.value = id,
                  ),
                );
              }),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStatusChip(String code, String label) {
    final isSelected = controller.selectedFilter.value == code;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primarySoft,
        backgroundColor: AppColors.background,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
        onSelected: (_) => controller.selectedFilter.value = code,
      ),
    );
  }

  Widget _buildVisitCard(VisitRequestModel req) {
    Color statusColor;
    Color statusBg;
    String statusKh;

    final status = (req.status ?? 'PENDING').toUpperCase();
    switch (status) {
      case 'ACCEPTED':
        statusColor = AppColors.success;
        statusBg = AppColors.successSoft;
        statusKh = 'status_accepted'.tr;
        break;
      case 'REJECTED':
        statusColor = AppColors.danger;
        statusBg = AppColors.dangerSoft;
        statusKh = 'status_rejected'.tr;
        break;
      case 'COMPLETED':
        statusColor = AppColors.primary;
        statusBg = AppColors.primarySoft;
        statusKh = 'status_completed'.tr;
        break;
      case 'CANCELLED':
        statusColor = AppColors.textMuted;
        statusBg = AppColors.border;
        statusKh = 'status_cancelled'.tr;
        break;
      case 'PENDING':
      default:
        statusColor = AppColors.accentOrange;
        statusBg = AppColors.accentOrangeLight;
        statusKh = 'status_pending'.tr;
        break;
    }

    final isPending = status == 'PENDING';
    final isAccepted = status == 'ACCEPTED';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending ? AppColors.accentOrange.withValues(alpha: 0.4) : AppColors.border,
          width: isPending ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Property Name + Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.apartment_rounded, size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.propertyName ?? 'property_building'.tr,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (req.roomNumber != null && req.roomNumber!.isNotEmpty)
                            Text(
                              "${'room'.tr}: ${req.roomNumber}",
                              style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusKh,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

          // Student Info
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primarySoft,
                child: const Icon(Icons.person_rounded, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.studentName != null && req.studentName!.isNotEmpty ? req.studentName! : 'student_applicant'.tr,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    if (req.studentPhone != null && req.studentPhone!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            req.studentPhone!,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Date & Time Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  "${'requested_date'.tr}: ${req.requestedDate ?? ''}",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                if (req.requestedTime != null && req.requestedTime!.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time_rounded, size: 15, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    req.requestedTime!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),

          // Message bubble if available
          if (req.message != null && req.message!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      req.message!,
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action Buttons for PENDING
          if (isPending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.isProcessing.value
                        ? null
                        : () => controller.rejectRequest(req.id!),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('reject_visit'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: controller.isProcessing.value
                        ? null
                        : () => controller.acceptRequest(req.id!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text('accept_visit'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Action Button for ACCEPTED
          if (isAccepted) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.isProcessing.value
                    ? null
                    : () => controller.completeRequest(req.id!),
                icon: const Icon(Icons.done_all_rounded, size: 16),
                label: Text('mark_completed'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
