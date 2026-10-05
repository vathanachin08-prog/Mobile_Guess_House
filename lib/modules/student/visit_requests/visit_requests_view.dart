import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/language_service.dart';
import '../../../models/rental/visit_request_model.dart';
import '../../../widgets/app_colors.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/empty_state_widget.dart';
import 'visit_requests_controller.dart';

class VisitRequestsView extends GetView<VisitRequestsController> {
  const VisitRequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      LanguageService.currentLocale.value;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(
          title: 'visit_appointments'.tr,
          subtitle: 'visit_requests_schedule'.tr,
        ),
        body: Column(
          children: [
            // Filter Tabs
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildTab("ALL", 'all'.tr),
                    _buildTab("PENDING", 'status_pending'.tr),
                    _buildTab("ACCEPTED", 'status_accepted'.tr),
                    _buildTab("COMPLETED", 'status_completed'.tr),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Requests list
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
                    icon: Icons.calendar_today_outlined,
                  );
                }

                return RefreshIndicator(
                  onRefresh: controller.loadRequests,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) => _buildRequestCard(list[i]),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTab(String code, String label) {
    return Obx(() {
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
    });
  }

  Widget _buildRequestCard(VisitRequestModel req) {
    Color statusColor;
    Color statusBg;
    String statusText;

    switch ((req.status ?? '').toUpperCase()) {
      case 'ACCEPTED':
        statusColor = AppColors.success;
        statusBg = AppColors.successSoft;
        statusText = 'status_accepted'.tr;
        break;
      case 'REJECTED':
        statusColor = AppColors.danger;
        statusBg = AppColors.dangerSoft;
        statusText = 'status_rejected'.tr;
        break;
      case 'COMPLETED':
        statusColor = AppColors.accentBlue;
        statusBg = AppColors.accentBlueLight;
        statusText = 'status_completed'.tr;
        break;
      case 'CANCELLED':
        statusColor = AppColors.textMuted;
        statusBg = AppColors.border;
        statusText = 'status_cancelled'.tr;
        break;
      default:
        statusColor = AppColors.warning;
        statusBg = AppColors.warningSoft;
        statusText = 'status_pending'.tr;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  req.propertyName ?? "Property Visit",
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  statusText,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          if (req.roomNumber != null) ...[
            const SizedBox(height: 4),
            Text(
              "${'room_label_prefix'.tr}: ${req.roomNumber}",
              style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                "${'date_label'.tr}: ${req.requestedDate ?? ''} • ${'time_label'.tr}: ${req.requestedTime ?? ''}",
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          if (req.message != null && req.message!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              "\"${req.message}\"",
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textMuted),
            ),
          ],
          if (req.status == 'PENDING') ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => controller.cancelRequest(req.id),
                child: Text('cancel_request'.tr, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
