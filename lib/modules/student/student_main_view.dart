import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
    const pages = [
      StudentHomeView(),
      StudentSearchView(),
      FavoritesView(),
      VisitRequestsView(),
      StudentProfileView(),
    ];

    return Obx(() => Scaffold(
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: "ទំព័រដើម",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              activeIcon: Icon(Icons.saved_search_rounded),
              label: "ស្វែងរក",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border_rounded),
              activeIcon: Icon(Icons.favorite_rounded),
              label: "ពេញចិត្ត",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month_rounded),
              label: "ការណាត់ជួប",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: "គណនី",
            ),
          ],
        ),
      ),
    ));
  }
}
