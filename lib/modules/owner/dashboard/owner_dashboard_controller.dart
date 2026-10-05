import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/constant_uri.dart';
import '../../../core/services/api_service.dart';
import '../../../data/local/token_store_local.dart';
import '../../../models/rental/property_model.dart';
import '../../../models/rental/visit_request_model.dart';
import '../../../widgets/app_colors.dart';
import '../floors/owner_floors_controller.dart';
import '../rooms/owner_rooms_controller.dart';
import '../tenants/owner_tenants_controller.dart';
import '../invoices/owner_invoices_controller.dart';
import '../visit_requests/owner_visit_requests_controller.dart';
import '../owner_main_controller.dart';

class OwnerDashboardController extends GetxController {
  final ApiService apiService;
  OwnerDashboardController({required this.apiService});

  final myProperties = <PropertyModel>[].obs;
  final currentProperty = Rxn<PropertyModel>();
  final isLoading = false.obs;

  // Stats dynamically computed or synced from actual data
  final totalFloors = 0.obs;
  final totalRooms = 0.obs;
  final availableRooms = 0.obs;
  final occupiedRooms = 0.obs;
  final totalTenants = 0.obs;
  final unpaidInvoices = 0.obs;
  final totalRevenue = 0.0.obs;
  final expectedRevenue = 0.0.obs;
  final pendingVisitRequestsCount = 0.obs;
  final latestVisitRequest = Rxn<VisitRequestModel>();

