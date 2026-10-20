import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/language_service.dart';
import '../../widgets/app_colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/owner_dashboard_app_bar.dart';
import 'dashboard/owner_dashboard_view.dart';
import 'floors/owner_floors_view.dart';
import 'rooms/owner_rooms_view.dart';
import 'tenants/owner_tenants_view.dart';
import 'invoices/owner_invoices_view.dart';
import 'profile/owner_profile_view.dart';
import 'owner_main_controller.dart';

class OwnerMainView extends GetView<OwnerMainController> {
  const OwnerMainView({super.key});

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    switch (controller.currentIndex.value) {
      case 0:
        return const OwnerDashboardAppBar();
      case 1:
        return CustomAppBar(
          title: 'floors'.tr,
          subtitle: controller.selectedPropertyName.value,
          showProperty: false,
          showLanguage: false,
          isOwner: true,
        );
      case 2:
        return CustomAppBar(
          title: 'rooms'.tr,
          subtitle: controller.selectedPropertyName.value,
          showProperty: false,
          showLanguage: false,
          isOwner: true,
        );
      case 3:
        return CustomAppBar(
          title: 'tenants'.tr,
          subtitle: controller.selectedPropertyName.value,
          showProperty: false,
          showLanguage: false,
          isOwner: true,
        );
      case 4:
        return CustomAppBar(
          title: 'invoices'.tr,
          subtitle: controller.selectedPropertyName.value,
          showProperty: false,
          showLanguage: false,
          isOwner: true,
        );
      case 5:
        return CustomAppBar(
          title: 'my_profile'.tr,
          subtitle: 'owner_profile'.tr,
          showProperty: false,
          showLanguage: false,
          isOwner: true,
        );
      default:
        return const CustomAppBar(title: "RoomFinder KH");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Rebuild when locale or tab changes
      LanguageService.currentLocale.value;

      final pages = [
        const OwnerDashboardView(),
        const OwnerFloorsView(),
        const OwnerRoomsView(),
        const OwnerTenantsView(),
        const OwnerInvoicesView(),
        const OwnerProfileView(),
      ];

      return Scaffold(
        appBar: _buildAppBar(context),
        body: IndexedStack(
          index: controller.currentIndex.value,
          children: pages,
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: BottomNavigationBar(
            currentIndex: controller.currentIndex.value,
            onTap: controller.changeTab,
            backgroundColor: AppColors.surface,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontSize: 10),
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.grid_view_outlined),
                activeIcon: const Icon(Icons.grid_view_rounded),
                label: 'dashboard'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.layers_outlined),
                activeIcon: const Icon(Icons.layers_rounded),
                label: 'floors'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.meeting_room_outlined),
                activeIcon: const Icon(Icons.meeting_room_rounded),
                label: 'rooms'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.people_outline_rounded),
                activeIcon: const Icon(Icons.people_rounded),
                label: 'tenants'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.receipt_long_outlined),
                activeIcon: const Icon(Icons.receipt_long_rounded),
                label: 'invoices'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline_rounded),
                activeIcon: const Icon(Icons.person_rounded),
                label: 'profile'.tr,
              ),
            ],
          ),
        ),
      );
    });
  }
}
