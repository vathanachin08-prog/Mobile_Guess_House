import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/language_service.dart';
import '../../widgets/app_colors.dart';
import 'favorites/favorites_view.dart';
import 'home/student_home_view.dart';
import 'profile/student_profile_view.dart';
import 'search/student_search_view.dart';
import 'student_main_controller.dart';
import 'visit_requests/visit_requests_view.dart';

class StudentMainView extends GetView<StudentMainController> {
  const StudentMainView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      LanguageService.currentLocale.value;

      final pages = [
        const StudentHomeView(),
        const StudentSearchView(),
        const FavoritesView(),
        const VisitRequestsView(),
        const StudentProfileView(),
      ];

      return Scaffold(
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
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home_rounded),
              label: 'home'.tr,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.search_rounded),
              activeIcon: const Icon(Icons.saved_search_rounded),
              label: 'search'.tr,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.favorite_border_rounded),
              activeIcon: const Icon(Icons.favorite_rounded),
              label: 'favorites'.tr,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.calendar_month_outlined),
              activeIcon: const Icon(Icons.calendar_month_rounded),
              label: 'visit_requests'.tr,
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
