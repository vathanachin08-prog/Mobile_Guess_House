import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/constant_uri.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../models/rental/property_model.dart';
import '../home/student_home_controller.dart';

class StudentSearchController extends GetxController {
  final ApiService apiService;
  StudentSearchController({required this.apiService});

  final searchController = TextEditingController();
  final searchResults = <PropertyModel>[].obs;
  final isLoading = false.obs;

  // Filters
  final selectedRoomType = "ALL".obs; // ALL, SINGLE, DOUBLE, SHARED
  final minPrice = 0.0.obs;
  final maxPrice = 300.0.obs;
  final onlyAvailable = false.obs;
  final selectedFacilities = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    search();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void resetFilters() {
    selectedRoomType.value = "ALL";
    minPrice.value = 0.0;
    maxPrice.value = 300.0;
    onlyAvailable.value = false;
    selectedFacilities.clear();
    search();
  }

  void toggleFacility(String name) {
    if (selectedFacilities.contains(name)) {
      selectedFacilities.remove(name);
    } else {
      selectedFacilities.add(name);
    }
  }

  Future<void> search() async {
    isLoading.value = true;
    final keyword = searchController.text.trim();

    try {
      final List<String> params = [];
      if (keyword.isNotEmpty) params.add("keyword=${Uri.encodeComponent(keyword)}");
      if (selectedRoomType.value != "ALL") params.add("roomType=${selectedRoomType.value}");
      if (minPrice.value > 0) params.add("minPrice=${minPrice.value.toInt()}");
      if (maxPrice.value < 300) params.add("maxPrice=${maxPrice.value.toInt()}");
      if (onlyAvailable.value) params.add("available=true");

      final queryStr = params.join("&");
      final res = await apiService.getApi(ConstantUri.publicProperties, param: queryStr.isNotEmpty ? queryStr : null);

      if (res != null) {
        final decoded = jsonDecode(res);
        if (decoded['data'] != null && decoded['data']['content'] != null) {
          final List content = decoded['data']['content'];
          final list = content.map((e) => PropertyModel.fromJson(e)).toList();
          searchResults.assignAll(list);
        }
      }

      // If empty and no filters applied or fresh DB, sync from home controller
      if (searchResults.isEmpty && keyword.isEmpty && selectedRoomType.value == "ALL") {
        if (Get.isRegistered<StudentHomeController>()) {
          final home = Get.find<StudentHomeController>();
          searchResults.assignAll(home.properties);
        }
      }

      if (keyword.isNotEmpty) {
        AppFirebaseService.logSearchForm(
          keyword: keyword,
          resultCount: searchResults.length,
        );
      }
    } catch (_) {
      if (searchResults.isEmpty && Get.isRegistered<StudentHomeController>()) {
        final home = Get.find<StudentHomeController>();
        searchResults.assignAll(home.properties);
      }
    } finally {
      isLoading.value = false;
    }
  }
}
