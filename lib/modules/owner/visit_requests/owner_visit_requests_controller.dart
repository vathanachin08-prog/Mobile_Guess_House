import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/constant_uri.dart';
import '../../../core/services/api_service.dart';
import '../../../models/rental/visit_request_model.dart';
import '../../../widgets/app_colors.dart';
import '../dashboard/owner_dashboard_controller.dart';
import '../owner_main_controller.dart';

class OwnerVisitRequestsController extends GetxController {
  final ApiService apiService;
  OwnerVisitRequestsController({required this.apiService});

  final requests = <VisitRequestModel>[].obs;
  final isLoading = false.obs;
  final isProcessing = false.obs;
  final selectedFilter = "ALL".obs; // ALL, PENDING, ACCEPTED, REJECTED, COMPLETED
  final selectedPropertyFilter = RxnInt(); // null = all properties

  int? get activePropertyId {
    if (Get.isRegistered<OwnerMainController>()) {
      return Get.find<OwnerMainController>().selectedPropertyId.value;
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    selectedPropertyFilter.value = activePropertyId;
    loadRequests();
  }

  List<VisitRequestModel> get filteredRequests {
    List<VisitRequestModel> list = requests;

    // Filter by property if selected
    if (selectedPropertyFilter.value != null) {
      list = list.where((r) => r.propertyId == selectedPropertyFilter.value).toList();
    }

    // Filter by status
    if (selectedFilter.value != "ALL") {
      list = list.where((r) => (r.status ?? '').toUpperCase() == selectedFilter.value).toList();
    }

    return list;
  }

  int get pendingCount {
    return requests.where((r) => (r.status ?? '').toUpperCase() == "PENDING").length;
  }

  Future<void> loadRequests() async {
    isLoading.value = true;
    try {
      // Collect property IDs owned by current owner
      final Set<int> propertyIds = {};
      if (Get.isRegistered<OwnerMainController>()) {
        final mainCtrl = Get.find<OwnerMainController>();
        for (var p in mainCtrl.propertiesList) {
          final id = p['id'];
          if (id is int) propertyIds.add(id);
        }
      }
      if (Get.isRegistered<OwnerDashboardController>()) {
        final dashCtrl = Get.find<OwnerDashboardController>();
        for (var p in dashCtrl.myProperties) {
          if (p.id != null) propertyIds.add(p.id!);
        }
      }

      // If activePropertyId exists and not yet in set
      final activeId = activePropertyId;
      if (activeId != null) propertyIds.add(activeId);

      // Fetch visit requests across all owner properties in parallel
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

      // Deduplicate by ID and sort descending
      final Map<int, VisitRequestModel> map = {};
      for (var r in allFetched) {
        if (r.id != null) map[r.id!] = r;
      }
      final sorted = map.values.toList();
      sorted.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
      requests.assignAll(sorted);

      _syncToDashboard();
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> acceptRequest(int id) async {
    isProcessing.value = true;
    try {
      final res = await apiService.putApi(ConstantUri.acceptVisitRequest(id));
      if (res != null) {
        Get.snackbar(
          "ជោគជ័យ",
          "បានយល់ព្រមទទួលការណាត់ជួបជោគជ័យ!",
          backgroundColor: Colors.white,
          colorText: AppColors.success,
          icon: const Icon(Icons.check_circle_rounded, color: AppColors.success),
        );
        await loadRequests();
      }
    } catch (e) {
      Get.snackbar("Error", "មិនអាចយល់ព្រមបានទេ: $e", backgroundColor: Colors.white);
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> rejectRequest(int id) async {
    isProcessing.value = true;
    try {
      final res = await apiService.putApi(ConstantUri.rejectVisitRequest(id));
      if (res != null) {
        Get.snackbar(
          "បដិសេធ",
          "បានបដិសេធការណាត់ជួប!",
          backgroundColor: Colors.white,
          colorText: AppColors.danger,
          icon: const Icon(Icons.cancel_rounded, color: AppColors.danger),
        );
        await loadRequests();
      }
    } catch (e) {
      Get.snackbar("Error", "មិនអាចបដិសេធបានទេ: $e", backgroundColor: Colors.white);
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> completeRequest(int id) async {
    isProcessing.value = true;
    try {
      final res = await apiService.putApi(ConstantUri.completeVisitRequest(id));
      if (res != null) {
        Get.snackbar(
          "រួចរាល់",
          "ការណាត់ជួបត្រូវបានបញ្ចប់ជោគជ័យ!",
          backgroundColor: Colors.white,
          colorText: AppColors.primary,
          icon: const Icon(Icons.done_all_rounded, color: AppColors.primary),
        );
        await loadRequests();
      }
    } catch (e) {
      Get.snackbar("Error", "មិនអាចបញ្ចប់ការណាត់ជួបបានទេ: $e", backgroundColor: Colors.white);
    } finally {
      isProcessing.value = false;
    }
  }

  void _syncToDashboard() {
    if (Get.isRegistered<OwnerDashboardController>()) {
      final dash = Get.find<OwnerDashboardController>();
      dash.updateVisitRequestsStats(requests);
    }
    if (Get.isRegistered<OwnerMainController>()) {
      Get.find<OwnerMainController>().loadDynamicNotifications();
    }
  }
}
