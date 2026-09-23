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
        if (decoded['data'] != null && decoded['data'] is List) {
          final List list = decoded['data'];
          requests.assignAll(list.map((e) => VisitRequestModel.fromJson(e)).toList());
        }
      }
      if (requests.isEmpty) {
        requests.assignAll(_getDemoRequests());
      }
    } catch (_) {
      if (requests.isEmpty) {
        requests.assignAll(_getDemoRequests());
      }
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

  List<VisitRequestModel> _getDemoRequests() {
    return [
      VisitRequestModel(
        id: 1,
        propertyName: "Sunrise Student Dormitory",
        roomNumber: "A101",
        requestedDate: "2026-09-25",
        requestedTime: "14:30:00",
        message: "Looking for room starting next semester",
        status: "PENDING",
      ),
      VisitRequestModel(
        id: 2,
        propertyName: "Campus View Apartment",
        roomNumber: "C301",
        requestedDate: "2026-09-20",
        requestedTime: "10:00:00",
        message: "Need to check WiFi stability",
        status: "ACCEPTED",
      ),
    ];
  }
}
