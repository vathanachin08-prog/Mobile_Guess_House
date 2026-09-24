import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_route_name.dart';
import '../../../widgets/app_colors.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/property_card.dart';
import '../student_main_controller.dart';
import 'student_home_controller.dart';

class StudentHomeView extends GetView<StudentHomeController> {
  const StudentHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.home_work_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "RoomFinder KH",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  "Phnom Penh, Cambodia 📍",
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: AppColors.primary, size: 20),
            onPressed: () {
              if (Get.locale?.languageCode == 'km') {
                Get.updateLocale(const Locale('en', 'US'));
              } else {
                Get.updateLocale(const Locale('km', 'KH'));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 22),
            onPressed: () {
              Get.snackbar("Notice", "No new notifications", backgroundColor: Colors.white);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.loadProperties,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "ស្វែងរកបន្ទប់ជួលដែលទុកចិត្តបាន 🏡",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Find safe, student-friendly rooms near your university",
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),

                    // Search Input Trigger
                    InkWell(
                      onTap: () {
                        // Switch to Search tab
                        final mainCtrl = Get.find<StudentMainController>();
                        mainCtrl.changeTab(1);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search, color: AppColors.primary, size: 22),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "ស្វែងរកតាមទីតាំង សកលវិទ្យាល័យ ឬតម្លៃ...",
                                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                              ),
                            ),
                            Icon(Icons.tune_rounded, color: AppColors.textSecondary, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Category Pills
              SizedBox(
                height: 38,
                child: Obx(() => ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildCategoryPill("ALL", "ទាំងអស់ (All)"),
                    _buildCategoryPill("DORMITORY", "អន្តេវាសិកដ្ឋាន (Dormitory)"),
                    _buildCategoryPill("APARTMENT", "អាផាតមិន (Apartment)"),
                    _buildCategoryPill("ROOM", "បន្ទប់ជួល (Room)"),
                    _buildCategoryPill("CONDO", "ខុនដូ (Condo)"),
                  ],
                )),
              ),

              const SizedBox(height: 24),

              // Verified Properties Section
              Obx(() {
                final verified = controller.verifiedProperties;
                if (verified.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.verified, color: AppColors.primary, size: 18),
                              SizedBox(width: 6),
                              Text(
                                "បានផ្ទៀងផ្ទាត់ (Verified)",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              final mainCtrl = Get.find<StudentMainController>();
                              mainCtrl.changeTab(1);
                            },
                            child: const Text(
                              "មើលទាំងអស់ / View All",
                              style: TextStyle(color: AppColors.primary, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 290,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: verified.length,
                        itemBuilder: (context, index) {
                          final item = verified[index];
                          return Container(
                            width: 260,
                            margin: const EdgeInsets.only(right: 14),
                            child: PropertyCard(
                              property: item,
                              isFavorite: controller.favoriteIds.contains(item.id),
                              onFavoriteTap: () => controller.toggleFavorite(item),
                              onTap: () => Get.toNamed(AppRouteName.propertyDetail, arguments: item),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 20),

              // All / Recommended Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "អចលនទ្រព្យណែនាំ (Recommended)",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Obx(() => Text(
                      "${controller.filteredProperties.length} found",
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }

                final list = controller.filteredProperties;
                if (list.isEmpty) {
                  return const EmptyStateWidget(
                    title: "រកមិនឃើញអចលនទ្រព្យ / No Properties Found",
                    message: "សូមព្យាយាមជ្រើសរើសប្រភេទផ្សេងទៀត",
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: PropertyCard(
                        property: item,
                        isFavorite: controller.favoriteIds.contains(item.id),
                        onFavoriteTap: () => controller.toggleFavorite(item),
                        onTap: () => Get.toNamed(AppRouteName.propertyDetail, arguments: item),
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPill(String code, String label) {
    final isSelected = controller.selectedCategory.value == code;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () => controller.setCategory(code),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