  final user = Rxn<Map<String, dynamic>>();
  final ownerNameRx = "Owner".obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserInfo();
    loadDashboard();
  }

  void _loadUserInfo() {
    final u = TokenStoreLocal.getUser();
    user.value = u;
    if (u != null) {
      final first = u['firstName'] ?? '';
      final last = u['lastName'] ?? '';
      if (first.toString().isNotEmpty || last.toString().isNotEmpty) {
        ownerNameRx.value = "$first $last".trim();
        return;
      }
      final un = u['username'];
      if (un != null && un.toString().isNotEmpty) {
        ownerNameRx.value = un.toString();
        return;
      }
    }
    ownerNameRx.value = 'Owner';
  }

  String get ownerName => ownerNameRx.value;

  double get occupancyRate {
    if (totalRooms.value == 0) return 0.0;
    return (occupiedRooms.value / totalRooms.value) * 100;
  }

  Future<void> loadDashboard() async {
    isLoading.value = true;
    try {
      final res = await apiService.getApi(ConstantUri.myProperties);
      if (res != null) {
        final decoded = res is Map ? res : jsonDecode(res.toString());
        List items = [];
        final data = decoded['data'];
        if (data != null) {
          if (data is Map && data['content'] is List) {
            items = data['content'];
          } else if (data is List) {
            items = data;
          }
        }
        if (items.isNotEmpty) {
          final props = items.map((e) => PropertyModel.fromJson(Map<String, dynamic>.from(e))).toList();
          myProperties.assignAll(props);
          if (myProperties.isNotEmpty) {
            int? activeId;
            if (Get.isRegistered<OwnerMainController>()) {
              activeId = Get.find<OwnerMainController>().selectedPropertyId.value;
            }
            final match = myProperties.firstWhereOrNull((p) => p.id == activeId);
            final selected = match ?? myProperties.first;
            await switchProperty(selected);
          }
        }
      }
    } catch (_) {
    } finally {
      _syncDynamicStats();
      isLoading.value = false;
    }
  }

  /// Sync stats from registered sub-controllers so dashboard is always 100% dynamic
  void _syncDynamicStats() {
    if (Get.isRegistered<OwnerFloorsController>()) {
      final fCtrl = Get.find<OwnerFloorsController>();
      if (fCtrl.activePropertyId == currentProperty.value?.id) {
        totalFloors.value = fCtrl.floors.length;
      }
    }
    if (Get.isRegistered<OwnerRoomsController>()) {
      final rCtrl = Get.find<OwnerRoomsController>();
      if (rCtrl.activePropertyId == currentProperty.value?.id) {
        totalRooms.value = rCtrl.rooms.length;
        availableRooms.value = rCtrl.rooms.where((r) => r.available == true).length;
        occupiedRooms.value = rCtrl.rooms.where((r) => r.available == false).length;
      }
    }
    if (Get.isRegistered<OwnerTenantsController>()) {
      final tCtrl = Get.find<OwnerTenantsController>();
      totalTenants.value = tCtrl.tenants.length;
    }
    if (Get.isRegistered<OwnerInvoicesController>()) {
      final iCtrl = Get.find<OwnerInvoicesController>();
      unpaidInvoices.value = iCtrl.unpaidCount;
      totalRevenue.value = iCtrl.totalCollectedRevenue;
      expectedRevenue.value = iCtrl.totalExpectedRevenue;
    }
  }

  Future<void> switchProperty(PropertyModel p) async {
    currentProperty.value = p;
    if (p.totalRoomCount != null) {
      totalRooms.value = p.totalRoomCount!;
      availableRooms.value = p.availableRoomCount ?? 0;
      occupiedRooms.value = (p.totalRoomCount! - (p.availableRoomCount ?? 0)).clamp(0, p.totalRoomCount!);
    } else if (p.rooms != null) {
      final rList = p.rooms!;
      totalRooms.value = rList.length;
      availableRooms.value = rList.where((r) => r.available == true).length;
      occupiedRooms.value = rList.where((r) => r.available == false).length;
    } else {
      totalRooms.value = 0;
      availableRooms.value = 0;
      occupiedRooms.value = 0;
    }

    // Immediately reset floor count to 0 so we don't display stale floors from another property
    totalFloors.value = 0;
    if (Get.isRegistered<OwnerFloorsController>()) {
      final fCtrl = Get.find<OwnerFloorsController>();
      if (fCtrl.activePropertyId == p.id) {
        totalFloors.value = fCtrl.floors.length;
      }
    }

    if (p.id != null) {
      await fetchFloorsForProperty(p.id!);
    }

    await fetchVisitRequestsStats();
  }

  Future<void> fetchFloorsForProperty(int propId) async {
    try {
      final res = await apiService.getApi(ConstantUri.propertyFloors(propId));
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
        if (currentProperty.value?.id == propId) {
          totalFloors.value = items.length;
        }
      }
    } catch (_) {}
  }

  Future<void> fetchVisitRequestsStats() async {
    try {
      final activeId = currentProperty.value?.id;
      final Set<int> propertyIds = {};
      for (var p in myProperties) {
        if (p.id != null) propertyIds.add(p.id!);
      }
      if (activeId != null) propertyIds.add(activeId);

      final List<VisitRequestModel> allFetched = [];
      await Future.wait(propertyIds.map((propId) async {
        try {
          final res = await apiService.getApi(ConstantUri.ownerVisitRequests(propId));
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
            allFetched.addAll(items.map((e) => VisitRequestModel.fromJson(Map<String, dynamic>.from(e))));
          }
        } catch (_) {}
      }));

      updateVisitRequestsStats(allFetched);
    } catch (_) {}
  }

  void updateVisitRequestsStats(List<VisitRequestModel> allRequests) {
    final activeId = currentProperty.value?.id;
    final pendingActive = allRequests.where((r) =>
        (r.status ?? '').toUpperCase() == "PENDING" &&
        (activeId == null || r.propertyId == activeId)).toList();

    final allPending = allRequests.where((r) =>
        (r.status ?? '').toUpperCase() == "PENDING").toList();

    pendingVisitRequestsCount.value = allPending.length;
    latestVisitRequest.value = pendingActive.isNotEmpty
        ? pendingActive.first
        : (allPending.isNotEmpty ? allPending.first : null);
  }

  Future<void> quickAcceptVisitRequest(int id) async {
    try {
      final res = await apiService.putApi(ConstantUri.acceptVisitRequest(id));
      if (res != null) {
        Get.snackbar("ជោគជ័យ", "បានយល់ព្រមទទួលការណាត់ជួប!", backgroundColor: Colors.white, colorText: AppColors.success);
        await fetchVisitRequestsStats();
        if (Get.isRegistered<OwnerVisitRequestsController>()) {
          Get.find<OwnerVisitRequestsController>().loadRequests();
        }
        if (Get.isRegistered<OwnerMainController>()) {
          Get.find<OwnerMainController>().loadDynamicNotifications();
        }
      }
    } catch (e) {
      Get.snackbar("Error", "មិនអាចយល់ព្រមបានទេ: $e", backgroundColor: Colors.white);
    }
  }

  Future<void> quickRejectVisitRequest(int id) async {
    try {
      final res = await apiService.putApi(ConstantUri.rejectVisitRequest(id));
      if (res != null) {
        Get.snackbar("បដិសេធ", "បានបដិសេធការណាត់ជួប!", backgroundColor: Colors.white, colorText: AppColors.danger);
        await fetchVisitRequestsStats();
        if (Get.isRegistered<OwnerVisitRequestsController>()) {
          Get.find<OwnerVisitRequestsController>().loadRequests();
        }
        if (Get.isRegistered<OwnerMainController>()) {
          Get.find<OwnerMainController>().loadDynamicNotifications();
        }
      }
    } catch (e) {
      Get.snackbar("Error", "មិនអាចបដិសេធបានទេ: $e", backgroundColor: Colors.white);
    }
  }
}
