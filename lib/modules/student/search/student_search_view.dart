import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_route_name.dart';
import '../../../widgets/app_colors.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/facility_chip.dart';
import '../../../widgets/property_card.dart';
import 'student_search_controller.dart';

class StudentSearchView extends GetView<StudentSearchController> {
  const StudentSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          "ស្វែងរកបន្ទប់ជួល / Search",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Input
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.searchController,
                    onSubmitted: (_) => controller.search(),
                    decoration: InputDecoration(
                      hintText: "ស្វែងរកឈ្មោះ សកលវិទ្យាល័យ ខណ្ឌ...",
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: AppColors.textSecondary),
                        onPressed: () {
                          controller.searchController.clear();
                          controller.search();
                        },
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: controller.search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  child: const Text("ស្វែងរក"),
                ),
              ],
            ),
          ),

          // Active filter indicator
          Obx(() {
            final activeFilters = <Widget>[];
            if (controller.selectedRoomType.value != "ALL") {
              activeFilters.add(_buildFilterTag("Type: ${controller.selectedRoomType.value}"));
            }
            if (controller.minPrice.value > 0 || controller.maxPrice.value < 300) {
              activeFilters.add(_buildFilterTag("\$${controller.minPrice.value.toInt()} - \$${controller.maxPrice.value.toInt()}"));
            }
            if (controller.onlyAvailable.value) {
              activeFilters.add(_buildFilterTag("Available only"));
            }

            if (activeFilters.isEmpty) return const SizedBox.shrink();

            return Container(
              width: double.infinity,
              color: AppColors.surface,
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  ...activeFilters,
                  InkWell(
                    onTap: controller.resetFilters,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        "សម្អាតតម្រង / Reset",
                        style: TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const Divider(height: 1, color: AppColors.border),

          // Search Results
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              final results = controller.searchResults;
              if (results.isEmpty) {
                return EmptyStateWidget(
                  title: "រកមិនឃើញលទ្ធផល / No Results Found",
                  message: "សូមសាកល្បងស្វែងរកដោយប្រើពាក្យផ្សេង ឬផ្លាស់ប្តូរតម្រង",
                  buttonText: "កំណត់តម្រងឡើងវិញ / Reset Filters",
                  onButtonTap: controller.resetFilters,
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final item = results[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: PropertyCard(
                      property: item,
                      onTap: () => Get.toNamed(AppRouteName.propertyDetail, arguments: item),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTag(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "តម្រងស្វែងរក (Filters)",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: AppColors.border),
              const SizedBox(height: 12),

              // Room Type
              const Text("ប្រភេទបន្ទប់ / Room Type", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Obx(() => Wrap(
                spacing: 8,
                children: [
                  _buildTypeChoice("ALL", "ទាំងអស់ (All)"),
                  _buildTypeChoice("SINGLE", "បន្ទប់ទោល (Single)"),
                  _buildTypeChoice("DOUBLE", "បន្ទប់គូ (Double)"),
                  _buildTypeChoice("SHARED", "បន្ទប់រួម (Shared)"),
                ],
              )),

              const SizedBox(height: 18),

              // Price Range
              const Text("កម្រិតតម្លៃ (\$ / ខែ) / Price Range", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Obx(() => Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("\$${controller.minPrice.value.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                      Text("\$${controller.maxPrice.value.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                  RangeSlider(
                    values: RangeValues(controller.minPrice.value, controller.maxPrice.value),
                    min: 0,
                    max: 300,
                    divisions: 30,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.border,
                    onChanged: (vals) {
                      controller.minPrice.value = vals.start;
                      controller.maxPrice.value = vals.end;
                    },
                  ),
                ],
              )),

              const SizedBox(height: 12),

              // Only available switch
              Obx(() => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.primary,
                title: const Text("បន្ទប់ទំនេរតែប៉ុណ្ណោះ (Only Available)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                value: controller.onlyAvailable.value,
                onChanged: (v) => controller.onlyAvailable.value = v,
              )),

              const SizedBox(height: 12),

              // Facilities
              const Text("ឧបករណ៍ប្រើប្រាស់ / Facilities", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Obx(() => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FacilityChip(
                    name: "WIFI",
                    isSelected: controller.selectedFacilities.contains("WIFI"),
                    onTap: () => controller.toggleFacility("WIFI"),
                  ),
                  FacilityChip(
                    name: "AIR_CONDITIONER",
                    isSelected: controller.selectedFacilities.contains("AIR_CONDITIONER"),
                    onTap: () => controller.toggleFacility("AIR_CONDITIONER"),
                  ),
                  FacilityChip(
                    name: "PRIVATE_BATHROOM",
                    isSelected: controller.selectedFacilities.contains("PRIVATE_BATHROOM"),
                    onTap: () => controller.toggleFacility("PRIVATE_BATHROOM"),
                  ),
                  FacilityChip(
                    name: "PARKING",
                    isSelected: controller.selectedFacilities.contains("PARKING"),
                    onTap: () => controller.toggleFacility("PARKING"),
                  ),
                ],
              )),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        controller.resetFilters();
                        Navigator.pop(ctx);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("កំណត់ឡើងវិញ / Reset"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        controller.search();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("អនុវត្ត / Apply"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChoice(String code, String label) {
    final isSelected = controller.selectedRoomType.value == code;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primarySoft,
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
      ),
      onSelected: (_) => controller.selectedRoomType.value = code,
    );
  }
}
