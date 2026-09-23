import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/rental/visit_request_model.dart';
import '../../../widgets/app_colors.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/empty_state_widget.dart';
import 'visit_requests_controller.dart';

class VisitRequestsView extends GetView<VisitRequestsController> {
  const VisitRequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: "ការណាត់ជួបមើលបន្ទប់",
        subtitle: "Visit Requests Schedule",
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 36,
              child: Obx(() => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildTab("ALL", "ទាំងអស់ (All)"),
                  _buildTab("PENDING", "រង់ចាំ (Pending)"),
                  _buildTab("ACCEPTED", "យល់ព្រម (Accepted)"),
                  _buildTab("COMPLETED", "រួចរាល់ (Completed)"),
                ],
              )),
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
                return const EmptyStateWidget(
                  title: "មិនទាន់មានការណាត់ជួប / No Visit Requests",
                  message: "អ្នកអាចស្នើសុំមើលបន្ទប់ដោយផ្ទាល់ពីទំព័រព័ត៌មានអចលនទ្រព្យ",
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
  }

  Widget _buildTab(String code, String label) {
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

  Widget _buildRequestCard(VisitRequestModel req) {
    Color statusColor;
    Color statusBg;
    String statusKh;

    switch ((req.status ?? '').toUpperCase()) {
      case 'ACCEPTED':
        statusColor = AppColors.success;
        statusBg = AppColors.successSoft;
        statusKh = "បានយល់ព្រម (Accepted)";
        break;
      case 'REJECTED':
        statusColor = AppColors.danger;
        statusBg = AppColors.dangerSoft;
        statusKh = "បដិសេធ (Rejected)";
        break;
      case 'COMPLETED':
        statusColor = AppColors.accentBlue;
        statusBg = AppColors.accentBlueLight;
        statusKh = "បានបញ្ចប់ (Completed)";
        break;
      case 'CANCELLED':
        statusColor = AppColors.textMuted;
        statusBg = AppColors.border;
        statusKh = "បានបោះបង់ (Cancelled)";
        break;
      default:
        statusColor = AppColors.warning;
        statusBg = AppColors.warningSoft;
        statusKh = "កំពុងរង់ចាំ (Pending)";
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
                  statusKh,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          if (req.roomNumber != null) ...[
            const SizedBox(height: 4),
            Text(
              "បន្ទប់ / Room: ${req.roomNumber}",
              style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                "កាលបរិច្ឆេទ: ${req.requestedDate ?? ''} • ម៉ោង: ${req.requestedTime ?? ''}",
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
                child: const Text("បោះបង់ការស្នើសុំ / Cancel", style: TextStyle(color: AppColors.danger, fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
