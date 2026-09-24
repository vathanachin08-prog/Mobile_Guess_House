import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/app_colors.dart';
import 'dashboard/owner_dashboard_view.dart';
import 'floors/owner_floors_view.dart';
import 'rooms/owner_rooms_view.dart';
import 'tenants/owner_tenants_view.dart';
import 'invoices/owner_invoices_view.dart';
import 'profile/owner_profile_view.dart';
import 'owner_main_controller.dart';

class OwnerMainView extends GetView<OwnerMainController> {
  const OwnerMainView({super.key});

  @override
  Widget build(BuildContext context) {
    const pages = [
      OwnerDashboardView(),
      OwnerFloorsView(),
      OwnerRoomsView(),
      OwnerTenantsView(),
      OwnerInvoicesView(),
      OwnerProfileView(),
    ];

    return Obx(
      () => Scaffold(
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
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_outlined),
                activeIcon: Icon(Icons.grid_view_rounded),
                label: "គ្រប់គ្រង",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.layers_outlined),
                activeIcon: Icon(Icons.layers_rounded),
                label: "ជាន់",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.meeting_room_outlined),
                activeIcon: Icon(Icons.meeting_room_rounded),
                label: "បន្ទប់",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline_rounded),
                activeIcon: Icon(Icons.people_rounded),
                label: "អ្នកជួល",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long_rounded),
                label: "វិក្កយបត្រ",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: "គណនី",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
