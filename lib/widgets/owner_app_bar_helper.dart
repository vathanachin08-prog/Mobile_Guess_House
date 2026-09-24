import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../modules/owner/owner_main_controller.dart';
import '../routes/app_route_name.dart';
import 'app_colors.dart';

class OwnerAppBarHelper {
  OwnerAppBarHelper._();

  static OwnerMainController getController() {
    if (Get.isRegistered<OwnerMainController>()) {
      return Get.find<OwnerMainController>();
    }
    return Get.put(OwnerMainController());
  }

  /// Show property switcher bottom sheet
  static void showPropertyPicker(BuildContext context) {
    final ctrl = getController();

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
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "ជ្រើសរើសអចលនទ្រព្យ",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Select Property / Switch active building",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 22),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Property List
                Obx(() {
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: ctrl.propertiesList.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = ctrl.propertiesList[index];
                      final isSelected = item['id'] == ctrl.selectedPropertyId.value;

                      return InkWell(
                        onTap: () {
                          ctrl.selectProperty(item);
                          Navigator.pop(ctx);
                          Get.snackbar(
                            "អចលនទ្រព្យសកម្ម",
                            "បានប្តូរទៅកាន់ ${item['name']}",
                            snackPosition: SnackPosition.BOTTOM,
                            margin: const EdgeInsets.all(16),
                            backgroundColor: Colors.white,
                            colorText: AppColors.textPrimary,
                            icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                            duration: const Duration(seconds: 2),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primarySoft.withValues(alpha: 0.35) : AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.business_rounded,
                                  size: 20,
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'] as String,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "${item['address']} • ${item['rooms']} បន្ទប់",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),

                const SizedBox(height: 16),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 14),

                // Add Property Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showAddPropertyDialog(context, ctrl, ctx);
                    },
                    icon: const Icon(Icons.add_business_rounded, size: 18, color: AppColors.primary),
                    label: const Text(
                      "+ បន្ថែមអគារថ្មី (Add New Property)",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.primary, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Show Add Property Dialog
  static void _showAddPropertyDialog(BuildContext context, OwnerMainController ctrl, BuildContext sheetContext) {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.add_business_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              "បន្ថែមអគារថ្មី",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: "ឈ្មោះអគារ / Property Name",
                hintText: "ឧ. Rose Garden Apartment",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressCtrl,
              decoration: InputDecoration(
                labelText: "អាសយដ្ឋាន / Address",
                hintText: "ឧ. Khan Daun Penh, Phnom Penh",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("បោះបង់ (Cancel)", style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final addr = addressCtrl.text.trim();
              if (name.isNotEmpty) {
                ctrl.addNewProperty(name, addr.isNotEmpty ? addr : "Phnom Penh");
                Navigator.pop(dialogCtx);
                Navigator.pop(sheetContext);
                Get.snackbar(
                  "ជោគជ័យ",
                  "បានបង្កើតអគារ $name រួចរាល់",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.white,
                  colorText: AppColors.textPrimary,
                  icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                  margin: const EdgeInsets.all(16),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("រក្សាទុក (Save)"),
          ),
        ],
      ),
    );
  }

  /// Show notifications modal bottom sheet
  static void showNotifications(BuildContext context) {
    final ctrl = getController();

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
                    const Expanded(
                      child: Text(
                        "ការជូនដំណឹង (Notifications)",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Obx(() {
                      final count = ctrl.unreadNotificationsCount.value;
                      if (count > 0) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "$count ថ្មី",
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
                        ctrl.markAllNotificationsAsRead();
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
                      label: const Text(
                        "សម្គាល់ថាបានអានទាំងអស់",
                        style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
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
                    if (ctrl.notificationsList.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.textMuted),
                              SizedBox(height: 12),
                              Text("មិនមានការជូនដំណឹងថ្មីទេ", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: ctrl.notificationsList.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final notif = ctrl.notificationsList[index];
                        final isUnread = notif['isUnread'] == true;
                        final color = (notif['color'] as Color?) ?? AppColors.primary;
                        final icon = (notif['icon'] as IconData?) ?? Icons.notifications_rounded;

                        return Container(
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
                                  ],
                                ),
                              ),
                            ],
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

  /// Navigate to owner account / profile tab
  static void navigateToProfile(BuildContext context) {
    if (Get.isRegistered<OwnerMainController>()) {
      final mainCtrl = Get.find<OwnerMainController>();
      mainCtrl.changeTab(5); // Index 5 is OwnerProfileView
      if (Navigator.canPop(context)) {
        Get.until((route) => route.isFirst);
      }
    } else {
      Get.toNamed(AppRouteName.ownerProfile);
    }
  }

  /// Build notification icon with real-time unread badge
  static Widget buildNotificationAction(BuildContext context) {
    final ctrl = getController();

    return Obx(() {
      final unread = ctrl.unreadNotificationsCount.value;

      return IconButton(
        tooltip: "ការជូនដំណឹង (Notifications)",
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 24),
            if (unread > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                ),
              ),
          ],
        ),
        onPressed: () => showNotifications(context),
      );
    });
  }

  /// Build account (profile) icon action
  static Widget buildAccountAction(BuildContext context) {
    return IconButton(
      tooltip: "គណនី (Account)",
      icon: const Icon(Icons.person_outline_rounded, color: AppColors.textPrimary, size: 24),
      onPressed: () => navigateToProfile(context),
    );
  }

  /// Standard owner action widgets (Notification + Account)
  static List<Widget> buildStandardActions(BuildContext context) {
    return [
      buildNotificationAction(context),
      buildAccountAction(context),
      const SizedBox(width: 4),
    ];
  }
}
