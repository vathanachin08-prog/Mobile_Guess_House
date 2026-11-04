import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/app_colors.dart';
import '../employee/employee_list_view.dart';
import '../product/product_list_view.dart';
import 'portal_controller.dart';
import 'portal_profile_view.dart';

class PortalView extends GetView<PortalController> {
  const PortalView({super.key});

  @override
  Widget build(BuildContext context) {
    final pages = const [
      ProductListView(),
      EmployeeListView(),
      PortalProfileView(),
    ];

    return Obx(() {
      final currentIndex = controller.currentIndex.value;

      return Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: pages,
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: controller.changeTab,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: Colors.grey.shade500,
            selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2_outlined),
                activeIcon: Icon(Icons.inventory_2_rounded),
                label: 'Products',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.badge_outlined),
                activeIcon: Icon(Icons.badge_rounded),
                label: 'Employees',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_circle_outlined),
                activeIcon: Icon(Icons.account_circle_rounded),
                label: 'Account',
              ),
            ],
          ),
        ),
      );
    });
  }
}

