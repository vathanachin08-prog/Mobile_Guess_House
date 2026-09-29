import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/constant_uri.dart';
import '../../core/services/api_service.dart';
import '../../data/local/token_store_local.dart';
import '../../widgets/app_colors.dart';
import 'dashboard/owner_dashboard_controller.dart';
import 'floors/owner_floors_controller.dart';
import 'rooms/owner_rooms_controller.dart';
import 'tenants/owner_tenants_controller.dart';
import 'invoices/owner_invoices_controller.dart';
import 'profile/owner_profile_controller.dart';

class OwnerMainController extends GetxController {
  final ApiService? apiService;
  OwnerMainController({this.apiService});

  final currentIndex = 0.obs;

  // Selected Property State
  final selectedPropertyName = "មិនទាន់មានអគារ (No Property)".obs;
  final selectedPropertyShortName = "No Property".obs;
  final selectedPropertyId = RxnInt();

  final propertiesList = <Map<String, dynamic>>[].obs;

  // Notification State
  final unreadNotificationsCount = 1.obs;
  final notificationsList = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initNotifications();
    loadProperties();
  }

  void _initNotifications() {
    final user = TokenStoreLocal.getUser();
    final name = (user != null && user['firstName'] != null)
        ? "${user['firstName']} ${user['lastName'] ?? ''}".trim()
        : "ម្ចាស់ផ្ទះ";

    notificationsList.assignAll([
      {
        "id": "welcome_1",
        "title": "សូមស្វាគមន៍មកកាន់ RoomFinder KH",
        "titleEn": "Welcome to RoomFinder KH",
        "message": "សួស្តី $name! គណនីរបស់អ្នកត្រូវបានបង្កើតជោគជ័យ។ ចាប់ផ្តើមគ្រប់គ្រងបន្ទប់ជួល និងអ្នកជួលរបស់អ្នកឥឡូវនេះ។",
        "time": "ទើបតែឥឡូវ",
        "icon": Icons.celebration_rounded,
        "color": AppColors.primary,
        "isUnread": true,
      },
    ]);
    unreadNotificationsCount.value = 1;
  }

  Future<void> loadProperties() async {
    final api = apiService ?? (Get.isRegistered<ApiService>() ? Get.find<ApiService>() : null);
    if (api != null) {
      try {
        final res = await api.getApi(ConstantUri.myProperties);
        if (res != null) {
          final decoded = res is Map ? res : jsonDecode(res.toString());
          final data = decoded['data'];
          if (data is List && data.isNotEmpty) {
            final mapped = data.map((item) {
              final m = Map<String, dynamic>.from(item);
              final name = m['name']?.toString() ?? 'My Property';
              final short = name.length > 14 ? "${name.substring(0, 12)}..." : name;
              return {
                "id": m['id'],
                "name": name,
                "shortName": short,
                "address": m['address']?.toString() ?? '',
                "rooms": (m['rooms'] as List?)?.length ?? 0,
              };
            }).toList();
            propertiesList.assignAll(mapped);
            if (propertiesList.isNotEmpty) {
              selectProperty(propertiesList.first);
            }
            return;
          }
        }
      } catch (_) {}
    }

    // Fresh account with zero properties created on server
    propertiesList.clear();
    selectedPropertyId.value = null;
    selectedPropertyName.value = "មិនទាន់មានអគារ (No Property)";
    selectedPropertyShortName.value = "No Property";
  }

  void changeTab(int index) {
    currentIndex.value = index;
    if (index == 5 && Get.isRegistered<OwnerProfileController>()) {
      final ctrl = Get.find<OwnerProfileController>();
      ctrl.loadUser();
      ctrl.fetchProfileFromServer();
    }
  }

  void selectProperty(Map<String, dynamic> prop) {
    selectedPropertyId.value = prop['id'] as int?;
    selectedPropertyName.value = (prop['name'] ?? 'My Property') as String;
    selectedPropertyShortName.value = (prop['shortName'] ?? prop['name'] ?? 'My Property') as String;

    // Notify OwnerDashboardController
    if (Get.isRegistered<OwnerDashboardController>()) {
      final dashCtrl = Get.find<OwnerDashboardController>();
      final match = dashCtrl.myProperties.firstWhereOrNull((p) => p.id == selectedPropertyId.value);
      if (match != null) {
        dashCtrl.switchProperty(match);
      }
    }

    // Sync with OwnerRoomsController
    if (Get.isRegistered<OwnerRoomsController>()) {
      Get.find<OwnerRoomsController>().loadRooms();
    }

    // Sync with OwnerFloorsController
    if (Get.isRegistered<OwnerFloorsController>()) {
      Get.find<OwnerFloorsController>().loadFloors();
    }
  }

  Future<int> ensureActivePropertyId() async {
    if (selectedPropertyId.value != null && selectedPropertyId.value! > 0) {
      return selectedPropertyId.value!;
    }
    await addNewProperty("អគាររបស់ខ្ញុំ", "រាជធានីភ្នំពេញ");
    return selectedPropertyId.value ?? (DateTime.now().millisecondsSinceEpoch % 100000);
  }

  Future<void> addNewProperty(String name, String address) async {
    final api = apiService ?? (Get.isRegistered<ApiService>() ? Get.find<ApiService>() : null);
    int newId = DateTime.now().millisecondsSinceEpoch % 100000;
    if (api != null) {
      try {
        final res = await api.postApi(
          ConstantUri.properties,
          body: {
            "name": name,
            "address": address,
            "propertyType": "APARTMENT",
            "description": name,
          },
        );
        if (res != null) {
          final decoded = res is Map ? res : jsonDecode(res.toString());
          final data = decoded['data'];
          if (data != null && data['id'] != null) {
            newId = data['id'];
          }
        }
      } catch (_) {}
    }

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
    Get.lazyPut(() => OwnerMainController(apiService: api));
    Get.lazyPut(() => OwnerDashboardController(apiService: api));
    Get.lazyPut(() => OwnerFloorsController(apiService: api));
    Get.lazyPut(() => OwnerRoomsController(apiService: api));
    Get.lazyPut(() => OwnerTenantsController(apiService: api));
    Get.lazyPut(() => OwnerInvoicesController(apiService: api));
    Get.lazyPut(() => OwnerProfileController());
  }
}
