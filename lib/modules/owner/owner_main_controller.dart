import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/api_service.dart';
import '../../widgets/app_colors.dart';
import 'dashboard/owner_dashboard_controller.dart';
import 'floors/owner_floors_controller.dart';
import 'rooms/owner_rooms_controller.dart';
import 'tenants/owner_tenants_controller.dart';
import 'invoices/owner_invoices_controller.dart';
import 'profile/owner_profile_controller.dart';

class OwnerMainController extends GetxController {
  final currentIndex = 0.obs;

  // Selected Property State
  final selectedPropertyName = "My Home (Phnom Penh)".obs;
  final selectedPropertyShortName = "My Home".obs;
  final selectedPropertyId = 1.obs;

  final propertiesList = <Map<String, dynamic>>[
    {
      "id": 1,
      "name": "My Home (Phnom Penh)",
      "shortName": "My Home",
      "address": "Toul Kork, Phnom Penh",
      "rooms": 5,
    },
    {
      "id": 2,
      "name": "Sunrise Student Dormitory",
      "shortName": "Sunrise Dorm",
      "address": "Sensok, Phnom Penh",
      "rooms": 12,
    },
    {
      "id": 3,
      "name": "Green Villa Apartments",
      "shortName": "Green Villa",
      "address": "BKK1, Phnom Penh",
      "rooms": 8,
    },
  ].obs;

  // Notification State
  final unreadNotificationsCount = 2.obs;
  final notificationsList = <Map<String, dynamic>>[
    {
      "id": "1",
      "title": "ការទូទាត់វិក្កយបត្រថ្មី",
      "titleEn": "New Invoice Payment",
      "message": "អ្នកជួល Chanrith (បន្ទប់ 101) បានទូទាត់ថ្លៃបន្ទប់ \$120.00 រួចរាល់",
      "time": "10 នាទីមុន",
      "icon": Icons.payment_rounded,
      "color": AppColors.primary,
      "isUnread": true,
    },
    {
      "id": "2",
      "title": "សំណើសុំមើលបន្ទប់ថ្មី",
      "titleEn": "New Visit Request",
      "message": "Sokha បានកក់ការណាត់ជួបមើលបន្ទប់ 203 សម្រាប់ថ្ងៃស្អែក ម៉ោង 10:00 ព្រឹក",
      "time": "1 ម៉ោងមុន",
      "icon": Icons.calendar_month_rounded,
      "color": AppColors.accentBlue,
      "isUnread": true,
    },
    {
      "id": "3",
      "title": "រំលឹកកាលបរិច្ឆេទវិក្កយបត្រ",
      "titleEn": "Invoice Due Reminder",
      "message": "មានបន្ទប់ចំនួន 2 ដល់ថ្ងៃបង់ប្រាក់ថ្លៃបន្ទប់ប្រចាំខែ",
      "time": "1 ថ្ងៃមុន",
      "icon": Icons.notification_important_rounded,
      "color": AppColors.accentOrange,
      "isUnread": false,
    },
    {
      "id": "4",
      "title": "កញ្ចប់សមាជិកភាព",
      "titleEn": "Membership Plan",
      "message": "គណនីរបស់អ្នកកំពុងប្រើប្រាស់កញ្ចប់ Basic (ឥតគិតថ្លៃ)",
      "time": "3 ថ្ងៃមុន",
      "icon": Icons.star_rounded,
      "color": AppColors.darkEmerald,
      "isUnread": false,
    },
  ].obs;

  void changeTab(int index) {
    currentIndex.value = index;
    if (index == 5 && Get.isRegistered<OwnerProfileController>()) {
      final ctrl = Get.find<OwnerProfileController>();
      ctrl.loadUser();
      ctrl.fetchProfileFromServer();
    }
  }

  void selectProperty(Map<String, dynamic> prop) {
    selectedPropertyId.value = prop['id'] as int;
    selectedPropertyName.value = prop['name'] as String;
    selectedPropertyShortName.value = (prop['shortName'] ?? prop['name']) as String;

    // Also notify OwnerDashboardController if registered
    if (Get.isRegistered<OwnerDashboardController>()) {
      final dashCtrl = Get.find<OwnerDashboardController>();
      final match = dashCtrl.myProperties.firstWhereOrNull((p) => p.id == selectedPropertyId.value);
      if (match != null) {
        dashCtrl.switchProperty(match);
      }
    }
  }

  void addNewProperty(String name, String address) {
    final newId = propertiesList.length + 1;
    final short = name.length > 12 ? "${name.substring(0, 10)}..." : name;
    final newProp = {
      "id": newId,
      "name": name,
      "shortName": short,
      "address": address,
      "rooms": 0,
    };
    propertiesList.add(newProp);
    selectProperty(newProp);
  }

  void markAllNotificationsAsRead() {
    unreadNotificationsCount.value = 0;
    for (var n in notificationsList) {
      n['isUnread'] = false;
    }
    notificationsList.refresh();
  }

  void clearNotifications() {
    notificationsList.clear();
    unreadNotificationsCount.value = 0;
  }
}

class OwnerMainBinding extends Bindings {
  @override
  void dependencies() {
    final api = Get.find<ApiService>();
    Get.lazyPut(() => OwnerMainController());
    Get.lazyPut(() => OwnerDashboardController(apiService: api));
    Get.lazyPut(() => OwnerFloorsController(apiService: api));
    Get.lazyPut(() => OwnerRoomsController(apiService: api));
    Get.lazyPut(() => OwnerTenantsController(apiService: api));
    Get.lazyPut(() => OwnerInvoicesController(apiService: api));
    Get.lazyPut(() => OwnerProfileController());
  }
}
