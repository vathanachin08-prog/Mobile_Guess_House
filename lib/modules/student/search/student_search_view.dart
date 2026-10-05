import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/language_service.dart';
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
    return Obx(() {
      LanguageService.currentLocale.value;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: Text(
            'search'.tr,
            style: const TextStyle(
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
                        hintText: 'search_properties_hint'.tr,
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
                    child: Text('search'.tr),
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
                activeFilters.add(_buildFilterTag('only_available'.tr));
              }
              for (var f in controller.selectedFacilities) {
                activeFilters.add(_buildFilterTag(f));
              }

              if (activeFilters.isEmpty) return const SizedBox.shrink();

              return Container(
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ...activeFilters,
                      TextButton(
                        onPressed: controller.resetFilters,
                        child: Text(
                          'reset'.tr,
                          style: const TextStyle(fontSize: 12, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const Divider(height: 1, color: AppColors.border),

            // Search Results List
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (controller.searchResults.isEmpty) {
                  return EmptyStateWidget(
                    title: 'no_data'.tr,
                    message: LanguageService.isKhmer ? "សូមព្យាយាមផ្លាស់ប្តូរពាក្យស្វែងរក ឬកែសម្រួលតម្រង" : "Try changing search keywords or adjusting filters",
                    icon: Icons.search_off_rounded,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.searchResults.length,
                  itemBuilder: (ctx, i) {
                    final p = controller.searchResults[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: PropertyCard(
                        property: p,
                        onTap: () => Get.toNamed(AppRouteName.propertyDetail, arguments: p),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFilterTag(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'filters'.tr,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
              Text('room_type'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Obx(() => Wrap(
                spacing: 8,
                children: [
                  _buildTypeChoice("ALL", 'all'.tr),
                  _buildTypeChoice("SINGLE", 'single_room'.tr),
                  _buildTypeChoice("DOUBLE", 'double_room'.tr),
                  _buildTypeChoice("SHARED", 'shared_room'.tr),
                ],
              )),

              const SizedBox(height: 18),

              // Price Range
              Text('price_range'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                title: Text('only_available'.tr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                value: controller.onlyAvailable.value,
                onChanged: (v) => controller.onlyAvailable.value = v,
              )),

              const SizedBox(height: 12),

              // Facilities
              Text('facilities'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                      child: Text('reset'.tr),
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
                      child: Text('apply'.tr),
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
