import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/constant_uri.dart';
import '../../core/services/api_service.dart';
import '../../data/local/token_store_local.dart';
import '../../routes/app_route_name.dart';
import '../../widgets/app_colors.dart';
import 'dashboard/owner_dashboard_controller.dart';
import 'floors/owner_floors_controller.dart';
import 'rooms/owner_rooms_controller.dart';
import 'tenants/owner_tenants_controller.dart';
import 'invoices/owner_invoices_controller.dart';
import 'profile/owner_profile_controller.dart';
import 'visit_requests/owner_visit_requests_controller.dart';
import '../student/home/student_home_controller.dart';

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
          List items = [];
          if (data != null) {
            if (data is Map && data['content'] is List) {
              items = data['content'];
            } else if (data is List) {
              items = data;
            }
          }
          if (items.isNotEmpty) {
            final mapped = items.map((item) {
              final m = Map<String, dynamic>.from(item);
              final name = m['name']?.toString() ?? 'My Property';
              final short = name.length > 14 ? "${name.substring(0, 12)}..." : name;
              final roomCount = m['totalRoomCount'] ?? ((m['rooms'] as List?)?.length ?? 0);
              return {
                "id": m['id'],
                "name": name,
                "shortName": short,
                "address": m['address']?.toString() ?? '',
                "mainImage": m['mainImage']?.toString(),
                "rooms": roomCount,
              };
            }).toList();
            propertiesList.assignAll(mapped);
            if (propertiesList.isNotEmpty) {
              final existing = propertiesList.firstWhereOrNull((p) => p['id'] == selectedPropertyId.value);
              selectProperty(existing ?? propertiesList.first);
            }
            loadDynamicNotifications();
            return;
          }
        }
      } catch (e) {
        debugPrint("Error loading my properties in OwnerMainController: $e");
      }
    }

    // Fresh account with zero properties created on server
    propertiesList.clear();
    selectedPropertyId.value = null;
    selectedPropertyName.value = "មិនទាន់មានអគារ (No Property)";
    selectedPropertyShortName.value = "No Property";
    loadDynamicNotifications();
  }

  Future<void> loadDynamicNotifications() async {
    final api = apiService ?? (Get.isRegistered<ApiService>() ? Get.find<ApiService>() : null);
    if (api == null) return;

    final user = TokenStoreLocal.getUser();
    final name = (user != null && user['firstName'] != null)
        ? "${user['firstName']} ${user['lastName'] ?? ''}".trim()
        : "ម្ចាស់ផ្ទះ";

    final List<Map<String, dynamic>> items = [
      {
        "id": "welcome_1",
        "title": "សូមស្វាគមន៍មកកាន់ RoomFinder KH",
        "titleEn": "Welcome to RoomFinder KH",
        "message": "សួស្តី $name! គណនីរបស់អ្នកត្រូវបានបង្កើតជោគជ័យ។ ចាប់ផ្តើមគ្រប់គ្រងបន្ទប់ជួល និងអ្នកជួលរបស់អ្នកឥឡូវនេះ។",
        "time": "ទើបតែឥឡូវ",
        "icon": Icons.celebration_rounded,
        "color": AppColors.primary,
        "isUnread": false,
      },
    ];

    try {
      // 1. Fetch pending visit requests across all properties
      final propertyIds = propertiesList.map((p) => p['id']).whereType<int>().toList();
      for (final propId in propertyIds) {
        try {
          final res = await api.getApi(ConstantUri.ownerVisitRequests(propId));
          if (res != null) {
            final decoded = res is Map ? res : jsonDecode(res.toString());
            final data = decoded['data'];
            List reqList = [];
            if (data != null) {
              if (data is Map && data['content'] is List) {
                reqList = data['content'];
              } else if (data is List) {
                reqList = data;
              }
            }
            for (final r in reqList) {
              final status = (r['status'] ?? '').toString().toUpperCase();
              if (status == 'PENDING') {
                final student = r['studentName'] ?? 'សិស្ស';
                final propName = r['propertyName'] ?? 'អគារ';
                final date = r['requestedDate'] ?? '';
                final time = r['requestedTime'] ?? '';
                items.insert(0, {
                  "id": "visit_${r['id']}",
                  "title": "សំណើសុំណាត់ជួបថ្មី ($propName)",
                  "message": "សិស្ស $student បានស្នើសុំណាត់ជួបមើលបន្ទប់នៅថ្ងៃ $date ម៉ោង $time",
                  "time": "កំពុងរង់ចាំ",
                  "icon": Icons.calendar_month_rounded,
                  "color": AppColors.accentOrange,
                  "isUnread": true,
                  "route": AppRouteName.ownerVisitRequests,
                });
              }
            }
          }
        } catch (_) {}
      }

      // 2. Fetch unpaid invoices count
      try {
        if (Get.isRegistered<OwnerInvoicesController>()) {
          final invCtrl = Get.find<OwnerInvoicesController>();
          final unpaid = invCtrl.invoices.where((inv) => (inv.status ?? '').toUpperCase() != 'PAID').length;
          if (unpaid > 0) {
            items.insert(0, {
              "id": "unpaid_invoices",
              "title": "វិក្កយបត្រមិនទាន់បង់ ($unpaid)",
              "message": "មានវិក្កយបត្រចំនួន $unpaid ដែលមិនទាន់បានបង់ប្រាក់ សូមពិនិត្យផ្ទៀងផ្ទាត់",
              "time": "ប្រចាំខែ",
              "icon": Icons.receipt_long_rounded,
              "color": AppColors.warning,
              "isUnread": true,
              "tabIndex": 3,
            });
          }
        }
      } catch (_) {}
    } catch (_) {}

    notificationsList.assignAll(items);
    unreadNotificationsCount.value = items.where((n) => n['isUnread'] == true).length;
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
      } else {
        dashCtrl.loadDashboard();
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

    // Sync with OwnerVisitRequestsController
    if (Get.isRegistered<OwnerVisitRequestsController>()) {
      final vrCtrl = Get.find<OwnerVisitRequestsController>();
      vrCtrl.selectedPropertyFilter.value = selectedPropertyId.value;
      vrCtrl.loadRequests();
    }
  }

  Future<int> ensureActivePropertyId() async {
    if (selectedPropertyId.value != null && selectedPropertyId.value! > 0) {
      return selectedPropertyId.value!;
    }
    await addNewProperty("អគាររបស់ខ្ញុំ", "រាជធានីភ្នំពេញ");
    return selectedPropertyId.value ?? (DateTime.now().millisecondsSinceEpoch % 100000);
  }

  Future<void> addNewProperty(String name, String address, {String? mainImage}) async {
    final api = apiService ?? (Get.isRegistered<ApiService>() ? Get.find<ApiService>() : null);
    int newId = DateTime.now().millisecondsSinceEpoch % 100000;
    bool serverSuccess = false;
    if (api != null) {
      try {
        final body = <String, dynamic>{
          "name": name,
          "address": address,
          "propertyType": "APARTMENT",
          "description": name,
        };
        if (mainImage != null && mainImage.isNotEmpty) {
          body["mainImage"] = mainImage;
        }
        final res = await api.postApi(
          ConstantUri.properties,
          body: body,
        );
        if (res != null) {
          final decoded = res is Map ? res : jsonDecode(res.toString());
          final data = decoded['data'];
          if (data != null && data['id'] != null) {
            newId = data['id'];
            serverSuccess = true;
          }
        }
      } catch (e) {
        debugPrint("Error creating property: $e");
      }
    }

    if (serverSuccess) {
      await loadProperties();
      final match = propertiesList.firstWhereOrNull((p) => p['id'] == newId);
      if (match != null) {
        selectProperty(match);
      }
    } else {
      final short = name.length > 12 ? "${name.substring(0, 10)}..." : name;
      final newProp = {
        "id": newId,
        "name": name,
        "shortName": short,
        "address": address,
        "mainImage": mainImage,
        "rooms": 0,
      };
      propertiesList.add(newProp);
      selectProperty(newProp);
    }

    if (Get.isRegistered<OwnerDashboardController>()) {
      Get.find<OwnerDashboardController>().loadDashboard();
    }
    if (Get.isRegistered<StudentHomeController>()) {
      Get.find<StudentHomeController>().loadProperties();
    }
  }

  void markAllNotificationsAsRead() {
    unreadNotificationsCount.value = 0;
    for (var n in notificationsList) {
      n['isUnread'] = false;
    }
    notificationsList.refresh();
  }

  void markNotificationAsRead(String id) {
    final idx = notificationsList.indexWhere((n) => n['id'] == id);
    if (idx != -1) {
      notificationsList[idx]['isUnread'] = false;
      notificationsList.refresh();
      unreadNotificationsCount.value = notificationsList.where((n) => n['isUnread'] == true).length;
    }
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
    Get.lazyPut(() => OwnerVisitRequestsController(apiService: api));
  }
}
