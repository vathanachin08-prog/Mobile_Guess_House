import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/language_service.dart';
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
    return Obx(() {
      LanguageService.currentLocale.value;

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
            tooltip: 'switch_language'.tr,
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language, color: AppColors.primary, size: 15),
                  const SizedBox(width: 4),
                  Text(
                    LanguageService.isKhmer ? "KH" : "EN",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            onPressed: () => LanguageService.showLanguageSelector(context),
          ),
          Obx(() {
            final unread = controller.unreadNotificationsCount.value;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  tooltip: 'notifications'.tr,
                  icon: Icon(
                    unread > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                    color: unread > 0 ? AppColors.primary : AppColors.textPrimary,
                    size: 22,
                  ),
                  onPressed: () => _showNotificationsSheet(context),
                ),
                if (unread > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Center(
                        child: Text(
                          "$unread",
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
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
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: AppColors.primary, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'search_properties_hint'.tr,
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                              ),
                            ),
                            const Icon(Icons.tune_rounded, color: AppColors.textSecondary, size: 20),
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
                    _buildCategoryPill("ALL", 'all'.tr),
                    _buildCategoryPill("DORMITORY", LanguageService.isKhmer ? "អន្តេវាសិកដ្ឋាន" : "Dormitory"),
                    _buildCategoryPill("APARTMENT", LanguageService.isKhmer ? "អាផាតមិន" : "Apartment"),
                    _buildCategoryPill("ROOM", LanguageService.isKhmer ? "បន្ទប់ជួល" : "Room"),
                    _buildCategoryPill("CONDO", LanguageService.isKhmer ? "ខុនដូ" : "Condo"),
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
                          Row(
                            children: [
                              const Icon(Icons.verified, color: AppColors.primary, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'verified_properties'.tr,
                                style: const TextStyle(
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
                            child: Text(
                              'view_all'.tr,
                              style: const TextStyle(color: AppColors.primary, fontSize: 12),
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
                            child: Obx(() => PropertyCard(
                              property: item,
                              style: PropertyCardStyle.vertical,
                              isFavorite: controller.favoriteIds.contains(item.id),
                              onFavoriteTap: () => controller.toggleFavorite(item),
                              onTap: () => Get.toNamed(AppRouteName.propertyDetail, arguments: item),
                            )),
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
                    Text(
                      'recommended_for_you'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        Obx(() => Text(
                          "${controller.filteredProperties.length} found",
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        )),
                        const SizedBox(width: 8),
                        Obx(() => InkWell(
                          onTap: controller.toggleCardStyle,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Icon(
                              controller.cardStyle.value == PropertyCardStyle.horizontal
                                  ? Icons.view_agenda_outlined
                                  : Icons.view_list_outlined,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        )),
                      ],
                    ),
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
                  return EmptyStateWidget(
                    title: 'no_properties_found'.tr,
                    message: 'try_different_category'.tr,
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
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Obx(() => PropertyCard(
                        property: item,
                        style: controller.cardStyle.value,
                        isFavorite: controller.favoriteIds.contains(item.id),
                        onFavoriteTap: () => controller.toggleFavorite(item),
                        onTap: () => Get.toNamed(AppRouteName.propertyDetail, arguments: item),
                      )),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
    });
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

  void _showNotificationsSheet(BuildContext context) {
    controller.loadNotifications();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'notifications'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Obx(() {
                      final count = controller.unreadNotificationsCount.value;
                      if (count > 0) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'new_notifications_count'.trParams({'count': count.toString()}),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.danger,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Mark all read button row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        controller.markAllNotificationsAsRead();
                        Get.snackbar(
                          "ការជូនដំណឹង",
                          "បានសម្គាល់ថាបានអានទាំងអស់",
                          snackPosition: SnackPosition.BOTTOM,
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.white,
                          colorText: AppColors.textPrimary,
                          margin: const EdgeInsets.all(16),
                        );
                      },
                      icon: const Icon(Icons.done_all_rounded, size: 16, color: AppColors.primary),
                      label: Text(
                        'mark_all_read'.tr,
                        style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 8),

                // Notification Items List
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.55,
                  ),
                  child: Obx(() {
                    if (controller.notificationsList.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              Text('no_notifications'.tr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: controller.notificationsList.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final notif = controller.notificationsList[index];
                        final isUnread = notif['isUnread'] == true;
                        final color = (notif['color'] as Color?) ?? AppColors.primary;
                        final icon = (notif['icon'] as IconData?) ?? Icons.notifications_rounded;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              final id = notif['id']?.toString() ?? '';
                              controller.markNotificationAsRead(id);
                              Navigator.pop(ctx);
                              if (notif['tabIndex'] != null && Get.isRegistered<StudentMainController>()) {
                                Get.find<StudentMainController>().changeTab(notif['tabIndex'] as int);
                              } else if (notif['route'] != null) {
                                Get.toNamed(notif['route'] as String);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isUnread ? color.withValues(alpha: 0.05) : AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isUnread ? color.withValues(alpha: 0.3) : AppColors.border,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(icon, size: 18, color: color),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                notif['title'] as String,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              notif['time'] as String,
                                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                            ),
                                            if (isUnread) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                width: 7,
                                                height: 7,
                                                decoration: BoxDecoration(
                                                  color: color,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          notif['message'] as String,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                            height: 1.3,
                                          ),
                                        ),
                                        if (notif['tabIndex'] != null || notif['route'] != null) ...[
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Text(
                                                "ចុចដើម្បីមើលព័ត៌មានលម្អិត",
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(Icons.arrow_forward_rounded, size: 12, color: color),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
