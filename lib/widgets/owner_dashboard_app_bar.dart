import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/services/api_service.dart';
import '../core/services/language_service.dart';
import '../modules/owner/dashboard/owner_dashboard_controller.dart';
import '../modules/owner/owner_main_controller.dart';
import 'app_colors.dart';
import 'owner_app_bar_helper.dart';

class OwnerDashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const OwnerDashboardAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<OwnerDashboardController>()
        ? Get.find<OwnerDashboardController>()
        : Get.put(OwnerDashboardController(apiService: Get.find<ApiService>()));

    return Obx(() {
      LanguageService.currentLocale.value;
      final ownerName = controller.ownerNameRx.value;
      final initial = ownerName.isNotEmpty ? ownerName[0].toUpperCase() : 'O';
      final hasAlert = controller.unpaidInvoices.value > 0 || controller.pendingVisitRequestsCount.value > 0;

      return Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                // Avatar with indicator
                GestureDetector(
                  onTap: () {
                    if (Get.isRegistered<OwnerMainController>()) {
                      Get.find<OwnerMainController>().changeTab(5);
                    }
                  },
                  child: Stack(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF00A86B), Color(0xFF10B981)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _buildAvatar(controller.profileImagePath.value, initial),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: hasAlert ? AppColors.accentOrange : AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Greeting & Owner Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        LanguageService.isKhmer ? "ទិវាសួស្តី!" : "Good day!",
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ownerName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Actions: Chat, Bell, Property Switch, Language
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Chat button
                    _buildIconButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      onTap: () {
                        Get.snackbar(
                          LanguageService.isKhmer ? "ជំនួយការគាំទ្រ" : "Support Center",
                          LanguageService.isKhmer
                              ? "សូមស្វាគមន៍មកកាន់ប្រព័ន្ធជំនួយ RoomFinder KH"
                              : "Welcome to RoomFinder KH Support",
                          backgroundColor: AppColors.surface,
                          colorText: AppColors.textPrimary,
                          snackPosition: SnackPosition.TOP,
                        );
                      },
                    ),

                    const SizedBox(width: 6),

                    // Notification Bell
                    _buildIconButton(
                      icon: Icons.notifications_none_rounded,
                      hasBadge: controller.pendingVisitRequestsCount.value > 0 || controller.unpaidInvoices.value > 0,
                      onTap: () => OwnerAppBarHelper.showNotifications(context),
                    ),

                    const SizedBox(width: 6),

                    // Property Picker
                    _buildIconButton(
                      icon: Icons.apartment_rounded,
                      onTap: () => OwnerAppBarHelper.showPropertyPicker(context),
                    ),

                    const SizedBox(width: 6),

                    // Language Toggle
                    GestureDetector(
                      onTap: () => LanguageService.toggleLanguage(showSnackbar: true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              LanguageService.isKhmer ? "🇰🇭" : "🇺🇸",
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              LanguageService.isKhmer ? "KH" : "EN",
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool hasBadge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: 19),
          ),
          if (hasBadge)
            Positioned(
              right: 1,
              top: 1,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String path, String initial) {
    if (path.isEmpty) {
      return Center(
        child: Text(
          initial,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      );
    }

    if (path.startsWith('data:image')) {
      try {
        final base64Part = path.split(',').last;
        return Image.memory(
          base64Decode(base64Part),
          fit: BoxFit.cover,
          width: 44,
          height: 44,
          errorBuilder: (ctx, err, stack) => Center(
            child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        );
      } catch (_) {
        return Center(
          child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        );
      }
    }

    return Image.network(
      path,
      fit: BoxFit.cover,
      width: 44,
      height: 44,
      errorBuilder: (ctx, err, stack) => Center(
        child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
    );
  }
}
