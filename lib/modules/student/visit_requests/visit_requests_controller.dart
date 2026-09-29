import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/constant_uri.dart';
import '../../../core/services/api_service.dart';
import '../../../models/rental/visit_request_model.dart';

class VisitRequestsController extends GetxController {
  final ApiService apiService;
  VisitRequestsController({required this.apiService});

  final requests = <VisitRequestModel>[].obs;
  final isLoading = false.obs;
  final selectedFilter = "ALL".obs;

  @override
  void onInit() {
    super.onInit();
    loadRequests();
  }

  List<VisitRequestModel> get filteredRequests {
    if (selectedFilter.value == "ALL") return requests;
    return requests.where((r) => (r.status ?? '').toUpperCase() == selectedFilter.value).toList();
  }

  Future<void> loadRequests() async {
    isLoading.value = true;
    try {
      final res = await apiService.getApi(ConstantUri.myVisitRequests);
      if (res != null) {
        final decoded = jsonDecode(res);
        final data = decoded['data'];
        List items = [];
        if (data != null) {
          if (data is Map && data['content'] is List) {
            items = data['content'];
          } else if (data is List) {
            items = data;
          }
        }
        requests.assignAll(items.map((e) => VisitRequestModel.fromJson(e)).toList());
      }
    } catch (_) {
      // Keep real data empty if none exists
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cancelRequest(int? id) async {
    if (id == null) return;
    try {
      final res = await apiService.putApi(ConstantUri.cancelVisitRequest(id));
      if (res != null) {
        Get.snackbar("Cancelled", "Visit request has been cancelled", backgroundColor: Colors.white);
        loadRequests();
      }
    } catch (e) {
      Get.snackbar("Error", "Could not cancel request: $e");
    }
  }
}
